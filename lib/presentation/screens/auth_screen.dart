import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';
import 'services_catalog_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailLoginCtrl = TextEditingController();
  final _emailRegisterCtrl = TextEditingController();
  final _identifierCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;
  bool _passVisible = false;
  // 'email' | 'cpf' | 'phone'
  String _identifierType = 'cpf';
  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailLoginCtrl.dispose();
    _emailRegisterCtrl.dispose();
    _identifierCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  String _identifierLabel() {
    switch (_identifierType) {
      case 'cpf':
        return 'CPF';
      case 'phone':
        return 'Telefone';
      default:
        return 'E-mail';
    }
  }

  IconData _identifierIcon() {
    switch (_identifierType) {
      case 'cpf':
        return Icons.badge_outlined;
      case 'phone':
        return Icons.phone_outlined;
      default:
        return Icons.email_outlined;
    }
  }

  TextInputType _identifierKeyboard() {
    switch (_identifierType) {
      case 'cpf':
      case 'phone':
        return TextInputType.number;
      default:
        return TextInputType.emailAddress;
    }
  }

  String? _validateIdentifier(String? v) {
    if (v == null || v.trim().isEmpty) {
      return 'Informe seu ${_identifierLabel()}';
    }
    if (_identifierType == 'cpf') {
      final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length != 11) return 'CPF deve ter 11 digitos';
    }
    if (_identifierType == 'phone') {
      final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length < 10) return 'Telefone invalido';
    }
    if (_identifierType == 'email') {
      if (!v.contains('@')) return 'E-mail invalido';
    }
    return null;
  }

  /// Busca o email real na coleção pública `identifiers`.
  Future<String?> _getEmailByIdentifier(String identifier) async {
    final snap = await FirebaseFirestore.instance
        .collection('identifiers')
        .doc(identifier.trim().toLowerCase())
        .get();
    if (snap.exists) {
      return snap.data()?['email'] as String?;
    }
    return null;
  }

  /// Login com e-mail direto (sem lookup em identifiers).
  Future<void> _submitEmailLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailLoginCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final msg = switch (e.code) {
        'user-not-found' => 'E-mail nao encontrado.',
        'wrong-password' => 'Senha incorreta.',
        'invalid-credential' => 'E-mail ou senha incorretos.',
        _ => e.message ?? 'Erro de autenticacao.',
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Login via CPF ou Telefone (lookup em identifiers).
  Future<void> _submitIdentifierLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final identifier = _identifierCtrl.text.trim();
      final email = await _getEmailByIdentifier(identifier);
      if (email == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Identificador nao encontrado.')),
          );
        }
        return;
      }
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: _passCtrl.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final msg = switch (e.code) {
        'wrong-password' => 'Senha incorreta.',
        'invalid-credential' => 'Identificador ou senha incorretos.',
        _ => e.message ?? 'Erro de autenticacao.',
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Cadastro novo usuário.
  Future<void> _submitRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final auth = FirebaseAuth.instance;
      final identifier = _identifierCtrl.text.trim();
      final email = _identifierType == 'email'
          ? identifier
          : _emailRegisterCtrl.text.trim();
      final cred = await auth.createUserWithEmailAndPassword(
        email: email,
        password: _passCtrl.text.trim(),
      );
      await UserRepository(FirebaseFirestore.instance).createUser(
        UserModel(
          uid: cred.user!.uid,
          name: _nameCtrl.text.trim(),
          email: email,
          role: 'user',
          identifier: identifier.toLowerCase(),
          identifierType: _identifierType,
        ),
      );
      final key = identifier.trim().toLowerCase();
      await FirebaseFirestore.instance.collection('identifiers').doc(key).set({
        'email': email,
        'identifier_type': _identifierType,
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final msg = switch (e.code) {
        'email-already-in-use' => 'Este e-mail ja esta cadastrado.',
        'weak-password' => 'Senha fraca — minimo 6 caracteres.',
        _ => e.message ?? 'Erro de autenticacao.',
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Login / cadastro com Google.
  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // usuário cancelou
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCred = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      final user = userCred.user!;
      // Se for o primeiro login com Google, cria o documento no Firestore
      final isNew = userCred.additionalUserInfo?.isNewUser ?? false;
      if (isNew) {
        final email = user.email ?? '';
        final name = user.displayName ?? '';
        await UserRepository(FirebaseFirestore.instance).createUser(
          UserModel(
            uid: user.uid,
            name: name,
            email: email,
            role: 'user',
            identifier: email.toLowerCase(),
            identifierType: 'email',
          ),
        );
        await FirebaseFirestore.instance
            .collection('identifiers')
            .doc(email.toLowerCase())
            .set({'email': email, 'identifier_type': 'email'});
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Erro ao entrar com Google.')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  Future<void> _signInWithApple() async {
    setState(() => _loading = true);
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final idToken = appleCredential.identityToken;
      if (idToken == null || idToken.isEmpty) {
        throw Exception(
          'Apple não retornou um token de identidade. '
          'Verifique suas configurações de conta Apple e tente novamente.',
        );
      }

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: idToken,
        rawNonce: rawNonce,
        accessToken: appleCredential.authorizationCode,
      );

      final userCred = await FirebaseAuth.instance.signInWithCredential(
        oauthCredential,
      );

      final isNew = userCred.additionalUserInfo?.isNewUser ?? false;
      if (isNew) {
        final user = userCred.user!;
        final email = user.email ?? appleCredential.email ?? '';
        final firstName = appleCredential.givenName ?? '';
        final lastName = appleCredential.familyName ?? '';
        final name = [
          firstName,
          lastName,
        ].where((s) => s.isNotEmpty).join(' ').trim();

        await UserRepository(FirebaseFirestore.instance).createUser(
          UserModel(
            uid: user.uid,
            name: name.isNotEmpty ? name : 'Usuário Apple',
            email: email,
            role: 'user',
            identifier: email.toLowerCase(),
            identifierType: 'email',
          ),
        );
        if (email.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('identifiers')
              .doc(email.toLowerCase())
              .set({'email': email, 'identifier_type': 'email'});
        }
      }
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return;
      if (!mounted) return;
      final msg = switch (e.code) {
        AuthorizationErrorCode.failed =>
          'Falha na autenticação com Apple. Verifique as configurações da sua conta Apple ID.',
        AuthorizationErrorCode.invalidResponse =>
          'Resposta inválida da Apple. Tente novamente.',
        AuthorizationErrorCode.notHandled =>
          'A autenticação Apple não pôde ser concluída. Tente novamente.',
        AuthorizationErrorCode.notInteractive =>
          'A autenticação Apple requer interação do usuário. Tente novamente.',
        AuthorizationErrorCode.unknown =>
          'Erro desconhecido na autenticação Apple. Tente novamente.',
        _ => 'Erro ao entrar com Apple: ${e.message}',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 5)),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final msg = switch (e.code) {
        'invalid-credential' => 'Credencial Apple inválida. Tente novamente.',
        'user-disabled' => 'Esta conta foi desabilitada.',
        'operation-not-allowed' =>
          'Login com Apple não está habilitado neste app.',
        'network-request-failed' =>
          'Sem conexão com a internet. Verifique sua rede e tente novamente.',
        _ => e.message ?? 'Erro de autenticação com Apple.',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 5)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _exploreAsGuest() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ServicesCatalogScreen(isGuestMode: true),
      ),
    );
  }

  Future<void> _forgotPassword() async {
    // Mostra campos distintos dependendo do tipo de identificador
    final identifierCtrl = TextEditingController(
      text: _identifierType == 'email'
          ? _emailLoginCtrl.text.trim()
          : _identifierCtrl.text.trim(),
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Redefinir senha'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Digite o identificador cadastrado.\n'
              'Enviaremos um link de redefinição para o e-mail associado.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: identifierCtrl,
              keyboardType: _identifierKeyboard(),
              autofocus: true,
              decoration: InputDecoration(
                labelText: _identifierLabel(),
                prefixIcon: Icon(_identifierIcon()),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Enviar link'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final identifier = identifierCtrl.text.trim();
    identifierCtrl.dispose();
    if (identifier.isEmpty) return;
    setState(() => _loading = true);
    try {
      String? email;
      if (_identifierType == 'email') {
        email = identifier;
      } else {
        email = await _getEmailByIdentifier(identifier);
      }
      if (email == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Identificador nao encontrado.')),
          );
        }
        return;
      }
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Link de redefinicao enviado para o e-mail cadastrado.',
            ),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Erro ao enviar e-mail.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _switchMode() {
    setState(() {
      _isLogin = !_isLogin;
      _formKey.currentState?.reset();
      _nameCtrl.clear();
      _emailLoginCtrl.clear();
      _emailRegisterCtrl.clear();
      _identifierCtrl.clear();
      _passCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/images/lavamax_logo.png', height: 100),
                  const SizedBox(height: 16),
                  Text(
                    _isLogin ? 'Bem-vindo de volta!' : 'Crie sua conta',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 32),
                  // ── Seletor de tipo de identificador ──────────────
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'email',
                        label: Text('E-mail'),
                        icon: Icon(Icons.email_outlined),
                      ),
                      ButtonSegment(
                        value: 'cpf',
                        label: Text('CPF'),
                        icon: Icon(Icons.badge_outlined),
                      ),
                      ButtonSegment(
                        value: 'phone',
                        label: Text('Telefone'),
                        icon: Icon(Icons.phone_outlined),
                      ),
                    ],
                    selected: {_identifierType},
                    onSelectionChanged: (s) => setState(() {
                      _identifierType = s.first;
                      _identifierCtrl.clear();
                      _emailLoginCtrl.clear();
                    }),
                  ),
                  const SizedBox(height: 20),
                  // ── Campo principal de identificador ───────────────
                  if (_identifierType == 'email' && _isLogin)
                    // Login por e-mail: campo direto
                    TextFormField(
                      controller: _emailLoginCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (v) => (v == null || !v.contains('@'))
                          ? 'E-mail invalido'
                          : null,
                    )
                  else
                    TextFormField(
                      controller: _identifierCtrl,
                      keyboardType: _identifierKeyboard(),
                      inputFormatters:
                          (_identifierType == 'cpf' ||
                              _identifierType == 'phone')
                          ? [FilteringTextInputFormatter.digitsOnly]
                          : null,
                      decoration: InputDecoration(
                        labelText: _identifierLabel(),
                        prefixIcon: Icon(_identifierIcon()),
                      ),
                      validator: _validateIdentifier,
                    ),
                  const SizedBox(height: 16),
                  // ── Campos extras apenas no cadastro ───────────────
                  if (!_isLogin) ...[
                    TextFormField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nome completo',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Informe seu nome'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    // Se o identificador NÃO for e-mail, pede e-mail separado
                    if (_identifierType != 'email') ...[
                      TextFormField(
                        controller: _emailRegisterCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (v) => (v == null || !v.contains('@'))
                            ? 'E-mail invalido'
                            : null,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                  // ── Senha ──────────────────────────────────────────
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: !_passVisible,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip: _passVisible
                            ? 'Ocultar senha'
                            : 'Mostrar senha',
                        icon: Icon(
                          _passVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () =>
                            setState(() => _passVisible = !_passVisible),
                      ),
                    ),
                    validator: (v) => (v == null || v.length < 6)
                        ? 'Minimo 6 caracteres'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  // ── Botão principal ────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loading
                          ? null
                          : () {
                              if (_isLogin) {
                                if (_identifierType == 'email') {
                                  _submitEmailLogin();
                                } else {
                                  _submitIdentifierLogin();
                                }
                              } else {
                                _submitRegister();
                              }
                            },
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_isLogin ? 'Entrar' : 'Cadastrar'),
                    ),
                  ),
                  // ── Esqueci minha senha ────────────────────────────
                  if (_isLogin) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: _loading ? null : _forgotPassword,
                        child: const Text('Esqueci minha senha'),
                      ),
                    ),
                  ],
                  // ── Divisor ────────────────────────────────────────
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'ou',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // ── Botão Google ───────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _loading ? null : _signInWithGoogle,
                      icon: Image.asset(
                        'assets/icons/google_logo.png',
                        height: 20,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.g_mobiledata, size: 22),
                      ),
                      label: const Text('Continuar com Google'),
                    ),
                  ),
                  // ── Botão Apple (apenas iOS) ────────────────────────
                  if (defaultTargetPlatform == TargetPlatform.iOS) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: SignInWithAppleButton(
                        onPressed: _loading ? () {} : _signInWithApple,
                        style: SignInWithAppleButtonStyle.black,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(8),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  // ── Alternar login / cadastro ──────────────────────
                  TextButton(
                    onPressed: _switchMode,
                    child: Text(
                      _isLogin
                          ? 'Nao tem conta? Cadastre-se'
                          : 'Ja tem conta? Entre',
                    ),
                  ),
                  // ── Explorar sem login ──────────────────────────────
                  TextButton(
                    onPressed: _loading ? null : _exploreAsGuest,
                    child: Text(
                      'Explorar serviços sem login',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
