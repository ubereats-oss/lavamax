import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:lavamax/core/constants/app_colors.dart';
import 'package:lavamax/core/constants/app_dimensions.dart';
import 'package:lavamax/data/models/user_model.dart';
import 'package:lavamax/data/repositories/appointment_repository.dart';
import 'package:lavamax/data/repositories/user_repository.dart';
import 'package:lavamax/data/services/firebase_service.dart';
import 'package:lavamax/firebase_options.dart';
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}
class _AdminUsersScreenState extends State<AdminUsersScreen> {
  // Bug 4: repositórios recebem FirebaseFirestore via construtor
  final _userRepo = UserRepository(FirebaseService().firestore);
  final _appointmentRepo =
      AppointmentRepository(FirebaseService().firestore);
  List<UserModel> _users = [];
  bool _loading = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _userRepo.getAllUsers();
      if (mounted) setState(() => _users = list);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
  void _openDetail(UserModel user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _UserDetailScreen(
          user: user,
          userRepo: _userRepo,
          appointmentRepo: _appointmentRepo,
          onChanged: _load,
        ),
      ),
    );
  }
  void _openCreate() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _CreateUserScreen(
          userRepo: _userRepo,
          onCreated: _load,
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Novo usuario'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Erro: $_error',
                          style:
                              const TextStyle(color: AppColors.error)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: _load,
                          child: const Text('Tentar novamente')),
                    ],
                  ),
                )
              : _users.isEmpty
                  ? const Center(
                      child: Text('Nenhum usuario encontrado.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _users.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final user = _users[i];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: user.isMaster
                                  ? Colors.amber.shade100
                                  : AppColors.grey200,
                              child: Icon(
                                user.isMaster
                                    ? Icons.star
                                    : Icons.person_outline,
                                color: user.isMaster
                                    ? Colors.amber.shade700
                                    : AppColors.grey600,
                              ),
                            ),
                            title: Text(
                              user.name.isNotEmpty
                                  ? user.name
                                  : '(sem nome)',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(user.email),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: user.isMaster
                                    ? Colors.amber.shade100
                                    : AppColors.grey200,
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                              child: Text(
                                user.isMaster ? 'Master' : 'Usuario',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: user.isMaster
                                      ? Colors.amber.shade800
                                      : AppColors.grey700,
                                ),
                              ),
                            ),
                            onTap: () => _openDetail(user),
                          ),
                        );
                      },
                    ),
    );
  }
}
// ─────────────────────────────────────────
// Tela de detalhe / edição de usuário
// ─────────────────────────────────────────
class _UserDetailScreen extends StatefulWidget {
  final UserModel user;
  final UserRepository userRepo;
  final AppointmentRepository appointmentRepo;
  final VoidCallback onChanged;
  const _UserDetailScreen({
    required this.user,
    required this.userRepo,
    required this.appointmentRepo,
    required this.onChanged,
  });
  @override
  State<_UserDetailScreen> createState() => _UserDetailScreenState();
}
class _UserDetailScreenState extends State<_UserDetailScreen> {
  late final TextEditingController _nameCtrl;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.name);
  }
  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }
  Future<void> _saveEdits() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nome e obrigatorio.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      // UX 2: apenas o nome é editável — email só pode ser alterado pelo
      // próprio usuário via Firebase Auth (client SDK não permite ao admin)
      await widget.userRepo.updateName(widget.user.uid, name: name);
      widget.onChanged();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nome atualizado.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
  Future<void> _toggleRole() async {
    final newRole =
        widget.user.isMaster ? 'customer' : 'master';
    final label = newRole == 'master' ? 'Master' : 'Usuario';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Alterar perfil'),
        content: Text(
            'Definir "${widget.user.name}" como $label?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar')),
        ],
      ),
    );
    if (confirm == true) {
      await widget.userRepo.updateRole(widget.user.uid, newRole);
      widget.onChanged();
      if (mounted) Navigator.pop(context);
    }
  }
  Future<void> _delete() async {
    int activeCount = 0;
    try {
      final all = await widget.appointmentRepo
          .getAppointmentsByCustomer(widget.user.uid);
      activeCount = all
          .where((a) =>
              a.status == 'pending' || a.status == 'confirmed')
          .length;
    } catch (_) {}
    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir usuario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tem certeza que deseja excluir "${widget.user.name}"?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Isso vai causar:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  if (activeCount > 0)
                    Text(
                      '• $activeCount agendamento(s) ativo(s) serao cancelados e os slots liberados',
                    ),
                  const Text(
                      '• Todos os agendamentos do usuario serao excluidos'),
                  const Text(
                      '• O documento do usuario sera removido'),
                  const SizedBox(height: 6),
                  const Text(
                    'Esta acao nao pode ser desfeita.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _saving = true);
      try {
        await widget.appointmentRepo
            .cancelAndDeleteAllByCustomer(widget.user.uid);
        await widget.userRepo.deleteUserData(widget.user.uid);
        widget.onChanged();
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Usuario excluido.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Usuario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            tooltip: 'Excluir usuario',
            onPressed: _saving ? null : _delete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(
            AppDimensions.screenPaddingHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppDimensions.paddingLarge),
            // Informações somente leitura
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(AppDimensions.paddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('UID'),
                    SelectableText(
                      widget.user.uid,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.grey600),
                    ),
                    const SizedBox(height: AppDimensions.paddingSmall),
                    _label('Email (somente leitura)'),
                    Text(widget.user.email),
                    const SizedBox(height: 4),
                    const Text(
                      'O email só pode ser alterado pelo próprio usuário.',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.grey500),
                    ),
                    const SizedBox(height: AppDimensions.paddingSmall),
                    _label('Identificador'),
                    Text(widget.user.identifier.isNotEmpty
                        ? '${widget.user.identifier} (${widget.user.identifierType})'
                        : '—'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            // Campo editável: apenas nome
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(AppDimensions.paddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Editar nome',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: AppDimensions.paddingMedium),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nome',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingMedium),
                    ElevatedButton(
                      onPressed: _saving ? null : _saveEdits,
                      child: _saving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2),
                            )
                          : const Text('Salvar nome'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            // Perfil
            Card(
              child: ListTile(
                leading: Icon(
                  widget.user.isMaster ? Icons.star : Icons.person_outline,
                  color: widget.user.isMaster
                      ? Colors.amber.shade700
                      : AppColors.grey600,
                ),
                title: Text(
                    'Perfil atual: ${widget.user.isMaster ? 'Master' : 'Usuario'}'),
                subtitle: Text(widget.user.isMaster
                    ? 'Toque para rebaixar para Usuario'
                    : 'Toque para promover a Master'),
                trailing: const Icon(Icons.swap_horiz),
                onTap: _saving ? null : _toggleRole,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingLarge),
          ],
        ),
      ),
    );
  }
  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(text,
            style: const TextStyle(
                fontSize: 11,
                color: AppColors.grey500,
                fontWeight: FontWeight.bold)),
      );
}
// ─────────────────────────────────────────
// Tela de criação de novo usuário
// ─────────────────────────────────────────
class _CreateUserScreen extends StatefulWidget {
  final UserRepository userRepo;
  final VoidCallback onCreated;
  const _CreateUserScreen({
    required this.userRepo,
    required this.onCreated,
  });
  @override
  State<_CreateUserScreen> createState() => _CreateUserScreenState();
}
class _CreateUserScreenState extends State<_CreateUserScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _role = 'customer';
  bool _loading = false;
  bool _obscure = true;
  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }
  Future<void> _create() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (name.isEmpty || email.isEmpty || password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Preencha nome, email e senha (minimo 6 caracteres).')),
      );
      return;
    }
    setState(() => _loading = true);
    // Usa app secundário para não deslogar o admin
    FirebaseApp? secondaryApp;
    try {
      secondaryApp = await Firebase.initializeApp(
        name: 'AdminCreatedUser_${DateTime.now().millisecondsSinceEpoch}',
        options: DefaultFirebaseOptions.currentPlatform,
      );
      final secondaryAuth =
          FirebaseAuth.instanceFor(app: secondaryApp);
      final cred = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = cred.user!.uid;
      await widget.userRepo.createUser(UserModel(
        uid: uid,
        name: name,
        email: email,
        role: _role,
        identifier: email.toLowerCase(),
        identifierType: 'email',
      ));
      // Bug 5: grava entrada em identifiers para que o login funcione
      await FirebaseService().firestore
          .collection('identifiers')
          .doc(email.toLowerCase())
          .set({
        'uid': uid,
        'identifier_type': 'email',
      });
      widget.onCreated();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Usuario "$name" criado com sucesso.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao criar usuario: $e')),
        );
      }
    } finally {
      await secondaryApp?.delete();
      if (mounted) setState(() => _loading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo Usuario')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(
            AppDimensions.screenPaddingHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppDimensions.paddingLarge),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nome completo',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Senha',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: () =>
                      setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: const InputDecoration(
                labelText: 'Perfil',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.manage_accounts_outlined),
              ),
              items: const [
                DropdownMenuItem(
                    value: 'customer', child: Text('Usuario')),
                DropdownMenuItem(
                    value: 'master', child: Text('Master')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _role = v);
              },
            ),
            const SizedBox(height: AppDimensions.paddingLarge),
            ElevatedButton(
              onPressed: _loading ? null : _create,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Criar usuario'),
            ),
          ],
        ),
      ),
    );
  }
}
