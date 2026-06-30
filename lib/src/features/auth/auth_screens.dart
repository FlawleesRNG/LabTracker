part of '../../../main.dart';

const String _authContinueOfflineResult = '__labtracker_continue_offline__';

class AuthGate extends StatefulWidget {
  final Widget child;

  const AuthGate({super.key, required this.child});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool loading = true;
  bool accessGranted = false;
  String? message;

  @override
  void initState() {
    super.initState();
    checkInitialAccess();
  }

  Future<void> checkInitialAccess() async {
    if (AuthService.isAvailable && AuthService.isLoggedIn) {
      await AuthService.persistCurrentUser();
      if (!mounted) return;
      setState(() {
        accessGranted = true;
        loading = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      accessGranted = false;
      loading = false;
    });
  }

  Future<void> openLogin() async {
    final String? result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const SupabaseLoginPage(
          continueOfflineResult: _authContinueOfflineResult,
        ),
      ),
    );

    if (!mounted) return;

    if (result == _authContinueOfflineResult) {
      continueOffline();
      return;
    }

    if (AuthService.isLoggedIn) {
      await AuthService.persistCurrentUser();
      if (!mounted) return;
      setState(() {
        accessGranted = true;
      });
      return;
    }

    if ((result ?? '').trim().isNotEmpty) {
      setState(() {
        message = result;
      });
    }
  }

  Future<void> openSignUp() async {
    final String? result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const SupabaseSignUpPage(
          continueOfflineResult: _authContinueOfflineResult,
        ),
      ),
    );

    if (!mounted) return;

    if (result == _authContinueOfflineResult) {
      continueOffline();
      return;
    }

    if (AuthService.isLoggedIn) {
      await AuthService.persistCurrentUser();
      if (!mounted) return;
      setState(() {
        accessGranted = true;
      });
      return;
    }

    if ((result ?? '').trim().isNotEmpty) {
      setState(() {
        message = result;
      });
    }
  }

  void continueOffline() {
    setState(() {
      accessGranted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (accessGranted) {
      return widget.child;
    }

    return StartupAccessPage(
      message: message,
      supabaseAvailable: AuthService.isAvailable,
      supabaseConfigured: SupabaseConfig.hasCredentials,
      onLogin: AuthService.isAvailable ? openLogin : null,
      onSignUp: AuthService.isAvailable ? openSignUp : null,
      onContinueOffline: continueOffline,
    );
  }
}

class StartupAccessPage extends StatelessWidget {
  final String? message;
  final bool supabaseAvailable;
  final bool supabaseConfigured;
  final VoidCallback? onLogin;
  final VoidCallback? onSignUp;
  final VoidCallback onContinueOffline;

  const StartupAccessPage({
    super.key,
    this.message,
    required this.supabaseAvailable,
    required this.supabaseConfigured,
    required this.onLogin,
    required this.onSignUp,
    required this.onContinueOffline,
  });

  @override
  Widget build(BuildContext context) {
    final String subtitle = supabaseAvailable
        ? 'Registre suas partidas, acompanhe seu progresso e sincronize PC e celular.'
        : 'Registre suas partidas e acompanhe seu progresso offline.';
    final String secondaryText = supabaseAvailable
        ? 'Voce pode usar o LabTracker offline. O login serve para backup e sincronizacao.'
        : supabaseConfigured
        ? 'Nao foi possivel iniciar a conta online agora. Voce pode continuar offline normalmente.'
        : 'Supabase nao esta configurado neste build. Voce pode continuar offline normalmente.';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: context.responsivePagePadding,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: AppSurfaceCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: LtMark(size: 86, bordered: true)),
                    const SizedBox(height: AppSpacing.xl),
                    const Center(child: LtLogo(scale: 1.25)),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: BrandColors.brancoSuave.withValues(alpha: 0.78),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    if ((message ?? '').trim().isNotEmpty) ...[
                      AuthMessageBox(
                        text: message!,
                        color: BrandColors.ambarDourado,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    if (supabaseAvailable) ...[
                      FilledButton.icon(
                        onPressed: onLogin,
                        icon: const Icon(Icons.login_outlined),
                        label: const Text('Entrar'),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton.icon(
                        onPressed: onSignUp,
                        icon: const Icon(Icons.person_add_alt_outlined),
                        label: const Text('Criar conta'),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    OutlinedButton.icon(
                      onPressed: onContinueOffline,
                      icon: const Icon(Icons.offline_bolt_outlined),
                      label: const Text('Continuar offline'),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      secondaryText,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: BrandColors.brancoSuave.withValues(alpha: 0.62),
                      ),
                    ),
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

class AccountSyncPage extends StatefulWidget {
  final String deviceId;
  final String? currentUserId;
  final DateTime? lastSyncAt;
  final int pendingSyncCount;
  final int syncErrorCount;
  final ValueListenable<SyncActivitySnapshot>? syncActivityListenable;
  final Future<SyncRunResult> Function()? onSyncNow;
  final Future<void> Function(bool enabled)? onAutoSyncChanged;

  const AccountSyncPage({
    super.key,
    required this.deviceId,
    required this.currentUserId,
    required this.lastSyncAt,
    required this.pendingSyncCount,
    required this.syncErrorCount,
    this.syncActivityListenable,
    this.onSyncNow,
    this.onAutoSyncChanged,
  });

  @override
  State<AccountSyncPage> createState() => _AccountSyncPageState();
}

class _AccountSyncPageState extends State<AccountSyncPage> {
  StreamSubscription<AuthState>? authSubscription;
  bool loading = false;
  bool syncing = false;
  String? successMessage;
  String? errorMessage;
  String? storedUserId;
  String? storedUserEmail;
  String? storedUserNick;
  late String currentDeviceId;
  late int pendingSyncCount;
  late int syncErrorCount;
  DateTime? lastSyncAt;
  bool autoSyncEnabled = true;

  @override
  void initState() {
    super.initState();
    storedUserId = widget.currentUserId;
    currentDeviceId = widget.deviceId;
    pendingSyncCount = widget.pendingSyncCount;
    syncErrorCount = widget.syncErrorCount;
    lastSyncAt = widget.lastSyncAt;
    carregarUsuarioLocal();
    carregarPreferenciaAutoSync();
    widget.syncActivityListenable?.addListener(aplicarSnapshotSyncExterno);
    aplicarSnapshotSyncExterno();
    authSubscription = AuthService.authStateChanges.listen((_) {
      carregarUsuarioLocal();
    });
  }

  @override
  void didUpdateWidget(covariant AccountSyncPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.syncActivityListenable == widget.syncActivityListenable) {
      return;
    }

    oldWidget.syncActivityListenable?.removeListener(
      aplicarSnapshotSyncExterno,
    );
    widget.syncActivityListenable?.addListener(aplicarSnapshotSyncExterno);
    aplicarSnapshotSyncExterno();
  }

  void aplicarSnapshotSyncExterno() {
    final SyncActivitySnapshot? snapshot = widget.syncActivityListenable?.value;
    if (snapshot == null || !mounted) return;

    setState(() {
      syncing = snapshot.syncing;
      pendingSyncCount = snapshot.pendingSyncCount;
      syncErrorCount = snapshot.syncErrorCount;
      lastSyncAt = snapshot.lastSyncAt;
      if (snapshot.message.trim().isNotEmpty) {
        if (!snapshot.syncing && snapshot.syncErrorCount > 0) {
          errorMessage = snapshot.message;
          successMessage = null;
        } else {
          successMessage = snapshot.message;
          errorMessage = null;
        }
      }
    });
  }

  Future<void> carregarPreferenciaAutoSync() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool enabled = prefs.getBool(prefsKeyAutoSyncEnabled) ?? true;

    if (!mounted) return;
    setState(() {
      autoSyncEnabled = enabled;
    });
  }

  Future<void> alterarAutoSync(bool enabled) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefsKeyAutoSyncEnabled, enabled);
    await marcarSnapshotExternoPendenteParaSync();
    await widget.onAutoSyncChanged?.call(enabled);

    if (!mounted) return;
    setState(() {
      autoSyncEnabled = enabled;
      successMessage = enabled
          ? 'Sincronizacao automatica ativada.'
          : 'Sincronizacao automatica desativada. O botao manual continua disponivel.';
      errorMessage = null;
    });
  }

  @override
  void dispose() {
    widget.syncActivityListenable?.removeListener(aplicarSnapshotSyncExterno);
    authSubscription?.cancel();
    super.dispose();
  }

  Future<void> carregarUsuarioLocal() async {
    final String? userId = AuthService.currentUserId;
    if (userId != null) {
      await AuthService.persistCurrentUser();
    }
    final String? email = userId == null
        ? null
        : AuthService.currentUserEmail ??
              await AuthService.loadStoredUserEmail();
    final String? nick = userId == null
        ? null
        : AuthService.currentUserNick ?? await AuthService.loadStoredUserNick();

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

  Future<void> sincronizarAgora() async {
    if (syncing) return;

    if (!AuthService.isLoggedIn) {
      setState(() {
        errorMessage = 'Entre na sua conta antes de sincronizar.';
        successMessage = null;
      });
      return;
    }

    final Future<SyncRunResult> Function()? syncAction = widget.onSyncNow;
    if (syncAction == null) {
      setState(() {
        errorMessage = 'Sincronizacao manual indisponivel nesta tela.';
        successMessage = null;
      });
      return;
    }

    setState(() {
      syncing = true;
      successMessage = 'Sincronizando...';
      errorMessage = null;
    });

    try {
      final SyncRunResult result = await syncAction();
      await carregarUsuarioLocal();
      if (!mounted) return;

      setState(() {
        pendingSyncCount = result.pendingCount;
        syncErrorCount = result.errorCount;
        lastSyncAt = result.syncedAt;
        currentDeviceId = result.deviceId;
        successMessage = result.success
            ? '${result.message} Enviados: ${result.uploadedCount}. Baixados: ${result.downloadedCount}.'
            : result.message;
        errorMessage = result.success
            ? null
            : '${result.failedCount} item(ns) ficaram com erro e continuam salvos localmente.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        successMessage = null;
        errorMessage = AuthService.friendlyError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          syncing = false;
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
            'Voce pode usar o LabTracker normalmente offline. Configure SUPABASE_URL e SUPABASE_ANON_KEY para ativar login e sincronizacao.',
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
          ResponsiveActionPair(
            primary: FilledButton.icon(
              onPressed: abrirLogin,
              icon: const Icon(Icons.login_outlined),
              label: const Text('Entrar'),
            ),
            secondary: OutlinedButton.icon(
              onPressed: abrirCadastro,
              icon: const Icon(Icons.person_add_alt_outlined),
              label: const Text('Criar conta'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: autoSyncEnabled,
            onChanged: alterarAutoSync,
            title: const Text('Sincronizacao automatica'),
            subtitle: const Text(
              'Fica preparada para rodar quando voce entrar na conta.',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: syncing ? null : sincronizarAgora,
              icon: const Icon(Icons.sync_outlined),
              label: const Text('Sincronizar agora'),
            ),
          ),
        ],
      ),
    );
  }

  Widget accountCard() {
    final String email = storedUserEmail ?? AuthService.currentUserEmail ?? '';
    final String nick = storedUserNick ?? AuthService.currentUserNick ?? '';
    final String userId = storedUserId ?? AuthService.currentUserId ?? '';
    final String statusLabel = syncing
        ? 'Sincronizando...'
        : syncErrorCount > 0
        ? 'Erro de sincronizacao'
        : pendingSyncCount > 0
        ? 'Sincronizacao pendente'
        : lastSyncAt == null
        ? 'Sincronizacao pendente'
        : 'Sincronizado';
    final Color statusColor = syncing
        ? BrandColors.laranjaVivo
        : syncErrorCount > 0
        ? BrandColors.alerta
        : pendingSyncCount > 0
        ? BrandColors.ambarDourado
        : BrandColors.sucesso;

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
                icon: syncing
                    ? Icons.sync_outlined
                    : syncErrorCount > 0
                    ? Icons.error_outline
                    : pendingSyncCount > 0
                    ? Icons.pending_actions_outlined
                    : Icons.cloud_done_outlined,
                label: statusLabel,
                color: statusColor,
              ),
              statusChip(
                icon: Icons.pending_actions_outlined,
                label: '$pendingSyncCount pendentes',
                color: BrandColors.ambarDourado,
              ),
              if (syncErrorCount > 0)
                statusChip(
                  icon: Icons.error_outline,
                  label: '$syncErrorCount erros',
                  color: BrandColors.alerta,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (nick.isNotEmpty) ...[
            Text('Nick: $nick'),
            const SizedBox(height: AppSpacing.sm),
          ],
          Text(
            lastSyncAt == null
                ? 'Ultima sincronizacao: nunca'
                : 'Ultima sincronizacao: ${formatarData(lastSyncAt!)}',
          ),
          const SizedBox(height: AppSpacing.lg),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: autoSyncEnabled,
            onChanged: loading || syncing ? null : alterarAutoSync,
            title: const Text('Sincronizacao automatica'),
            subtitle: const Text(
              'Salva local primeiro e tenta sincronizar em segundo plano.',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: loading || syncing ? null : sincronizarAgora,
              icon: syncing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync_outlined),
              label: Text(syncing ? 'Sincronizando...' : 'Sincronizar agora'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              leading: const Icon(Icons.tune_outlined),
              title: const Text('Detalhes tecnicos'),
              subtitle: const Text('Informacoes de suporte e debug'),
              children: [
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SelectableText(
                    [
                      'ID da conta: ${userId.isEmpty ? 'indisponivel' : userId}',
                      'ID deste dispositivo: ${currentDeviceId.isEmpty ? 'indisponivel' : currentDeviceId}',
                      'Status interno: $statusLabel',
                      'Ultimo erro: ${(errorMessage ?? '').trim().isEmpty ? 'nenhum erro recente' : errorMessage!.trim()}',
                      'Versao: ${ConfiguracoesPage.versaoApp}',
                    ].join('\n'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
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
    final bool logado = AuthService.isLoggedIn;

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
                    subtitle: 'Login opcional e sincronizacao',
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

class ResponsiveActionPair extends StatelessWidget {
  final Widget primary;
  final Widget secondary;

  const ResponsiveActionPair({
    super.key,
    required this.primary,
    required this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool compact = constraints.maxWidth < 420;

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              primary,
              const SizedBox(height: AppSpacing.sm),
              secondary,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: secondary),
          ],
        );
      },
    );
  }
}

class SupabaseLoginPage extends StatefulWidget {
  final String? continueOfflineResult;

  const SupabaseLoginPage({super.key, this.continueOfflineResult});

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
      MaterialPageRoute(
        builder: (context) => SupabaseSignUpPage(
          continueOfflineResult: widget.continueOfflineResult,
        ),
      ),
    );

    if (!mounted) return;
    if (mensagem == _authContinueOfflineResult) {
      Navigator.pop(context, mensagem);
      return;
    }
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
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
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
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: loading ? null : abrirCadastro,
              icon: const Icon(Icons.person_add_alt_outlined),
              label: const Text('Criar conta'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: loading
                  ? null
                  : () => Navigator.pop(context, widget.continueOfflineResult),
              icon: const Icon(Icons.offline_bolt_outlined),
              label: const Text('Continuar offline'),
            ),
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
  final String? continueOfflineResult;

  const SupabaseSignUpPage({super.key, this.continueOfflineResult});

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
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
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
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: loading ? null : () => Navigator.pop(context),
              icon: const Icon(Icons.login_outlined),
              label: const Text('Ja tenho conta'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: loading
                  ? null
                  : () => Navigator.pop(context, widget.continueOfflineResult),
              icon: const Icon(Icons.offline_bolt_outlined),
              label: const Text('Continuar offline'),
            ),
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
