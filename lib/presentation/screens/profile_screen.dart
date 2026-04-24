import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../providers/user_provider.dart';
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}
class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _loading = false;
  bool _showChangePassword = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _whatsappSameAsPhone = false;
  bool _initialized = false;
  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _whatsappCtrl.dispose();
    _addressCtrl.dispose();
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }
  void _initFields(String name, String email, String phone, String whatsapp, String address) {
    if (!_initialized) {
      _nameCtrl.text = name;
      _emailCtrl.text = email;
      _phoneCtrl.text = phone;
      _whatsappCtrl.text = whatsapp;
      _addressCtrl.text = address;
      // Se telefone e whatsapp são iguais e não vazios, marca o checkbox
      if (phone.isNotEmpty && phone == whatsapp) {
        _whatsappSameAsPhone = true;
      }
      _initialized = true;
    }
  }
  /// Remove tudo que não for dígito
  String _onlyDigits(String v) => v.replaceAll(RegExp(r'\D'), '');
  void _onPhoneChanged(String value) {
    if (_whatsappSameAsPhone) {
      _whatsappCtrl.text = value;
    }
  }
  void _onWhatsappSameToggled(bool? checked) {
    setState(() {
      _whatsappSameAsPhone = checked ?? false;
      if (_whatsappSameAsPhone) {
        _whatsappCtrl.text = _phoneCtrl.text;
      }
    });
  }
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
        length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String _sha256ofString(String input) =>
      sha256.convert(utf8.encode(input)).toString();

  Future<AuthCredential?> _buildCredentialForReauth(User user) async {
    final providers =
        user.providerData.map((p) => p.providerId).toList();

    if (providers.contains('apple.com')) {
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);
      final apple = await SignInWithApple.getAppleIDCredential(
        scopes: [],
        nonce: nonce,
      );
      return OAuthProvider('apple.com').credential(
        idToken: apple.identityToken,
        rawNonce: rawNonce,
      );
    }

    if (providers.contains('google.com')) {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;
      final googleAuth = await googleUser.authentication;
      return GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
    }

    // E-mail / senha
    final passCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirme sua senha'),
        content: TextField(
          controller: passCtrl,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Senha atual',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed != true || passCtrl.text.isEmpty) return null;
    return EmailAuthProvider.credential(
      email: user.email!,
      password: passCtrl.text,
    );
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir conta'),
        content: const Text(
          'Sua conta e todos os seus dados pessoais serão removidos permanentemente.\n\n'
          'Agendamentos já realizados permanecem no histórico do estabelecimento.\n\n'
          'Deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir conta'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final credential = await _buildCredentialForReauth(user);
      if (credential == null) return; // usuário cancelou

      await user.reauthenticateWithCredential(credential);

      final db = FirebaseFirestore.instance;
      final userDoc = await db.collection('users').doc(user.uid).get();

      // Remove identifier
      if (userDoc.exists) {
        final identifier =
            (userDoc.data()?['identifier'] as String? ?? '').trim();
        if (identifier.isNotEmpty) {
          await db.collection('identifiers').doc(identifier).delete();
        }
      }

      // Remove documento do usuário
      await db.collection('users').doc(user.uid).delete();

      // Remove conta Firebase Auth
      await user.delete();

      // Firebase Auth signOut automático após delete; não há mais usuário
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final msg = switch (e.code) {
        'wrong-password' || 'invalid-credential' => 'Senha incorreta.',
        'requires-recent-login' =>
          'Saia e entre novamente antes de excluir a conta.',
        _ => e.message ?? 'Erro ao excluir conta.',
      };
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro Apple: ${e.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _loading = true);
    try {
      final newName = _nameCtrl.text.trim();
      final newEmail = _emailCtrl.text.trim();
      final newPhone = _onlyDigits(_phoneCtrl.text);
      final newWhatsapp = _whatsappSameAsPhone
          ? newPhone
          : _onlyDigits(_whatsappCtrl.text);
      final newAddress = _addressCtrl.text.trim();
      // Atualiza email no Auth se mudou
      if (newEmail != user.email) {
        await user.verifyBeforeUpdateEmail(newEmail);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Um link de verificacao foi enviado para o novo e-mail. '
                'O e-mail so sera atualizado apos confirmacao.',
              ),
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
      // Atualiza dados no Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'name': newName,
        'phone': newPhone,
        'whatsapp': newWhatsapp,
        'address': newAddress,
      });
      // Atualiza senha se solicitado
      if (_showChangePassword && _newPassCtrl.text.isNotEmpty) {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: _currentPassCtrl.text,
        );
        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(_newPassCtrl.text);
        _currentPassCtrl.clear();
        _newPassCtrl.clear();
        _confirmPassCtrl.clear();
        setState(() => _showChangePassword = false);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil atualizado com sucesso.')),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final msg = switch (e.code) {
        'wrong-password' => 'Senha atual incorreta.',
        'requires-recent-login' =>
          'Sessao expirada. Saia e entre novamente para alterar dados sensiveis.',
        'email-already-in-use' => 'Este e-mail ja esta em uso.',
        _ => e.message ?? 'Erro ao atualizar perfil.',
      };
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userRoleProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Meu Perfil')),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (user) {
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }
          _initFields(user.name, user.email, user.phone, user.whatsapp, user.address);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  // Info somente leitura
                  _InfoRow(
                    label: 'Identificador',
                    value: '${user.identifier} (${user.identifierType})',
                  ),
                  const SizedBox(height: 24),
                  // Nome
                  TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nome completo',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Informe seu nome'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  // E-mail
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email_outlined),
                      helperText:
                          'Alterar envia um link de verificacao para o novo e-mail.',
                    ),
                    validator: (v) =>
                        (v == null || !v.contains('@')) ? 'E-mail invalido' : null,
                  ),
                  const SizedBox(height: 16),
                  // Telefone
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 11,
                    onChanged: _onPhoneChanged,
                    decoration: const InputDecoration(
                      labelText: 'Telefone',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone_outlined),
                      hintText: '11999998888',
                      counterText: '',
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return null; // opcional
                      final digits = _onlyDigits(v);
                      if (digits.length < 10 || digits.length > 11) {
                        return 'Informe um telefone valido (10 ou 11 digitos)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 4),
                  // Checkbox WhatsApp igual ao telefone
                  Row(
                    children: [
                      Checkbox(
                        value: _whatsappSameAsPhone,
                        onChanged: _onWhatsappSameToggled,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      const Text('WhatsApp igual ao telefone'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // WhatsApp
                  TextFormField(
                    controller: _whatsappCtrl,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 11,
                    enabled: !_whatsappSameAsPhone,
                    decoration: InputDecoration(
                      labelText: 'WhatsApp',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.chat_outlined),
                      hintText: '11999998888',
                      counterText: '',
                      filled: _whatsappSameAsPhone,
                      fillColor: _whatsappSameAsPhone
                          ? Theme.of(context).disabledColor.withValues(alpha: 0.08)
                          : null,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return null; // opcional
                      final digits = _onlyDigits(v);
                      if (digits.length < 10 || digits.length > 11) {
                        return 'Informe um WhatsApp valido (10 ou 11 digitos)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Endereço
                  TextFormField(
                    controller: _addressCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Endereco',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on_outlined),
                      hintText: 'Rua, numero, bairro, cidade',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  // Seção de alteração de senha
                  OutlinedButton.icon(
                    onPressed: () => setState(
                        () => _showChangePassword = !_showChangePassword),
                    icon: Icon(_showChangePassword
                        ? Icons.expand_less
                        : Icons.lock_outline),
                    label: Text(_showChangePassword
                        ? 'Cancelar alteracao de senha'
                        : 'Alterar senha'),
                  ),
                  if (_showChangePassword) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _currentPassCtrl,
                      obscureText: _obscureCurrent,
                      decoration: InputDecoration(
                        labelText: 'Senha atual',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureCurrent
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () => setState(
                              () => _obscureCurrent = !_obscureCurrent),
                        ),
                      ),
                      validator: (v) {
                        if (!_showChangePassword) return null;
                        if (v == null || v.isEmpty) return 'Informe a senha atual';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _newPassCtrl,
                      obscureText: _obscureNew,
                      decoration: InputDecoration(
                        labelText: 'Nova senha',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureNew
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () =>
                              setState(() => _obscureNew = !_obscureNew),
                        ),
                      ),
                      validator: (v) {
                        if (!_showChangePassword) return null;
                        if (v == null || v.length < 6) {
                          return 'Minimo 6 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirmPassCtrl,
                      obscureText: _obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Confirmar nova senha',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirm
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                      validator: (v) {
                        if (!_showChangePassword) return null;
                        if (v != _newPassCtrl.text) {
                          return 'As senhas nao coincidem';
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: _loading ? null : _save,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Salvar alteracoes'),
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Divider(),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _loading ? null : _deleteAccount,
                      icon: const Icon(Icons.delete_forever_outlined,
                          color: Colors.red),
                      label: const Text(
                        'Excluir minha conta',
                        style: TextStyle(color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        Text(value),
      ],
    );
  }
}
