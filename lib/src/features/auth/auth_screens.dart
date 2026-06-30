part of '../../../main.dart';

class AccountSyncPage extends StatefulWidget {
  final String deviceId;
  final String? currentUserId;
  final int pendingSyncCount;
  final int syncErrorCount;

  const AccountSyncPage({
    super.key,
    required this.deviceId,
    required this.currentUserId,
    required this.pendingSyncCount,
    required this.syncErrorCount,
  });

  @override
  State<AccountSyncPage> createState() => _AccountSyncPageState();
}

class _AccountSyncPageState extends State<AccountSyncPage> {
  StreamSubscription<AuthState>? authSubscription;
  bool loading = false;
  String? successMessage;
  String? errorMessage;
  String? storedUserId;
  String? storedUserEmail;
  String? storedUserNick;

  @override
  void initState() {
    super.initState();
    storedUserId = widget.currentUserId;
    carregarUsuarioLocal();
    authSubscription = AuthService.authStateChanges.listen((_) {
      carregarUsuarioLocal();
    });
  }

  @override
  void dispose() {
    authSubscription?.cancel();
    super.dispose();
  }

  Future<void> carregarUsuarioLocal() async {
    final String? userId = await AuthService.resolveCurrentUserId();
    final String? email =
        AuthService.currentUserEmail ?? await AuthService.loadStoredUserEmail();
    final String? nick =
        AuthService.currentUserNick ?? await AuthService.loadStoredUserNick();

    if (!mounted) return;

    setState(() {
      storedUserId = userId;
      storedUserEmail = email;
      storedUserNick = nick;
    });
  }

  Future<void> abrirLogin() async {
    final String? mensagem = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const SupabaseLoginPage()),
    );

    await carregarUsuarioLocal();
    if (!mounted) return;

    if (mensagem != null && mensagem.trim().isNotEmpty) {
      setState(() {
        successMessage = mensagem;
        errorMessage = null;
      });
    }
  }

  Future<void> abrirCadastro() async {
    final String? mensagem = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const SupabaseSignUpPage()),
    );

    await carregarUsuarioLocal();
    if (!mounted) return;

    if (mensagem != null && mensagem.trim().isNotEmpty) {
      setState(() {
        successMessage = mensagem;
        errorMessage = null;
      });
    }
  }

  Future<void> sair() async {
    setState(() {
      loading = true;
      successMessage = null;
      errorMessage = null;
    });

    try {
      await AuthService.signOut();
      await carregarUsuarioLocal();
      if (!mounted) return;
      setState(() {
        successMessage = 'Conta desconectada. O uso local continua normal.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        errorMessage = AuthService.friendlyError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Widget statusChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.sm),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
    );
  }

  Widget configMissingCard() {
    final String erro = SupabaseConfig.initializationError.trim();

    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionTitle(
            title: 'Usando offline',
            subtitle: 'Supabase nao configurado',
            trailing: Icon(Icons.cloud_off_outlined),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'Voce pode usar o LabTracker normalmente offline. Configure SUPABASE_URL e SUPABASE_ANON_KEY para ativar login e sincronizacao futura.',
          ),
          if (erro.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            AuthMessageBox(text: erro, color: BrandColors.alerta),
          ],
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.offline_bolt_outlined),
              label: const Text('Continuar offline'),
            ),
          ),
        ],
      ),
    );
  }

  Widget offlineCard() {
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionTitle(
            title: 'Usando offline',
            subtitle: 'Conta opcional',
            trailing: Icon(Icons.offline_bolt_outlined),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'Voce pode usar o LabTracker offline. Entre em uma conta para sincronizar PC e celular.',
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: abrirLogin,
                  icon: const Icon(Icons.login_outlined),
                  label: const Text('Entrar'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: abrirCadastro,
                  icon: const Icon(Icons.person_add_alt_outlined),
                  label: const Text('Criar conta'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget accountCard() {
    final String email = storedUserEmail ?? AuthService.currentUserEmail ?? '';
    final String nick = storedUserNick ?? AuthService.currentUserNick ?? '';
    final String userId = storedUserId ?? AuthService.currentUserId ?? '';

    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionTitle(
            title: 'Conta conectada',
            subtitle: email.isEmpty ? 'Sessao ativa' : email,
            trailing: const Icon(Icons.verified_user_outlined),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              statusChip(
                icon: Icons.cloud_done_outlined,
                label: 'Logado',
                color: BrandColors.sucesso,
              ),
              statusChip(
                icon: Icons.pending_actions_outlined,
                label: '${widget.pendingSyncCount} pendentes',
                color: BrandColors.ambarDourado,
              ),
              if (widget.syncErrorCount > 0)
                statusChip(
                  icon: Icons.error_outline,
                  label: '${widget.syncErrorCount} erros',
                  color: BrandColors.alerta,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (nick.isNotEmpty) ...[
            Text('Nick: $nick'),
            const SizedBox(height: AppSpacing.sm),
          ],
          SelectableText('User ID: $userId'),
          const SizedBox(height: AppSpacing.sm),
          SelectableText('Device ID: ${widget.deviceId}'),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.sync_outlined),
              label: const Text('Sincronizar agora em breve'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: loading ? null : sair,
              icon: const Icon(Icons.logout_outlined),
              label: Text(loading ? 'Saindo...' : 'Sair'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool logado = AuthService.isLoggedIn || storedUserId != null;

    return Scaffold(
      appBar: AppBar(
        title: const CompactAppBarTitle('Conta e Sync'),
        centerTitle: true,
        actions: const [HomeNavigationButton()],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: context.responsivePagePadding,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppPageHeader(
                    title: 'Conta e Sync',
                    subtitle: 'Login opcional para sync futuro',
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (errorMessage != null) ...[
                    AuthMessageBox(
                      text: errorMessage!,
                      color: BrandColors.alerta,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  if (successMessage != null) ...[
                    AuthMessageBox(
                      text: successMessage!,
                      color: BrandColors.sucesso,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  if (!AuthService.isAvailable)
                    configMissingCard()
                  else if (logado)
                    accountCard()
                  else
                    offlineCard(),
                  const SizedBox(height: AppSpacing.lg),
                  const AppSurfaceCard(
                    child: Row(
                      children: [
                        Icon(Icons.storage_outlined),
                        SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            'Dados locais continuam sendo salvos primeiro.',
                          ),
                        ),
                      ],
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

class SupabaseLoginPage extends StatefulWidget {
  const SupabaseLoginPage({super.key});

  @override
  State<SupabaseLoginPage> createState() => _SupabaseLoginPageState();
}

class _SupabaseLoginPageState extends State<SupabaseLoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool manterConectado = true;
  bool loading = false;
  bool showPassword = false;
  String? errorMessage;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  bool validar() {
    if (emailController.text.trim().isEmpty) {
      setState(() => errorMessage = 'Informe seu e-mail.');
      return false;
    }

    if (passwordController.text.trim().isEmpty) {
      setState(() => errorMessage = 'Informe sua senha.');
      return false;
    }

    return true;
  }

  Future<void> entrar() async {
    if (!validar()) return;

    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      await AuthService.signIn(
        email: emailController.text,
        password: passwordController.text,
      );
      if (!mounted) return;
      Navigator.pop(context, 'Conta conectada.');
    } catch (error) {
      if (!mounted) return;
      setState(() => errorMessage = AuthService.friendlyError(error));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> abrirCadastro() async {
    final String? mensagem = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const SupabaseSignUpPage()),
    );

    if (!mounted) return;
    if ((mensagem ?? '').trim().isNotEmpty) {
      Navigator.pop(context, mensagem);
    }
  }

  Future<void> esqueciSenha() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Recuperacao de senha'),
          content: const Text(
            'Esse fluxo sera adicionado depois. Por enquanto, use e-mail e senha para entrar.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ok'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthFormScaffold(
      title: 'LabTracker',
      subtitle:
          'Entre na sua conta para sincronizar seus dados entre PC e celular.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'E-mail',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: passwordController,
            obscureText: !showPassword,
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(
              labelText: 'Senha',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: () => setState(() => showPassword = !showPassword),
                tooltip: showPassword ? 'Ocultar senha' : 'Mostrar senha',
                icon: Icon(
                  showPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: manterConectado,
            onChanged: (value) {
              setState(() => manterConectado = value ?? true);
            },
            title: const Text('Manter conectado neste dispositivo'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          if (errorMessage != null) ...[
            AuthMessageBox(text: errorMessage!, color: BrandColors.alerta),
            const SizedBox(height: AppSpacing.md),
          ],
          FilledButton.icon(
            onPressed: loading ? null : entrar,
            icon: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.login_outlined),
            label: Text(loading ? 'Entrando...' : 'Entrar'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: loading ? null : abrirCadastro,
            icon: const Icon(Icons.person_add_alt_outlined),
            label: const Text('Criar conta'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            onPressed: loading ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.offline_bolt_outlined),
            label: const Text('Continuar offline'),
          ),
          TextButton(
            onPressed: loading ? null : esqueciSenha,
            child: const Text('Esqueci minha senha'),
          ),
        ],
      ),
    );
  }
}

class SupabaseSignUpPage extends StatefulWidget {
  const SupabaseSignUpPage({super.key});

  @override
  State<SupabaseSignUpPage> createState() => _SupabaseSignUpPageState();
}

class _SupabaseSignUpPageState extends State<SupabaseSignUpPage> {
  final TextEditingController nickController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool manterConectado = true;
  bool loading = false;
  bool showPassword = false;
  bool showConfirmPassword = false;
  String? errorMessage;
  String? successMessage;

  @override
  void dispose() {
    nickController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  bool validar() {
    if (nickController.text.trim().isEmpty) {
      setState(() => errorMessage = 'Informe seu nick.');
      return false;
    }

    if (emailController.text.trim().isEmpty) {
      setState(() => errorMessage = 'Informe seu e-mail.');
      return false;
    }

    if (passwordController.text.trim().isEmpty) {
      setState(() => errorMessage = 'Informe sua senha.');
      return false;
    }

    if (passwordController.text.trim().length < 6) {
      setState(
        () => errorMessage = 'A senha precisa ter pelo menos 6 caracteres.',
      );
      return false;
    }

    if (confirmPasswordController.text.trim() !=
        passwordController.text.trim()) {
      setState(() => errorMessage = 'A confirmacao precisa ser igual a senha.');
      return false;
    }

    return true;
  }

  Future<void> criarConta() async {
    if (!validar()) return;

    setState(() {
      loading = true;
      errorMessage = null;
      successMessage = null;
    });

    try {
      final AuthResponse response = await AuthService.signUp(
        nick: nickController.text,
        email: emailController.text,
        password: passwordController.text,
      );

      if (!mounted) return;

      if (response.session == null) {
        setState(() {
          successMessage =
              'Conta criada. Verifique seu e-mail para confirmar o acesso.';
          passwordController.clear();
          confirmPasswordController.clear();
        });
        return;
      }

      Navigator.pop(context, 'Conta criada e conectada.');
    } catch (error) {
      if (!mounted) return;
      setState(() => errorMessage = AuthService.friendlyError(error));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthFormScaffold(
      title: 'Criar conta',
      subtitle:
          'Seu progresso continua salvo localmente e sera sincronizado quando voce estiver online.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: nickController,
            autofillHints: const [AutofillHints.nickname],
            decoration: const InputDecoration(
              labelText: 'Nick',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'E-mail',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: passwordController,
            obscureText: !showPassword,
            autofillHints: const [AutofillHints.newPassword],
            decoration: InputDecoration(
              labelText: 'Senha',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: () => setState(() => showPassword = !showPassword),
                tooltip: showPassword ? 'Ocultar senha' : 'Mostrar senha',
                icon: Icon(
                  showPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: confirmPasswordController,
            obscureText: !showConfirmPassword,
            autofillHints: const [AutofillHints.newPassword],
            decoration: InputDecoration(
              labelText: 'Confirmar senha',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.lock_reset_outlined),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() => showConfirmPassword = !showConfirmPassword);
                },
                tooltip: showConfirmPassword
                    ? 'Ocultar senha'
                    : 'Mostrar senha',
                icon: Icon(
                  showConfirmPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: manterConectado,
            onChanged: (value) {
              setState(() => manterConectado = value ?? true);
            },
            title: const Text('Manter conectado neste dispositivo'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          if (errorMessage != null) ...[
            AuthMessageBox(text: errorMessage!, color: BrandColors.alerta),
            const SizedBox(height: AppSpacing.md),
          ],
          if (successMessage != null) ...[
            AuthMessageBox(text: successMessage!, color: BrandColors.sucesso),
            const SizedBox(height: AppSpacing.md),
          ],
          FilledButton.icon(
            onPressed: loading ? null : criarConta,
            icon: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.person_add_alt_outlined),
            label: Text(loading ? 'Criando...' : 'Criar conta'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: loading ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.login_outlined),
            label: const Text('Ja tenho conta'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            onPressed: loading ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.offline_bolt_outlined),
            label: const Text('Continuar offline'),
          ),
        ],
      ),
    );
  }
}

class AuthFormScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const AuthFormScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: CompactAppBarTitle(title),
        centerTitle: true,
        actions: const [HomeNavigationButton()],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: context.responsivePagePadding,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: AppSurfaceCard(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: LtMark(size: 82, bordered: true)),
                    const SizedBox(height: AppSpacing.lg),
                    const Center(child: LtLogo(scale: 1.2)),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: BrandColors.brancoSuave.withValues(alpha: 0.72),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    child,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthMessageBox extends StatelessWidget {
  final String text;
  final Color color;

  const AuthMessageBox({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(text, style: TextStyle(color: color)),
    );
  }
}
