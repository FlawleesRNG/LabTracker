part of '../../main.dart';

class HomePage extends StatefulWidget {
  final String jogoAtual;
  final String? personagemInicialNome;
  final TimePrincipalInvincible? timePrincipalInicial;
  final TimePrincipal2XKO? time2XKOInicial;
  final TimePrincipalKofXV? timeKofInicial;

  const HomePage({
    super.key,
    required this.jogoAtual,
    this.personagemInicialNome,
    this.timePrincipalInicial,
    this.time2XKOInicial,
    this.timeKofInicial,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

enum _HomePageMenuAction { conta, perfil, configuracoes, resetar }

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  static const Duration _autoSyncDebounceDuration = Duration(seconds: 3);
  static const Duration _minIntervalBetweenAutoSync = Duration(seconds: 30);
  static const Duration _foregroundAutoSyncInterval = Duration(minutes: 2);
  static const Duration _periodicAutoSyncInterval = Duration(minutes: 5);

  PlayerProfile perfil = perfilPadrao;

  late Map<String, Character> personagens;

  late String personagemAtualNome;

  TimePrincipalInvincible timePrincipalInvincible =
      timePrincipalInvincibleVazio;
  TimePrincipal2XKO timePrincipal2XKO = timePrincipal2XKOVazio;
  TimePrincipalKofXV timePrincipalKofXV = timePrincipalKofVazio;

  Map<String, String> smashCoverPreferences = {};

  List<PartidaRegistrada> historico = [];
  List<PartidaRegistrada> partidasExcluidasParaSync = [];
  List<SyncQueueItem> syncQueue = [];
  List<LocalSyncRecord> syncRecords = [];
  String deviceId = '';
  String? currentUserId;

  bool carregando = true;
  bool autoSyncEnabled = true;
  bool syncEmAndamento = false;
  bool autoSyncPendenteAposAtual = false;
  bool? ultimaConectividadeOnline;
  DateTime? lastAutoSyncAttemptAt;
  DateTime? lastAutoSyncCompletedAt;
  Timer? autoSyncDebounceTimer;
  Timer? autoSyncPeriodicTimer;
  StreamSubscription<AuthState>? authStateSubscription;
  StreamSubscription<List<ConnectivityResult>>? connectivitySubscription;

  /// Nome do personagem padrão (primeiro do roster do jogo atual).
  String get personagemPadraoDoJogo {
    final roster = rosterDoJogo(widget.jogoAtual);
    return roster.isNotEmpty ? roster.first.name : '';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    personagens = {
      for (final personagem in rosterDoJogo(widget.jogoAtual))
        personagem.name: personagem,
    };
    personagemAtualNome =
        widget.personagemInicialNome ?? personagemPadraoDoJogo;
    iniciarObservadoresSyncAutomatico();
    carregarDados();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    autoSyncDebounceTimer?.cancel();
    autoSyncPeriodicTimer?.cancel();
    authStateSubscription?.cancel();
    connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;

    final DateTime now = DateTime.now();
    final bool intervaloOk =
        lastAutoSyncCompletedAt == null ||
        now.difference(lastAutoSyncCompletedAt!) >= _foregroundAutoSyncInterval;

    if (intervaloOk) {
      agendarSyncAutomatico(motivo: 'foreground');
    }
  }

  Character get personagemAtual {
    return personagens[personagemAtualNome] ??
        personagens[personagemPadraoDoJogo] ??
        Character(
          name: personagemPadraoDoJogo,
          initial: personagemPadraoDoJogo.isNotEmpty
              ? personagemPadraoDoJogo[0].toUpperCase()
              : '?',
          rank: rankInicialDoJogo(widget.jogoAtual),
          pdl: 0,
        );
  }

  void iniciarObservadoresSyncAutomatico() {
    authStateSubscription = AuthService.authStateChanges.listen((_) async {
      await AuthService.persistCurrentUser();
      final String? resolvedUserId = await AuthService.resolveCurrentUserId();
      if (!mounted) return;

      setState(() {
        currentUserId = resolvedUserId;
      });

      if ((resolvedUserId ?? '').trim().isNotEmpty) {
        agendarSyncAutomatico(
          motivo: 'login',
          force: true,
          delay: const Duration(seconds: 2),
        );
      }
    });

    connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      final bool online = conectividadeTemRede(results);
      final bool voltouOnline = online && ultimaConectividadeOnline == false;
      ultimaConectividadeOnline = online;

      if (voltouOnline) {
        agendarSyncAutomatico(motivo: 'connection_restored', force: true);
      }
    });

    autoSyncPeriodicTimer = Timer.periodic(_periodicAutoSyncInterval, (_) {
      agendarSyncAutomatico(motivo: 'interval');
    });

    unawaited(carregarPreferenciaSyncAutomatico());
  }

  Future<void> carregarPreferenciaSyncAutomatico() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool enabled = prefs.getBool(prefsKeyAutoSyncEnabled) ?? true;

    if (!mounted) return;
    setState(() {
      autoSyncEnabled = enabled;
    });
  }

  bool conectividadeTemRede(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }

  Future<bool> temInternetProvavel() async {
    try {
      final List<ConnectivityResult> results = await Connectivity()
          .checkConnectivity();
      final bool online = conectividadeTemRede(results);
      ultimaConectividadeOnline = online;
      return online;
    } catch (_) {
      return true;
    }
  }

  void agendarSyncAutomatico({
    required String motivo,
    bool force = false,
    Duration delay = _autoSyncDebounceDuration,
  }) {
    if (!mounted || !autoSyncEnabled) return;

    if (carregando || syncEmAndamento) {
      autoSyncPendenteAposAtual = true;
      return;
    }

    final DateTime now = DateTime.now();
    Duration atrasoFinal = delay;

    if (!force && lastAutoSyncAttemptAt != null) {
      final Duration desdeUltimaTentativa = now.difference(
        lastAutoSyncAttemptAt!,
      );
      if (desdeUltimaTentativa < _minIntervalBetweenAutoSync) {
        final Duration restante =
            _minIntervalBetweenAutoSync - desdeUltimaTentativa;
        if (restante > atrasoFinal) atrasoFinal = restante;
      }
    }

    autoSyncDebounceTimer?.cancel();
    autoSyncDebounceTimer = Timer(atrasoFinal, () {
      unawaited(executarSyncAutomatico(motivo: motivo, force: force));
    });
  }

  Future<void> executarSyncAutomatico({
    required String motivo,
    bool force = false,
  }) async {
    if (!mounted || !autoSyncEnabled || carregando) return;

    if (syncEmAndamento) {
      autoSyncPendenteAposAtual = true;
      return;
    }

    if (!AuthService.isAvailable) return;

    if (!AuthService.isLoggedIn) return;

    final bool online = await temInternetProvavel();
    if (!online) return;

    final DateTime now = DateTime.now();
    if (!force && lastAutoSyncAttemptAt != null) {
      final Duration desdeUltimaTentativa = now.difference(
        lastAutoSyncAttemptAt!,
      );
      if (desdeUltimaTentativa < _minIntervalBetweenAutoSync) {
        agendarSyncAutomatico(motivo: motivo);
        return;
      }
    }

    try {
      await executarSincronizacao(automatico: true);
    } catch (_) {
      // Sync automatico e silencioso: a fila local guarda pendencias/erros.
    }
  }

  Future<bool> incorporarSnapshotsExternosPendentes() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool pendente =
        prefs.getBool(prefsKeyPendingExternalSyncSnapshot) ?? false;
    if (!pendente) return false;

    if (deviceId.trim().isEmpty) {
      deviceId = await DeviceService.obterOuCriarDeviceId();
    }

    marcarSnapshotsLocaisPendentes();
    await _salvarDadosArquivo(gerarDadosPersistidos());
    await prefs.remove(prefsKeyPendingExternalSyncSnapshot);
    return true;
  }

  List<PartidaRegistrada> get historicoDoContextoAtual {
    return filtrarHistoricoPorContextoAtual(
      historico,
      jogo: widget.jogoAtual,
      personagemAtual: personagemAtual.name,
      timePrincipalInvincible: timePrincipalInvincible,
      timePrincipal2XKO: timePrincipal2XKO,
      timePrincipalKofXV: timePrincipalKofXV,
    );
  }

  PartidaRegistrada? get ultimaPartidaDoContextoAtual {
    final List<PartidaRegistrada> partidas = historicoDoContextoAtual;
    return partidas.isEmpty ? null : partidas.first;
  }

  Map<String, dynamic> gerarDadosPersistidos() {
    return {
      'offlineFirstVersion': 1,
      'deviceId': deviceId,
      'currentUserId': currentUserId,
      'perfilJogador': perfil.toJson(),
      'jogoAtual': widget.jogoAtual,
      'personagemAtualNome': personagemAtualNome,
      'timePrincipalInvincible': timePrincipalInvincible.toJson(),
      'timePrincipal2XKO': timePrincipal2XKO.toJson(),
      'timePrincipalKofXV': timePrincipalKofXV.toJson(),
      prefsKeySmashCoverPreferences: smashCoverPreferences,
      'personagens': personagens.values
          .map((personagem) => personagem.toJson())
          .toList(),
      'historico': historico.map((partida) => partida.toJson()).toList(),
      'partidasExcluidasParaSync': partidasExcluidasParaSync
          .map((partida) => partida.toJson())
          .toList(),
      'syncRecords': syncRecords.map((record) => record.toJson()).toList(),
      'syncQueue': syncQueue.map((item) => item.toJson()).toList(),
    };
  }

  void _aplicarDadosMap(Map<String, dynamic> dados) {
    final dynamic personagensRaw = dados['personagens'];
    final dynamic historicoRaw = dados['historico'];
    final dynamic personagemAtualRaw = dados['personagemAtualNome'];
    final dynamic timePrincipalRaw = dados['timePrincipalInvincible'];
    final dynamic time2XKORaw = dados['timePrincipal2XKO'];
    final dynamic timeKofRaw = dados['timePrincipalKofXV'];
    final dynamic perfilRaw = dados['perfilJogador'];
    final dynamic smashCoverPreferencesRaw =
        dados[prefsKeySmashCoverPreferences];
    final dynamic partidasExcluidasRaw = dados['partidasExcluidasParaSync'];
    final dynamic syncRecordsRaw = dados['syncRecords'];
    final dynamic syncQueueRaw = dados['syncQueue'];
    final dynamic currentUserIdRaw = dados['currentUserId'];

    personagens = {
      for (final personagem in rosterDoJogo(widget.jogoAtual))
        personagem.name: personagem,
    };
    timePrincipalInvincible = timePrincipalInvincibleVazio;
    timePrincipal2XKO = timePrincipal2XKOVazio;
    timePrincipalKofXV = timePrincipalKofVazio;

    if (personagensRaw is List) {
      final Map<String, Character> importados = {};
      for (final item in personagensRaw) {
        if (item is Map<String, dynamic>) {
          try {
            final Character personagem = Character.fromJson(item);
            importados[personagem.name] = personagem;
          } catch (_) {}
        }
      }

      personagens.addAll(importados);
    }

    for (final personagemBase in rosterDoJogo(widget.jogoAtual)) {
      personagens.putIfAbsent(personagemBase.name, () => personagemBase);
    }

    historico = [];
    partidasExcluidasParaSync = [];
    if (historicoRaw is List) {
      final List<PartidaRegistrada> importadas = [];
      final List<PartidaRegistrada> excluidas = [];
      for (final item in historicoRaw) {
        if (item is Map<String, dynamic>) {
          try {
            final PartidaRegistrada partida = PartidaRegistrada.fromJson(item);
            if (partida.deletadaLocalmente) {
              excluidas.add(partida);
            } else {
              importadas.add(partida);
            }
          } catch (_) {}
        }
      }
      historico = importadas;
      partidasExcluidasParaSync = excluidas;
    }

    if (partidasExcluidasRaw is List) {
      final List<PartidaRegistrada> excluidas = [];
      for (final item in partidasExcluidasRaw) {
        if (item is Map<String, dynamic>) {
          try {
            final PartidaRegistrada partida = PartidaRegistrada.fromJson(item);
            excluidas.add(partida);
          } catch (_) {}
        }
      }
      partidasExcluidasParaSync.addAll(excluidas);
    }

    if (personagemAtualRaw is String &&
        personagens.containsKey(personagemAtualRaw)) {
      personagemAtualNome = personagemAtualRaw;
    }

    if (timePrincipalRaw is Map<String, dynamic>) {
      try {
        timePrincipalInvincible = TimePrincipalInvincible.fromJson(
          timePrincipalRaw,
        );
      } catch (_) {}
    } else if (timePrincipalRaw is Map) {
      try {
        timePrincipalInvincible = TimePrincipalInvincible.fromJson(
          Map<String, dynamic>.from(timePrincipalRaw),
        );
      } catch (_) {}
    }

    if (time2XKORaw is Map<String, dynamic>) {
      try {
        timePrincipal2XKO = TimePrincipal2XKO.fromJson(time2XKORaw);
      } catch (_) {}
    } else if (time2XKORaw is Map) {
      try {
        timePrincipal2XKO = TimePrincipal2XKO.fromJson(
          Map<String, dynamic>.from(time2XKORaw),
        );
      } catch (_) {}
    }

    if (timeKofRaw is Map<String, dynamic>) {
      try {
        timePrincipalKofXV = TimePrincipalKofXV.fromJson(timeKofRaw);
      } catch (_) {}
    } else if (timeKofRaw is Map) {
      try {
        timePrincipalKofXV = TimePrincipalKofXV.fromJson(
          Map<String, dynamic>.from(timeKofRaw),
        );
      } catch (_) {}
    }

    if (perfilRaw is Map<String, dynamic>) {
      try {
        perfil = PlayerProfile.fromJson(perfilRaw);
      } catch (_) {}
    }

    smashCoverPreferences = normalizarPreferenciasCapaSmash(
      smashCoverPreferencesRaw,
    );
    currentUserId = currentUserIdRaw?.toString();

    syncRecords = [];
    if (syncRecordsRaw is List) {
      for (final item in syncRecordsRaw) {
        if (item is Map<String, dynamic>) {
          try {
            syncRecords.add(LocalSyncRecord.fromJson(item));
          } catch (_) {}
        } else if (item is Map) {
          try {
            syncRecords.add(
              LocalSyncRecord.fromJson(Map<String, dynamic>.from(item)),
            );
          } catch (_) {}
        }
      }
    }

    syncQueue = [];
    if (syncQueueRaw is List) {
      for (final item in syncQueueRaw) {
        if (item is Map<String, dynamic>) {
          try {
            syncQueue.add(SyncQueueItem.fromJson(item));
          } catch (_) {}
        } else if (item is Map) {
          try {
            syncQueue.add(
              SyncQueueItem.fromJson(Map<String, dynamic>.from(item)),
            );
          } catch (_) {}
        }
      }
    }
  }

  Future<void> carregarDados() async {
    deviceId = await DeviceService.obterOuCriarDeviceId();
    currentUserId = await AuthService.resolveCurrentUserId();
    bool carregouArquivo = false;
    final Map<String, dynamic>? dadosArquivo = await _lerDadosArquivo();
    if (dadosArquivo != null) {
      _aplicarDadosMap(dadosArquivo);
      carregouArquivo = true;
    }

    if (!carregouArquivo) {
      final prefs = await SharedPreferences.getInstance();

      final String? personagensSalvos = prefs.getString('personagens');
      final String? historicoSalvo = prefs.getString('historico');
      final String? personagemAtualSalvo = prefs.getString(
        'personagemAtualNome',
      );
      final String? perfilSalvo = prefs.getString('perfilJogador');
      final String? timePrincipalSalvo = prefs.getString(
        'timePrincipalInvincible',
      );
      final String? time2XKOSalvo = prefs.getString('timePrincipal2XKO');
      final String? timeKofSalvo = prefs.getString('timePrincipalKofXV');
      final String? preferenciasCapaSmashSalvas = prefs.getString(
        prefsKeySmashCoverPreferences,
      );

      if (personagensSalvos != null) {
        try {
          final dynamic decoded = jsonDecode(personagensSalvos);
          if (decoded is List) {
            final Map<String, Character> importados = {};
            for (final item in decoded) {
              if (item is Map<String, dynamic>) {
                try {
                  final Character personagem = Character.fromJson(item);
                  importados[personagem.name] = personagem;
                } catch (_) {}
              }
            }

            personagens.addAll(importados);
          }
        } catch (_) {}

        for (final personagemBase in rosterDoJogo(widget.jogoAtual)) {
          personagens.putIfAbsent(personagemBase.name, () => personagemBase);
        }
      }

      if (historicoSalvo != null) {
        try {
          final dynamic decoded = jsonDecode(historicoSalvo);
          if (decoded is List) {
            historico = decoded
                .whereType<Map<String, dynamic>>()
                .map((item) => PartidaRegistrada.fromJson(item))
                .toList();
          }
        } catch (_) {
          historico = [];
        }
      }

      if (personagemAtualSalvo != null &&
          personagens.containsKey(personagemAtualSalvo)) {
        personagemAtualNome = personagemAtualSalvo;
      }

      if (timePrincipalSalvo != null) {
        try {
          final dynamic decoded = jsonDecode(timePrincipalSalvo);
          if (decoded is Map<String, dynamic>) {
            timePrincipalInvincible = TimePrincipalInvincible.fromJson(decoded);
          } else if (decoded is Map) {
            timePrincipalInvincible = TimePrincipalInvincible.fromJson(
              Map<String, dynamic>.from(decoded),
            );
          }
        } catch (_) {}
      }

      if (time2XKOSalvo != null) {
        try {
          final dynamic decoded = jsonDecode(time2XKOSalvo);
          if (decoded is Map<String, dynamic>) {
            timePrincipal2XKO = TimePrincipal2XKO.fromJson(decoded);
          } else if (decoded is Map) {
            timePrincipal2XKO = TimePrincipal2XKO.fromJson(
              Map<String, dynamic>.from(decoded),
            );
          }
        } catch (_) {}
      }

      if (timeKofSalvo != null) {
        try {
          final dynamic decoded = jsonDecode(timeKofSalvo);
          if (decoded is Map<String, dynamic>) {
            timePrincipalKofXV = TimePrincipalKofXV.fromJson(decoded);
          } else if (decoded is Map) {
            timePrincipalKofXV = TimePrincipalKofXV.fromJson(
              Map<String, dynamic>.from(decoded),
            );
          }
        } catch (_) {}
      }

      if (perfilSalvo != null) {
        try {
          final dynamic decoded = jsonDecode(perfilSalvo);
          if (decoded is Map<String, dynamic>) {
            perfil = PlayerProfile.fromJson(decoded);
          }
        } catch (_) {}
      }

      if (preferenciasCapaSmashSalvas != null) {
        try {
          smashCoverPreferences = normalizarPreferenciasCapaSmash(
            jsonDecode(preferenciasCapaSmashSalvas),
          );
        } catch (_) {}
      }
    }

    if (smashCoverPreferences.isEmpty) {
      smashCoverPreferences = await carregarPreferenciasCapaSmashPrefs();
    }

    currentUserId = AuthService.currentUserId ?? currentUserId;

    if (widget.personagemInicialNome != null &&
        personagens.containsKey(widget.personagemInicialNome)) {
      personagemAtualNome = widget.personagemInicialNome!;
    }

    final bool recebeuTimeInicial = widget.timePrincipalInicial != null;
    final bool recebeuTime2XKOInicial = widget.time2XKOInicial != null;
    final bool recebeuTimeKofInicial = widget.timeKofInicial != null;
    if (widget.timePrincipalInicial != null) {
      timePrincipalInvincible = widget.timePrincipalInicial!;
      if (timePrincipalInvincible.slot1.isNotEmpty &&
          personagens.containsKey(timePrincipalInvincible.slot1)) {
        personagemAtualNome = timePrincipalInvincible.slot1;
      }
    }

    if (widget.time2XKOInicial != null) {
      timePrincipal2XKO = widget.time2XKOInicial!;
      garantirDupla2XKONosPersonagens();
      if (timePrincipal2XKO.completo) {
        personagemAtualNome = timePrincipal2XKO.key;
      }
    } else if (widget.jogoAtual == jogo2Xko && timePrincipal2XKO.completo) {
      garantirDupla2XKONosPersonagens();
      personagemAtualNome = timePrincipal2XKO.key;
    }

    if (widget.timeKofInicial != null) {
      timePrincipalKofXV = widget.timeKofInicial!;
      garantirTimeKofNosPersonagens();
      if (timePrincipalKofXV.completo) {
        personagemAtualNome = timePrincipalKofXV.key;
      }
    } else if (widget.jogoAtual == jogoKofXV && timePrincipalKofXV.completo) {
      garantirTimeKofNosPersonagens();
      personagemAtualNome = timePrincipalKofXV.key;
    }

    recalcularPersonagensPeloHistorico();
    final bool normalizouOfflineFirst = prepararBaseOfflineFirstLocal();

    setState(() {
      carregando = false;
    });

    if (normalizouOfflineFirst ||
        recebeuTimeInicial ||
        recebeuTime2XKOInicial ||
        recebeuTimeKofInicial) {
      await salvarDados();
    }

    await carregarPreferenciaSyncAutomatico();
    agendarSyncAutomatico(
      motivo: 'app_open',
      force: true,
      delay: const Duration(seconds: 2),
    );
  }

  Future<void> salvarDados({bool marcarSyncPendente = true}) async {
    if (deviceId.trim().isEmpty) {
      deviceId = await DeviceService.obterOuCriarDeviceId();
    }

    if (marcarSyncPendente) {
      marcarSnapshotsLocaisPendentes();
    }
    final prefs = await SharedPreferences.getInstance();

    await _salvarDadosArquivo(gerarDadosPersistidos());

    await prefs.setString('personagemAtualNome', personagemAtualNome);
    await prefs.setString(
      'timePrincipalInvincible',
      jsonEncode(timePrincipalInvincible.toJson()),
    );
    await prefs.setString(
      'timePrincipal2XKO',
      jsonEncode(timePrincipal2XKO.toJson()),
    );
    await prefs.setString(
      'timePrincipalKofXV',
      jsonEncode(timePrincipalKofXV.toJson()),
    );
    await prefs.setString('perfilJogador', jsonEncode(perfil.toJson()));
    if ((currentUserId ?? '').trim().isNotEmpty) {
      await prefs.setString(
        AuthService.prefsKeyCurrentUserId,
        currentUserId!.trim(),
      );
    }
    await prefs.setString(
      prefsKeySmashCoverPreferences,
      jsonEncode(smashCoverPreferences),
    );
    await prefs.remove('personagens');
    await prefs.remove('historico');

    if (marcarSyncPendente) {
      agendarSyncAutomatico(motivo: 'local_save');
    }
  }

  bool prepararBaseOfflineFirstLocal() {
    if (deviceId.trim().isEmpty) return false;

    bool alterou = false;
    final DateTime now = DateTime.now();

    List<PartidaRegistrada> normalizarPartidas(
      List<PartidaRegistrada> partidas,
    ) {
      return partidas.map((partida) {
        final PartidaRegistrada normalizada =
            LocalSyncRepository.garantirMetadadosPartida(
              partida: partida,
              deviceId: deviceId,
              now: now,
            );

        if (normalizada.id != partida.id ||
            normalizada.deviceId != partida.deviceId ||
            normalizada.syncStatus != partida.syncStatus) {
          alterou = true;
        }

        return normalizada;
      }).toList();
    }

    historico = normalizarPartidas(historico);
    partidasExcluidasParaSync = normalizarPartidas(partidasExcluidasParaSync);
    marcarSnapshotsLocaisPendentes(now: now);

    for (final PartidaRegistrada partida in historico) {
      if (partida.syncStatus == SyncStatus.pendingSync ||
          partida.syncStatus == SyncStatus.localOnly) {
        final int tamanhoAntes = syncQueue.length;
        syncQueue = LocalSyncRepository.upsertQueueItem(
          queue: syncQueue,
          entityType: SyncEntityType.match,
          entityId: partida.id,
          operation: SyncOperation.create,
          now: now,
        );
        alterou = alterou || syncQueue.length != tamanhoAntes;
      }
    }

    for (final PartidaRegistrada partida in partidasExcluidasParaSync) {
      final int tamanhoAntes = syncQueue.length;
      syncQueue = LocalSyncRepository.upsertQueueItem(
        queue: syncQueue,
        entityType: SyncEntityType.match,
        entityId: partida.id,
        operation: SyncOperation.delete,
        now: now,
      );
      alterou = alterou || syncQueue.length != tamanhoAntes;
    }

    return alterou;
  }

  void marcarSnapshotsLocaisPendentes({DateTime? now}) {
    if (deviceId.trim().isEmpty) return;

    final DateTime resolvedNow = now ?? DateTime.now();

    void marcar(SyncEntityType type, String entityId) {
      syncRecords = LocalSyncRepository.upsertRecord(
        records: syncRecords,
        entityType: type,
        entityId: entityId,
        deviceId: deviceId,
        userId: currentUserId,
        now: resolvedNow,
      );
      syncQueue = LocalSyncRepository.queueRecordUpdate(
        queue: syncQueue,
        entityType: type,
        entityId: entityId,
        now: resolvedNow,
      );
    }

    marcar(
      SyncEntityType.gameProfile,
      'profile:${perfil.email}:${perfil.nick}',
    );
    marcar(SyncEntityType.characterProgress, 'characters:${widget.jogoAtual}');
    marcar(SyncEntityType.preference, prefsKeySmashCoverPreferences);
    marcar(SyncEntityType.favorite, 'favorites');
    marcar(SyncEntityType.selectedCharacter, 'selected:${widget.jogoAtual}');

    if (widget.jogoAtual == jogoInvincibleVs) {
      marcar(SyncEntityType.selectedTeam, 'team:$jogoInvincibleVs');
    } else if (widget.jogoAtual == jogo2Xko) {
      marcar(SyncEntityType.selectedTeam, 'team:$jogo2Xko');
    } else if (widget.jogoAtual == jogoKofXV) {
      marcar(SyncEntityType.selectedTeam, 'team:$jogoKofXV');
    }
  }

  PartidaRegistrada prepararPartidaParaSalvarLocal(
    PartidaRegistrada partida, {
    required SyncOperation operation,
  }) {
    final SyncOperation operacaoFinal =
        partida.id.trim().isEmpty && operation == SyncOperation.update
        ? SyncOperation.create
        : operation;
    final PartidaRegistrada preparada =
        LocalSyncRepository.prepararPartidaParaSalvar(
          partida: partida,
          deviceId: deviceId,
          userId: currentUserId,
          operation: operacaoFinal,
        );

    syncQueue = LocalSyncRepository.upsertQueueItem(
      queue: syncQueue,
      entityType: SyncEntityType.match,
      entityId: preparada.id,
      operation: operacaoFinal,
    );

    return preparada;
  }

  void registrarPartidaExcluidaParaSync(PartidaRegistrada partida) {
    final PartidaRegistrada tombstone =
        LocalSyncRepository.prepararPartidaExcluida(
          partida: partida,
          deviceId: deviceId,
          userId: currentUserId,
        );

    partidasExcluidasParaSync.removeWhere(
      (partida) => partida.id == tombstone.id,
    );
    partidasExcluidasParaSync.add(tombstone);

    syncQueue = LocalSyncRepository.upsertQueueItem(
      queue: syncQueue,
      entityType: SyncEntityType.match,
      entityId: tombstone.id,
      operation: SyncOperation.delete,
    );
  }

  String get pastaBackupPath {
    final String? userProfile = Platform.environment['USERPROFILE'];

    if (userProfile != null && userProfile.trim().isNotEmpty) {
      return '$userProfile${Platform.pathSeparator}Documents${Platform.pathSeparator}LabTracker_Backups';
    }

    return '${Directory.current.path}${Platform.pathSeparator}LabTracker_Backups';
  }

  Map<String, dynamic> gerarDadosBackup() {
    return {
      'app': 'LabTracker',
      'versaoBackup': 2,
      'criadoEm': DateTime.now().toIso8601String(),
      'offlineFirstVersion': 1,
      'deviceId': deviceId,
      'currentUserId': currentUserId,
      'perfilJogador': perfil.toJson(),
      'jogoAtual': widget.jogoAtual,
      'personagemAtualNome': personagemAtualNome,
      'timePrincipalInvincible': timePrincipalInvincible.toJson(),
      'timePrincipal2XKO': timePrincipal2XKO.toJson(),
      'timePrincipalKofXV': timePrincipalKofXV.toJson(),
      prefsKeySmashCoverPreferences: smashCoverPreferences,
      'personagens': personagens.values
          .map((personagem) => personagem.toJson())
          .toList(),
      'historico': historico.map((partida) => partida.toJson()).toList(),
      'partidasExcluidasParaSync': partidasExcluidasParaSync
          .map((partida) => partida.toJson())
          .toList(),
      'syncRecords': syncRecords.map((record) => record.toJson()).toList(),
      'syncQueue': syncQueue.map((item) => item.toJson()).toList(),
    };
  }

  Future<String> exportarBackup() async {
    final Directory pastaBackup = Directory(pastaBackupPath);

    if (!await pastaBackup.exists()) {
      await pastaBackup.create(recursive: true);
    }

    final DateTime agora = DateTime.now();
    String doisDigitos(int numero) => numero.toString().padLeft(2, '0');

    final String nomeArquivo =
        'labtracker_backup_'
        '${agora.year}${doisDigitos(agora.month)}${doisDigitos(agora.day)}_'
        '${doisDigitos(agora.hour)}${doisDigitos(agora.minute)}${doisDigitos(agora.second)}.json';

    final String caminhoArquivo =
        '${pastaBackup.path}${Platform.pathSeparator}$nomeArquivo';

    final File arquivoBackup = File(caminhoArquivo);
    const JsonEncoder encoder = JsonEncoder.withIndent('  ');

    await arquivoBackup.writeAsString(
      encoder.convert(gerarDadosBackup()),
      flush: true,
    );

    return arquivoBackup.path;
  }

  Future<String> importarBackupMaisRecente() async {
    final Directory pastaBackup = Directory(pastaBackupPath);

    if (!await pastaBackup.exists()) {
      throw Exception(
        'A pasta de backup ainda não existe. Exporte um backup primeiro.',
      );
    }

    final List<File> arquivos = pastaBackup
        .listSync()
        .whereType<File>()
        .where((arquivo) => arquivo.path.toLowerCase().endsWith('.json'))
        .toList();

    if (arquivos.isEmpty) {
      throw Exception(
        'Nenhum arquivo .json de backup foi encontrado na pasta.',
      );
    }

    arquivos.sort((a, b) {
      return b.lastModifiedSync().compareTo(a.lastModifiedSync());
    });

    final File arquivoMaisRecente = arquivos.first;
    final String conteudo = await arquivoMaisRecente.readAsString();
    final Map<String, dynamic> dados = jsonDecode(conteudo);

    if (dados['app'] != 'LabTracker') {
      throw Exception(
        'Esse arquivo não parece ser um backup válido do LabTracker.',
      );
    }

    setState(() {
      _aplicarDadosMap(dados);

      if (!personagens.containsKey(personagemAtualNome)) {
        personagemAtualNome = personagemPadraoDoJogo;
      }

      recalcularPersonagensPeloHistorico();
    });

    await salvarDados();

    return arquivoMaisRecente.path;
  }

  Character characterDaDupla2XKO(TimePrincipal2XKO dupla, {int pdl = 0}) {
    final String key = dupla.key;
    return Character(
      name: key,
      initial: '2X',
      rank: calcularRankDoJogo(jogo2Xko, pdl),
      pdl: pdl,
    );
  }

  Character characterDoTimeKof(TimePrincipalKofXV time, {int pdl = 0}) {
    final String key = time.key;
    return Character(
      name: key,
      initial: 'KOF',
      rank: calcularRankDoJogo(jogoKofXV, pdl),
      pdl: pdl,
    );
  }

  void garantirDupla2XKONosPersonagens() {
    if (widget.jogoAtual != jogo2Xko || !timePrincipal2XKO.completo) return;

    personagens.putIfAbsent(
      timePrincipal2XKO.key,
      () => characterDaDupla2XKO(timePrincipal2XKO),
    );
  }

  void garantirTimeKofNosPersonagens() {
    if (widget.jogoAtual != jogoKofXV || !timePrincipalKofXV.completo) return;

    personagens.putIfAbsent(
      timePrincipalKofXV.key,
      () => characterDoTimeKof(timePrincipalKofXV),
    );
  }

  void recalcularPersonagensPeloHistorico() {
    final Map<String, Character> novosPersonagens = {
      for (final personagem in rosterDoJogo(widget.jogoAtual))
        personagem.name: personagem,
    };

    if (widget.jogoAtual == jogo2Xko && timePrincipal2XKO.completo) {
      novosPersonagens[timePrincipal2XKO.key] = characterDaDupla2XKO(
        timePrincipal2XKO,
      );
    }

    if (widget.jogoAtual == jogoKofXV && timePrincipalKofXV.completo) {
      novosPersonagens[timePrincipalKofXV.key] = characterDoTimeKof(
        timePrincipalKofXV,
      );
    }

    final List<PartidaRegistrada> partidasEmOrdemCronologica = historico
        .where((partida) => partidaPertenceAoJogo(partida, widget.jogoAtual))
        .toList()
        .reversed
        .toList();

    void aplicarPontos(String nomePersonagem, int pontos) {
      if (nomePersonagem.trim().isEmpty) return;

      final Character personagem =
          novosPersonagens[nomePersonagem] ??
          Character(
            name: nomePersonagem,
            initial: nomePersonagem.isNotEmpty
                ? nomePersonagem[0].toUpperCase()
                : '?',
            rank: rankInicialDoJogo(widget.jogoAtual),
            pdl: 0,
          );

      final int novoPdl = personagem.pdl + pontos;
      final int pdlCorrigido = novoPdl < 0 ? 0 : novoPdl;

      novosPersonagens[personagem.name] = personagem.copyWith(
        pdl: pdlCorrigido,
        rank: calcularRankDoJogo(widget.jogoAtual, pdlCorrigido),
      );
    }

    for (final partida in partidasEmOrdemCronologica) {
      if (widget.jogoAtual == jogoInvincibleVs && partida.isInvincible) {
        for (final personagem in partida.meuTime) {
          aplicarPontos(personagem, partida.pdlGerado);
        }
      } else if (widget.jogoAtual == jogo2Xko && partida.is2XKO) {
        final String teamKey = partida.personagemJogador.trim().isNotEmpty
            ? partida.personagemJogador
            : chaveDupla2XKO(partida.meuTimeSlot1, partida.meuTimeSlot2);
        aplicarPontos(teamKey, partida.pdlGerado);
      } else if (widget.jogoAtual == jogoKofXV && partida.isKofXV) {
        final String teamKey = partida.personagemJogador.trim().isNotEmpty
            ? partida.personagemJogador
            : chaveTimeKofXV(
                partida.meuTimeSlot1,
                partida.meuTimeSlot2,
                partida.meuTimeSlot3,
              );
        aplicarPontos(teamKey, partida.pdlGerado);
      } else {
        aplicarPontos(partida.personagemJogador, partida.pdlGerado);
      }
    }

    personagens = novosPersonagens;

    if (!personagens.containsKey(personagemAtualNome)) {
      if (widget.jogoAtual == jogo2Xko && timePrincipal2XKO.completo) {
        personagemAtualNome = timePrincipal2XKO.key;
      } else if (widget.jogoAtual == jogoKofXV && timePrincipalKofXV.completo) {
        personagemAtualNome = timePrincipalKofXV.key;
      } else {
        personagemAtualNome = personagemPadraoDoJogo;
      }
    }
  }

  Future<void> resetarDados() async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Resetar dados?'),
          content: const Text(
            'Isso vai apagar o PDL, ranks e histórico salvos no LabTracker.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Resetar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    await _removerDadosArquivo();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('personagens');
    await prefs.remove('historico');
    await prefs.remove('personagemAtualNome');
    await prefs.remove('timePrincipalInvincible');
    await prefs.remove('timePrincipal2XKO');
    await prefs.remove('timePrincipalKofXV');
    await prefs.remove('perfilJogador');
    await prefs.remove(prefsKeySmashCoverPreferences);

    setState(() {
      personagens = {
        for (final personagem in rosterDoJogo(widget.jogoAtual))
          personagem.name: personagem,
      };
      historico = [];
      personagemAtualNome = personagemPadraoDoJogo;
      timePrincipalInvincible = timePrincipalInvincibleVazio;
      timePrincipal2XKO = timePrincipal2XKOVazio;
      timePrincipalKofXV = timePrincipalKofVazio;
      smashCoverPreferences = {};
      perfil = perfilPadrao;
      partidasExcluidasParaSync = [];
      syncRecords = [];
      syncQueue = [];
    });
  }

  Future<void> atualizarPreferenciaCapaSmash(
    String personagem,
    String preferencia,
  ) async {
    if (!jogoEhSmash(widget.jogoAtual)) return;

    final String nome = normalizarPersonagemCapaSmash(personagem);
    if (!personagemTemPreferenciaCapaSmash(nome)) return;

    final Map<String, String> novasPreferencias = {...smashCoverPreferences};

    if (opcaoCapaSmashPorId(nome, preferencia) == null) {
      novasPreferencias.remove(nome);
    } else {
      novasPreferencias[nome] = preferencia;
    }

    setState(() {
      smashCoverPreferences = novasPreferencias;
    });

    await salvarDados();
  }

  Future<void> abrirSelecaoDePersonagem() async {
    if (widget.jogoAtual == jogoKofXV) {
      await abrirMontarTimeKofXV();
      return;
    }

    if (widget.jogoAtual == jogo2Xko) {
      await abrirMontarTime2XKO();
      return;
    }

    final Character? personagemEscolhido = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelecionarPersonagemPage(
          titulo: 'Escolher seu personagem',
          personagens: personagens.values.toList(),
          jogoAtual: widget.jogoAtual,
          smashCoverPreferences: smashCoverPreferences,
          usarPreferenciaVisualSmash: jogoEhSmash(widget.jogoAtual),
        ),
      ),
    );

    if (personagemEscolhido != null) {
      setState(() {
        personagemAtualNome = personagemEscolhido.name;
      });

      await marcarPersonagemRecente(widget.jogoAtual, personagemEscolhido.name);
      await marcarJogoRecente(widget.jogoAtual);
      await salvarDados();
    }
  }

  Future<bool> abrirMontarTimePrincipal() async {
    final TimePrincipalInvincible? time =
        await Navigator.push<TimePrincipalInvincible>(
          context,
          MaterialPageRoute<TimePrincipalInvincible>(
            builder: (context) =>
                MontarTimeInvinciblePage(timeInicial: timePrincipalInvincible),
          ),
        );

    if (time == null) return false;

    setState(() {
      timePrincipalInvincible = time;
      if (time.slot1.isNotEmpty && personagens.containsKey(time.slot1)) {
        personagemAtualNome = time.slot1;
      }
    });

    await marcarJogoRecente(widget.jogoAtual);
    for (final personagem in time.personagens) {
      await marcarPersonagemRecente(widget.jogoAtual, personagem);
    }

    await salvarDados();
    return true;
  }

  Future<bool> abrirMontarTimeKofXV() async {
    final TimePrincipalKofXV? time = await Navigator.push<TimePrincipalKofXV>(
      context,
      MaterialPageRoute<TimePrincipalKofXV>(
        builder: (context) =>
            MontarTimeKofXVPage(timeInicial: timePrincipalKofXV),
      ),
    );

    if (time == null) return false;

    setState(() {
      timePrincipalKofXV = time;
      garantirTimeKofNosPersonagens();
      if (timePrincipalKofXV.completo) {
        personagemAtualNome = timePrincipalKofXV.key;
      }
    });

    await marcarJogoRecente(widget.jogoAtual);
    for (final personagem in time.personagens) {
      await marcarPersonagemRecente(widget.jogoAtual, personagem);
    }

    await salvarDados();
    return true;
  }

  Future<bool> abrirMontarTime2XKO() async {
    final TimePrincipal2XKO? dupla = await Navigator.push<TimePrincipal2XKO>(
      context,
      MaterialPageRoute<TimePrincipal2XKO>(
        builder: (context) =>
            MontarTime2XKOPage(timeInicial: timePrincipal2XKO),
      ),
    );

    if (dupla == null) return false;

    setState(() {
      timePrincipal2XKO = dupla;
      garantirDupla2XKONosPersonagens();
      personagemAtualNome = dupla.key;
      recalcularPersonagensPeloHistorico();
    });

    await marcarJogoRecente(widget.jogoAtual);
    for (final personagem in dupla.personagens) {
      await marcarPersonagemRecente(widget.jogoAtual, personagem);
    }

    await salvarDados();
    return true;
  }

  List<String> sugestoesFrequentes(Iterable<String> itens) {
    return gerarRankingFrequencia(
      itens.toList(),
    ).map((item) => item.nome).take(8).toList();
  }

  Future<void> abrirRegistrarPartida({
    PartidaRegistrada? partidaInicial,
    bool repetirUltima = false,
  }) async {
    if (widget.jogoAtual == jogoInvincibleVs &&
        !timePrincipalInvincible.completo) {
      final bool montouTime = await abrirMontarTimePrincipal();
      if (!montouTime || !timePrincipalInvincible.completo) return;
    }

    if (widget.jogoAtual == jogo2Xko && !timePrincipal2XKO.completo) {
      final bool montouDupla = await abrirMontarTime2XKO();
      if (!montouDupla || !timePrincipal2XKO.completo) return;
    }

    if (widget.jogoAtual == jogoKofXV && !timePrincipalKofXV.completo) {
      final bool montouTime = await abrirMontarTimeKofXV();
      if (!montouTime || !timePrincipalKofXV.completo) return;
    }

    if (!mounted) return;

    final List<PartidaRegistrada> partidasDoContexto = historicoDoContextoAtual;

    final PartidaRegistrada? partida = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          if (widget.jogoAtual == jogoInvincibleVs) {
            return RegistrarPartidaInvinciblePage(
              jogo: widget.jogoAtual,
              sugestoesPlayers: gerarSugestoesPlayers(partidasDoContexto),
              timePrincipal: timePrincipalInvincible,
              partidaInicial: partidaInicial,
              repetirUltima: repetirUltima,
            );
          }

          if (widget.jogoAtual == jogo2Xko) {
            return RegistrarPartida2XKOPage(
              jogo: widget.jogoAtual,
              sugestoesPlayers: gerarSugestoesPlayers(partidasDoContexto),
              timePrincipal: timePrincipal2XKO,
              partidaInicial: partidaInicial,
              repetirUltima: repetirUltima,
            );
          }

          if (widget.jogoAtual == jogoKofXV) {
            return RegistrarPartidaKofXVPage(
              jogo: widget.jogoAtual,
              sugestoesPlayers: gerarSugestoesPlayers(partidasDoContexto),
              timePrincipal: timePrincipalKofXV,
              partidaInicial: partidaInicial,
              repetirUltima: repetirUltima,
            );
          }

          if (widget.jogoAtual == jogoTekken8) {
            return RegistrarPartidaTekken8Page(
              personagemAtual: personagemAtual,
              jogo: widget.jogoAtual,
              sugestoesPlayers: gerarSugestoesPlayers(partidasDoContexto),
              sugestoesStages: sugestoesFrequentes(
                partidasDoContexto.map((partida) => partida.stage),
              ),
              partidaInicial: partidaInicial,
              repetirUltima: repetirUltima,
            );
          }

          if (widget.jogoAtual == jogoFatalFury) {
            return RegistrarPartidaFatalFuryPage(
              personagemAtual: personagemAtual,
              jogo: widget.jogoAtual,
              sugestoesPlayers: gerarSugestoesPlayers(partidasDoContexto),
              sugestoesStages: sugestoesFrequentes(
                partidasDoContexto.map((partida) => partida.stage),
              ),
              partidaInicial: partidaInicial,
              repetirUltima: repetirUltima,
            );
          }

          if (widget.jogoAtual == jogoStreetFighter6) {
            return RegistrarPartidaStreetFighterPage(
              personagemAtual: personagemAtual,
              jogo: widget.jogoAtual,
              sugestoesPlayers: gerarSugestoesPlayers(partidasDoContexto),
              partidaInicial: partidaInicial,
              repetirUltima: repetirUltima,
            );
          }

          if (widget.jogoAtual == jogoMortalKombat1) {
            return RegistrarPartidaMortalKombat1Page(
              personagemAtual: personagemAtual,
              jogo: widget.jogoAtual,
              sugestoesPlayers: gerarSugestoesPlayers(partidasDoContexto),
              sugestoesStages: sugestoesFrequentes(
                partidasDoContexto.map((partida) => partida.stage),
              ),
              partidaInicial: partidaInicial,
              repetirUltima: repetirUltima,
            );
          }

          if (widget.jogoAtual == jogoGuiltyGearStrive) {
            return RegistrarPartidaGuiltyGearPage(
              personagemAtual: personagemAtual,
              jogo: widget.jogoAtual,
              sugestoesPlayers: gerarSugestoesPlayers(partidasDoContexto),
              partidaInicial: partidaInicial,
              repetirUltima: repetirUltima,
            );
          }

          if (widget.jogoAtual == jogoRivalsOfAether2) {
            return RegistrarPartidaRivalsPage(
              personagemAtual: personagemAtual,
              jogo: widget.jogoAtual,
              sugestoesPlayers: gerarSugestoesPlayers(partidasDoContexto),
              sugestoesStages: sugestoesFrequentes(
                partidasDoContexto.map((partida) => partida.stage),
              ),
              partidaInicial: partidaInicial,
              repetirUltima: repetirUltima,
            );
          }

          return RegistrarPartidaPage(
            personagemAtual: personagemAtual,
            jogo: widget.jogoAtual,
            sugestoesPlayers: gerarSugestoesPlayers(partidasDoContexto),
            sugestoesStages: sugestoesFrequentes(
              partidasDoContexto.map((partida) => partida.stage),
            ),
            sugestoesKills: sugestoesFrequentes(
              partidasDoContexto.map((partida) => partida.formaDeKill),
            ),
            sugestoesMortes: sugestoesFrequentes(
              partidasDoContexto.map((partida) => partida.formaDeMorte),
            ),
            partidaInicial: partidaInicial,
          );
        },
      ),
    );

    if (partida != null) {
      final PartidaRegistrada partidaLocal = prepararPartidaParaSalvarLocal(
        partida,
        operation: SyncOperation.create,
      );

      setState(() {
        historico.insert(0, partidaLocal);
        recalcularPersonagensPeloHistorico();
      });

      await marcarJogoRecente(widget.jogoAtual);
      if (widget.jogoAtual == jogoInvincibleVs) {
        for (final personagem in partidaLocal.meuTime) {
          await marcarPersonagemRecente(widget.jogoAtual, personagem);
        }
      } else if (widget.jogoAtual == jogo2Xko) {
        for (final personagem in partidaLocal.meuTime) {
          await marcarPersonagemRecente(widget.jogoAtual, personagem);
        }
      } else if (widget.jogoAtual == jogoKofXV) {
        for (final personagem in partidaLocal.meuTime) {
          await marcarPersonagemRecente(widget.jogoAtual, personagem);
        }
      } else {
        await marcarPersonagemRecente(
          widget.jogoAtual,
          partidaLocal.personagemJogador,
        );
      }
      await salvarDados();
    }
  }

  Future<void> abrirRepetirUltimaPartida() async {
    final PartidaRegistrada? ultimaPartida = ultimaPartidaDoContextoAtual;
    if (ultimaPartida == null) return;

    await abrirRegistrarPartida(
      partidaInicial: ultimaPartida,
      repetirUltima: true,
    );
  }

  Future<void> abrirHistorico() async {
    final bool? houveAlteracao = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HistoricoPage(
          historico: historico,
          personagemAtual: personagemReferenciaAtual(),
          jogo: widget.jogoAtual,
          timePrincipalInvincible: timePrincipalInvincible,
          timePrincipal2XKO: timePrincipal2XKO,
          timePrincipalKofXV: timePrincipalKofXV,
          smashCoverPreferences: smashCoverPreferences,
          onHistoricoAlterado: (alteracao) async {
            if (!mounted) return;
            setState(() {
              if (alteracao.operation == SyncOperation.delete) {
                registrarPartidaExcluidaParaSync(alteracao.original);
              } else if (alteracao.operation == SyncOperation.update &&
                  alteracao.atualizada != null) {
                final int index = historico.indexOf(alteracao.atualizada!);
                if (index != -1) {
                  historico[index] = prepararPartidaParaSalvarLocal(
                    alteracao.atualizada!,
                    operation: SyncOperation.update,
                  );
                }
              }
              recalcularPersonagensPeloHistorico();
            });
            await salvarDados();
          },
        ),
      ),
    );

    if (houveAlteracao == true) {
      setState(() {
        recalcularPersonagensPeloHistorico();
      });

      await salvarDados();
    }
  }

  void abrirEstatisticas() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          if (widget.jogoAtual == jogoInvincibleVs) {
            return EstatisticasInvinciblePage(
              historico: historico,
              jogoAtual: widget.jogoAtual,
              timePrincipalInvincible: timePrincipalInvincible,
            );
          }

          if (widget.jogoAtual == jogo2Xko) {
            return Estatisticas2XKOPage(
              historico: historico,
              jogoAtual: widget.jogoAtual,
              timePrincipal2XKO: timePrincipal2XKO,
            );
          }

          if (widget.jogoAtual == jogoKofXV) {
            return EstatisticasKofXVPage(
              historico: historico,
              jogoAtual: widget.jogoAtual,
              timePrincipalKofXV: timePrincipalKofXV,
            );
          }

          if (widget.jogoAtual == jogoTekken8) {
            return EstatisticasTekken8Page(
              personagemAtual: personagemAtual,
              historico: historico,
              jogoAtual: widget.jogoAtual,
            );
          }

          if (widget.jogoAtual == jogoFatalFury) {
            return EstatisticasFatalFuryPage(
              personagemAtual: personagemAtual,
              historico: historico,
              jogoAtual: widget.jogoAtual,
            );
          }

          if (widget.jogoAtual == jogoStreetFighter6) {
            return EstatisticasStreetFighterPage(
              personagemAtual: personagemAtual,
              historico: historico,
              jogoAtual: widget.jogoAtual,
            );
          }

          if (widget.jogoAtual == jogoMortalKombat1) {
            return EstatisticasMortalKombat1Page(
              personagemAtual: personagemAtual,
              historico: historico,
              jogoAtual: widget.jogoAtual,
            );
          }

          if (widget.jogoAtual == jogoGuiltyGearStrive) {
            return EstatisticasGuiltyGearPage(
              personagemAtual: personagemAtual,
              historico: historico,
              jogoAtual: widget.jogoAtual,
            );
          }

          if (widget.jogoAtual == jogoRivalsOfAether2) {
            return EstatisticasRivalsPage(
              personagemAtual: personagemAtual,
              historico: historico,
              jogoAtual: widget.jogoAtual,
            );
          }

          return EstatisticasPage(
            personagemAtual: personagemAtual,
            historico: historico,
            jogoAtual: widget.jogoAtual,
            smashCoverPreferences: smashCoverPreferences,
          );
        },
      ),
    );
  }

  DateTime? get ultimaSincronizacaoLocal {
    final List<DateTime> datas = [
      ...historico.map((partida) => partida.lastSyncAt).whereType<DateTime>(),
      ...partidasExcluidasParaSync
          .map((partida) => partida.lastSyncAt)
          .whereType<DateTime>(),
      ...syncRecords.map((record) => record.lastSyncAt).whereType<DateTime>(),
    ];

    if (datas.isEmpty) return null;
    datas.sort((a, b) => b.compareTo(a));
    return datas.first;
  }

  Future<SyncRunResult> executarSincronizacao({
    required bool automatico,
  }) async {
    if (syncEmAndamento) {
      autoSyncPendenteAposAtual = autoSyncPendenteAposAtual || automatico;
      throw Exception('Ja existe uma sincronizacao em andamento.');
    }

    syncEmAndamento = true;
    if (automatico) {
      lastAutoSyncAttemptAt = DateTime.now();
    }

    try {
      if (deviceId.trim().isEmpty) {
        deviceId = await DeviceService.obterOuCriarDeviceId();
      }

      await incorporarSnapshotsExternosPendentes();

      final SyncRunResult result = await SyncService.syncNow(
        deviceId: deviceId,
        currentUserId: currentUserId,
        jogoAtual: widget.jogoAtual,
        perfil: perfil,
        personagemAtualNome: personagemAtualNome,
        timePrincipalInvincible: timePrincipalInvincible,
        timePrincipal2XKO: timePrincipal2XKO,
        timePrincipalKofXV: timePrincipalKofXV,
        personagens: personagens,
        historico: historico,
        partidasExcluidasParaSync: partidasExcluidasParaSync,
        syncQueue: syncQueue,
        syncRecords: syncRecords,
        smashCoverPreferences: smashCoverPreferences,
      );

      if (!mounted) return result;

      setState(() {
        currentUserId = result.userId;
        deviceId = result.deviceId;
        historico = result.historico;
        partidasExcluidasParaSync = result.partidasExcluidasParaSync;
        syncQueue = result.syncQueue;
        syncRecords = result.syncRecords;
        smashCoverPreferences = result.smashCoverPreferences;
        personagemAtualNome = result.personagemAtualNome;
        timePrincipalInvincible = result.timePrincipalInvincible;
        timePrincipal2XKO = result.timePrincipal2XKO;
        timePrincipalKofXV = result.timePrincipalKofXV;
        recalcularPersonagensPeloHistorico();
      });

      await salvarDados(marcarSyncPendente: false);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(prefsKeyPendingExternalSyncSnapshot);
      await carregarPreferenciaSyncAutomatico();

      if (automatico) {
        lastAutoSyncCompletedAt = result.syncedAt;
      }

      return result;
    } finally {
      syncEmAndamento = false;
      if (autoSyncPendenteAposAtual && autoSyncEnabled && mounted) {
        autoSyncPendenteAposAtual = false;
        agendarSyncAutomatico(motivo: 'queued_after_sync');
      }
    }
  }

  Future<SyncRunResult> sincronizarAgora() async {
    return executarSincronizacao(automatico: false);
  }

  Future<void> abrirContaSync() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AccountSyncPage(
          deviceId: deviceId,
          currentUserId: currentUserId,
          lastSyncAt: ultimaSincronizacaoLocal,
          pendingSyncCount: syncQueue
              .where((item) => item.status == SyncQueueStatus.pending)
              .length,
          syncErrorCount: syncQueue
              .where((item) => item.status == SyncQueueStatus.error)
              .length,
          onSyncNow: sincronizarAgora,
          onAutoSyncChanged: (enabled) async {
            if (!mounted) return;
            setState(() {
              autoSyncEnabled = enabled;
            });

            if (!enabled) {
              autoSyncDebounceTimer?.cancel();
              return;
            }

            agendarSyncAutomatico(motivo: 'auto_sync_enabled', force: true);
          },
        ),
      ),
    );

    final String? resolvedUserId = await AuthService.resolveCurrentUserId();
    if (!mounted) return;

    setState(() {
      currentUserId = resolvedUserId;
    });

    await carregarPreferenciaSyncAutomatico();
    await salvarDados(marcarSyncPendente: false);

    if (autoSyncEnabled) {
      agendarSyncAutomatico(motivo: 'account_return', force: true);
    }
  }

  void abrirResumoTreino() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          if (widget.jogoAtual == jogoInvincibleVs) {
            return EstatisticasInvinciblePage(
              historico: historico,
              jogoAtual: widget.jogoAtual,
              timePrincipalInvincible: timePrincipalInvincible,
            );
          }

          if (widget.jogoAtual == jogo2Xko) {
            return Estatisticas2XKOPage(
              historico: historico,
              jogoAtual: widget.jogoAtual,
              timePrincipal2XKO: timePrincipal2XKO,
            );
          }

          if (widget.jogoAtual == jogoKofXV) {
            return EstatisticasKofXVPage(
              historico: historico,
              jogoAtual: widget.jogoAtual,
              timePrincipalKofXV: timePrincipalKofXV,
            );
          }

          if (widget.jogoAtual == jogoTekken8) {
            return EstatisticasTekken8Page(
              personagemAtual: personagemAtual,
              historico: historico,
              jogoAtual: widget.jogoAtual,
            );
          }

          if (widget.jogoAtual == jogoFatalFury) {
            return EstatisticasFatalFuryPage(
              personagemAtual: personagemAtual,
              historico: historico,
              jogoAtual: widget.jogoAtual,
            );
          }

          if (widget.jogoAtual == jogoStreetFighter6) {
            return EstatisticasStreetFighterPage(
              personagemAtual: personagemAtual,
              historico: historico,
              jogoAtual: widget.jogoAtual,
            );
          }

          if (widget.jogoAtual == jogoMortalKombat1) {
            return EstatisticasMortalKombat1Page(
              personagemAtual: personagemAtual,
              historico: historico,
              jogoAtual: widget.jogoAtual,
            );
          }

          if (widget.jogoAtual == jogoGuiltyGearStrive) {
            return EstatisticasGuiltyGearPage(
              personagemAtual: personagemAtual,
              historico: historico,
              jogoAtual: widget.jogoAtual,
            );
          }

          if (widget.jogoAtual == jogoRivalsOfAether2) {
            return EstatisticasRivalsPage(
              personagemAtual: personagemAtual,
              historico: historico,
              jogoAtual: widget.jogoAtual,
            );
          }

          return ResumoTreinoPage(
            personagemAtual: personagemAtual,
            historico: historico,
            jogoAtual: widget.jogoAtual,
            smashCoverPreferences: smashCoverPreferences,
          );
        },
      ),
    );
  }

  Future<void> abrirPerfil() async {
    final PlayerProfile? perfilEditado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PerfilJogadorPage(
          perfil: perfil,
          personagemAtual: personagemReferenciaAtual(),
          jogoAtual: widget.jogoAtual,
          smashCoverPreferences: smashCoverPreferences,
          onSmashCoverPreferenceChanged: atualizarPreferenciaCapaSmash,
        ),
      ),
    );

    smashCoverPreferences = await carregarPreferenciasCapaSmashPrefs();

    if (perfilEditado != null) {
      setState(() {
        perfil = perfilEditado;
      });

      await salvarDados();
    }
  }

  void abrirConfiguracoes() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConfiguracoesPage(
          pastaBackupPath: pastaBackupPath,
          exportarBackup: exportarBackup,
          importarBackupMaisRecente: importarBackupMaisRecente,
          abrirPerfil: abrirPerfil,
        ),
      ),
    );
  }

  void voltarTelaAnterior() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }

    irParaSelecaoDeJogos(context);
  }

  void executarAcaoMenuHome(_HomePageMenuAction acao) {
    switch (acao) {
      case _HomePageMenuAction.conta:
        abrirContaSync();
        break;
      case _HomePageMenuAction.perfil:
        abrirPerfil();
        break;
      case _HomePageMenuAction.configuracoes:
        abrirConfiguracoes();
        break;
      case _HomePageMenuAction.resetar:
        resetarDados();
        break;
    }
  }

  List<Widget> construirAcoesAppBar(bool compacta) {
    if (compacta) {
      return [
        const HomeNavigationButton(),
        PopupMenuButton<_HomePageMenuAction>(
          tooltip: 'Mais opções',
          icon: const Icon(Icons.more_vert),
          onSelected: executarAcaoMenuHome,
          itemBuilder: (context) {
            return const [
              PopupMenuItem(
                value: _HomePageMenuAction.conta,
                child: ListTile(
                  leading: Icon(Icons.cloud_sync_outlined),
                  title: Text('Conta e Sync'),
                ),
              ),
              PopupMenuItem(
                value: _HomePageMenuAction.perfil,
                child: ListTile(
                  leading: Icon(Icons.person_outline),
                  title: Text('Meu perfil'),
                ),
              ),
              PopupMenuItem(
                value: _HomePageMenuAction.configuracoes,
                child: ListTile(
                  leading: Icon(Icons.settings_outlined),
                  title: Text('Configurações'),
                ),
              ),
              PopupMenuItem(
                value: _HomePageMenuAction.resetar,
                child: ListTile(
                  leading: Icon(Icons.delete_outline),
                  title: Text('Resetar dados'),
                ),
              ),
            ];
          },
        ),
      ];
    }

    return [
      const HomeNavigationButton(),
      IconButton(
        onPressed: abrirContaSync,
        tooltip: 'Conta e Sync',
        icon: const Icon(Icons.cloud_sync_outlined),
      ),
      IconButton(
        onPressed: abrirPerfil,
        tooltip: 'Meu perfil',
        icon: const Icon(Icons.person_outline),
      ),
      IconButton(
        onPressed: abrirConfiguracoes,
        tooltip: 'Configurações e backup',
        icon: const Icon(Icons.settings_outlined),
      ),
      IconButton(
        onPressed: resetarDados,
        tooltip: 'Resetar dados',
        icon: const Icon(Icons.delete_outline),
      ),
    ];
  }

  int get totalPartidasDoJogo {
    return historicoDoContextoAtual.length;
  }

  int get totalVitorias {
    return historicoDoContextoAtual
        .where((partida) => resultadoEhVitoria(partida.resultado))
        .length;
  }

  int get totalDerrotas {
    return historicoDoContextoAtual
        .where((partida) => resultadoEhDerrota(partida.resultado))
        .length;
  }

  int get lpTimePrincipal {
    if (!timePrincipalInvincible.completo) return 0;

    int lp = 0;
    final List<PartidaRegistrada> partidasDoTime = historicoDoContextoAtual;

    for (final partida in partidasDoTime.reversed) {
      lp += partida.pdlGerado;
      if (lp < 0) lp = 0;
    }

    return lp;
  }

  Character personagemReferenciaAtual() {
    if (widget.jogoAtual == jogoInvincibleVs &&
        timePrincipalInvincible.slot1.isNotEmpty &&
        personagens.containsKey(timePrincipalInvincible.slot1)) {
      return personagens[timePrincipalInvincible.slot1]!;
    }

    if (widget.jogoAtual == jogo2Xko && timePrincipal2XKO.completo) {
      return personagens[timePrincipal2XKO.key] ??
          characterDaDupla2XKO(timePrincipal2XKO);
    }

    if (widget.jogoAtual == jogoKofXV && timePrincipalKofXV.completo) {
      return personagens[timePrincipalKofXV.key] ??
          characterDoTimeKof(timePrincipalKofXV);
    }

    return personagemAtual;
  }

  @override
  Widget build(BuildContext context) {
    if (carregando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final bool isInvincible = widget.jogoAtual == jogoInvincibleVs;
    final bool is2XKO = widget.jogoAtual == jogo2Xko;
    final bool isKof = widget.jogoAtual == jogoKofXV;
    final bool isTeamContext = isInvincible || is2XKO || isKof;
    final bool isStreetFighter = widget.jogoAtual == jogoStreetFighter6;
    final Character personagem = personagemAtual;
    final String pontosLabel = labelPontosRank(widget.jogoAtual);
    final String contextoAtual = isInvincible
        ? (timePrincipalInvincible.completo
              ? timePrincipalInvincible.texto
              : 'Nenhum time principal definido')
        : is2XKO
        ? (timePrincipal2XKO.completo
              ? timePrincipal2XKO.texto
              : 'Nenhuma dupla definida')
        : isKof
        ? (timePrincipalKofXV.completo
              ? timePrincipalKofXV.texto
              : 'Nenhum time definido')
        : personagem.name;
    final bool appBarCompacta = MediaQuery.sizeOf(context).width < 480;

    return Scaffold(
      appBar: AppBar(
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          child: LtLogo(scale: 0.8, showProgress: false),
        ),
        centerTitle: true,
        leading: IconButton(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          padding: const EdgeInsets.all(12),
          visualDensity: VisualDensity.standard,
          onPressed: voltarTelaAnterior,
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back),
        ),
        actions: construirAcoesAppBar(appBarCompacta),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bem-vindo, ${perfil.nick}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            if (isTeamContext)
              Text(
                perfil.regiao.trim().isEmpty
                    ? '${widget.jogoAtual} - $contextoAtual'
                    : '${widget.jogoAtual} - $contextoAtual - ${perfil.regiao}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            if (!isTeamContext)
              Text(
                perfil.regiao.trim().isEmpty
                    ? '${widget.jogoAtual} • ${personagem.name}'
                    : '${widget.jogoAtual} • ${personagem.name} • ${perfil.regiao}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            const SizedBox(height: 32),
            Card(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bool isMobileCard = constraints.maxWidth < 520;
                  final double avatarSize = isMobileCard ? 56 : 68;

                  final bool timeCompleto = timePrincipalInvincible.completo;
                  final bool duplaCompleta = timePrincipal2XKO.completo;
                  final bool timeKofCompleto = timePrincipalKofXV.completo;
                  final int lpTime = lpTimePrincipal;
                  final String rankTime = calcularRankDoJogo(
                    widget.jogoAtual,
                    lpTime,
                  );
                  final int pdlDupla = personagem.pdl;
                  final List<String> nomesTime =
                      timePrincipalInvincible.personagens;
                  final List<String> nomesDupla = timePrincipal2XKO.personagens;
                  final List<String> nomesTimeKof =
                      timePrincipalKofXV.personagens;

                  final Widget avatar = isTeamContext
                      ? SizedBox(
                          width: isMobileCard
                              ? double.infinity
                              : is2XKO
                              ? 128
                              : isKof
                              ? 188
                              : 188,
                          child: Wrap(
                            alignment: isMobileCard
                                ? WrapAlignment.center
                                : WrapAlignment.start,
                            spacing: 8,
                            runSpacing: 8,
                            children: is2XKO
                                ? (duplaCompleta
                                      ? [
                                          for (final nome in nomesDupla)
                                            CharacterAvatar(
                                              personagem: nome,
                                              jogo: widget.jogoAtual,
                                              size: avatarSize,
                                              initialOverride:
                                                  personagens[nome]?.initial,
                                            ),
                                        ]
                                      : [
                                          CircleAvatar(
                                            radius: avatarSize / 2,
                                            child: const Icon(
                                              Icons.people_alt_outlined,
                                            ),
                                          ),
                                        ])
                                : isKof
                                ? (timeKofCompleto
                                      ? [
                                          for (final nome in nomesTimeKof)
                                            CharacterAvatar(
                                              personagem: nome,
                                              jogo: widget.jogoAtual,
                                              size: avatarSize,
                                              initialOverride:
                                                  personagens[nome]?.initial,
                                            ),
                                        ]
                                      : [
                                          CircleAvatar(
                                            radius: avatarSize / 2,
                                            child: const Icon(
                                              Icons.groups_outlined,
                                            ),
                                          ),
                                        ])
                                : timeCompleto
                                ? [
                                    for (final nome in nomesTime)
                                      CharacterAvatar(
                                        personagem: nome,
                                        jogo: widget.jogoAtual,
                                        size: avatarSize,
                                        initialOverride:
                                            personagens[nome]?.initial,
                                      ),
                                  ]
                                : [
                                    CircleAvatar(
                                      radius: avatarSize / 2,
                                      child: const Icon(Icons.groups_outlined),
                                    ),
                                  ],
                          ),
                        )
                      : CharacterAvatar(
                          personagem: personagem.name,
                          jogo: widget.jogoAtual,
                          size: avatarSize,
                          initialOverride: personagem.initial,
                          smashCoverPreferences: smashCoverPreferences,
                          usarPreferenciaVisualSmash: true,
                        );

                  final Widget perfilInfo = Column(
                    crossAxisAlignment: isMobileCard
                        ? CrossAxisAlignment.center
                        : CrossAxisAlignment.start,
                    children: [
                      Text(
                        isInvincible
                            ? 'Time Atual'
                            : is2XKO
                            ? 'Dupla Atual'
                            : isKof
                            ? 'Time Atual'
                            : isStreetFighter
                            ? 'Personagem Atual'
                            : 'Perfil atual',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: isMobileCard
                            ? TextAlign.center
                            : TextAlign.start,
                        style: TextStyle(
                          fontSize: isMobileCard ? 20 : 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Jogo: ${widget.jogoAtual}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: isMobileCard
                            ? TextAlign.center
                            : TextAlign.start,
                      ),
                      if (isTeamContext)
                        Text(
                          is2XKO
                              ? 'Dupla: $contextoAtual'
                              : isKof
                              ? 'Ordem: $contextoAtual'
                              : 'Time: $contextoAtual',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          textAlign: isMobileCard
                              ? TextAlign.center
                              : TextAlign.start,
                        )
                      else
                        Text(
                          'Personagem: ${personagem.name}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: isMobileCard
                              ? TextAlign.center
                              : TextAlign.start,
                        ),
                      const SizedBox(height: 6),
                      Wrap(
                        alignment: isMobileCard
                            ? WrapAlignment.center
                            : WrapAlignment.start,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          const Text('Rank:'),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: RankBadge(
                              rank: isInvincible ? rankTime : personagem.rank,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isInvincible
                            ? '$pontosLabel do time: $lpTime'
                            : is2XKO
                            ? '$pontosLabel da dupla: $pdlDupla'
                            : isKof
                            ? '$pontosLabel do time: $pdlDupla'
                            : '$pontosLabel: ${personagem.pdl}',
                      ),
                    ],
                  );

                  final Widget trocarButton = SizedBox(
                    width: isMobileCard ? double.infinity : null,
                    child: OutlinedButton(
                      onPressed: isInvincible
                          ? abrirMontarTimePrincipal
                          : is2XKO
                          ? abrirMontarTime2XKO
                          : isKof
                          ? abrirMontarTimeKofXV
                          : abrirSelecaoDePersonagem,
                      child: Text(
                        isInvincible
                            ? (timeCompleto ? 'Alterar Time' : 'Montar Time')
                            : is2XKO
                            ? (duplaCompleta ? 'Alterar Dupla' : 'Montar Dupla')
                            : isKof
                            ? (timeKofCompleto ? 'Alterar Time' : 'Montar Time')
                            : isStreetFighter
                            ? 'Selecionar Personagem'
                            : 'Trocar personagem',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );

                  return Padding(
                    padding: EdgeInsets.all(isMobileCard ? 16 : 20),
                    child: isMobileCard
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              avatar,
                              const SizedBox(height: 14),
                              perfilInfo,
                              const SizedBox(height: 16),
                              trocarButton,
                            ],
                          )
                        : Row(
                            children: [
                              avatar,
                              const SizedBox(width: 20),
                              Expanded(child: perfilInfo),
                              const SizedBox(width: 12),
                              trocarButton,
                            ],
                          ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: InfoBox(
                        titulo: 'Partidas',
                        valor: '$totalPartidasDoJogo',
                      ),
                    ),
                    Expanded(
                      child: InfoBox(
                        titulo: 'Vitórias',
                        valor: '$totalVitorias',
                      ),
                    ),
                    Expanded(
                      child: InfoBox(
                        titulo: 'Derrotas',
                        valor: '$totalDerrotas',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => abrirRegistrarPartida(),
                    child: const Text('Registrar partida'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: abrirHistorico,
                    child: const Text('Ver histórico'),
                  ),
                ),
              ],
            ),
            if (ultimaPartidaDoContextoAtual != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: abrirRepetirUltimaPartida,
                  icon: const Icon(Icons.replay_outlined),
                  label: const Text('Repetir ultima partida'),
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: abrirEstatisticas,
                icon: const Icon(Icons.bar_chart),
                label: const Text('Ver estatísticas'),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: abrirResumoTreino,
                icon: const Icon(Icons.today_outlined),
                label: Text(
                  widget.jogoAtual == jogoInvincibleVs
                      ? 'Leitura de times'
                      : widget.jogoAtual == jogo2Xko
                      ? 'Leitura da dupla'
                      : widget.jogoAtual == jogoKofXV
                      ? 'Leitura do time'
                      : 'Resumo do treino de hoje',
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: abrirPerfil,
                icon: const Icon(Icons.person_outline),
                label: const Text('Meu perfil'),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: abrirConfiguracoes,
                icon: const Icon(Icons.backup_outlined),
                label: const Text('Backup e configurações'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
