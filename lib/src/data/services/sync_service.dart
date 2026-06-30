part of '../../../main.dart';

class SyncRunResult {
  final bool success;
  final String message;
  final int uploadedCount;
  final int downloadedCount;
  final int failedCount;
  final DateTime syncedAt;
  final String userId;
  final String deviceId;
  final List<PartidaRegistrada> historico;
  final List<PartidaRegistrada> partidasExcluidasParaSync;
  final List<SyncQueueItem> syncQueue;
  final List<LocalSyncRecord> syncRecords;
  final PlayerProfile perfil;
  final Map<String, String> smashCoverPreferences;
  final String personagemAtualNome;
  final TimePrincipalInvincible timePrincipalInvincible;
  final TimePrincipal2XKO timePrincipal2XKO;
  final TimePrincipalKofXV timePrincipalKofXV;

  const SyncRunResult({
    required this.success,
    required this.message,
    required this.uploadedCount,
    required this.downloadedCount,
    required this.failedCount,
    required this.syncedAt,
    required this.userId,
    required this.deviceId,
    required this.historico,
    required this.partidasExcluidasParaSync,
    required this.syncQueue,
    required this.syncRecords,
    required this.perfil,
    required this.smashCoverPreferences,
    required this.personagemAtualNome,
    required this.timePrincipalInvincible,
    required this.timePrincipal2XKO,
    required this.timePrincipalKofXV,
  });

  int get pendingCount {
    return syncQueue
        .where((item) => item.status == SyncQueueStatus.pending)
        .length;
  }

  int get errorCount {
    return syncQueue
        .where((item) => item.status == SyncQueueStatus.error)
        .length;
  }
}

class SyncCounters {
  int uploaded = 0;
  int downloaded = 0;
  int failed = 0;
}

class SyncMutableState {
  List<PartidaRegistrada> historico;
  List<PartidaRegistrada> partidasExcluidasParaSync;
  List<SyncQueueItem> syncQueue;
  List<LocalSyncRecord> syncRecords;
  PlayerProfile perfil;
  Map<String, String> smashCoverPreferences;
  String personagemAtualNome;
  TimePrincipalInvincible timePrincipalInvincible;
  TimePrincipal2XKO timePrincipal2XKO;
  TimePrincipalKofXV timePrincipalKofXV;

  SyncMutableState({
    required this.historico,
    required this.partidasExcluidasParaSync,
    required this.syncQueue,
    required this.syncRecords,
    required this.perfil,
    required this.smashCoverPreferences,
    required this.personagemAtualNome,
    required this.timePrincipalInvincible,
    required this.timePrincipal2XKO,
    required this.timePrincipalKofXV,
  });
}

abstract final class SyncService {
  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );

  static Future<SyncRunResult> syncNow({
    required String deviceId,
    required String? currentUserId,
    required String jogoAtual,
    required PlayerProfile perfil,
    required String personagemAtualNome,
    required TimePrincipalInvincible timePrincipalInvincible,
    required TimePrincipal2XKO timePrincipal2XKO,
    required TimePrincipalKofXV timePrincipalKofXV,
    required Map<String, Character> personagens,
    required List<PartidaRegistrada> historico,
    required List<PartidaRegistrada> partidasExcluidasParaSync,
    required List<SyncQueueItem> syncQueue,
    required List<LocalSyncRecord> syncRecords,
    required Map<String, String> smashCoverPreferences,
  }) async {
    if (!AuthService.isAvailable) {
      throw Exception(
        'Supabase nao esta configurado. O LabTracker continua funcionando offline.',
      );
    }

    final String? resolvedUserId = AuthService.currentUserId;
    if ((resolvedUserId ?? '').trim().isEmpty) {
      throw Exception('Entre em uma conta para sincronizar seus dados.');
    }
    await AuthService.persistCurrentUser();

    final SupabaseClient? maybeClient = SupabaseClientProvider.client;
    if (maybeClient == null) {
      throw Exception(
        'Supabase nao esta disponivel agora. O uso offline continua normal.',
      );
    }

    final SupabaseClient client = maybeClient;
    final String resolvedDeviceId = deviceId.trim().isNotEmpty
        ? deviceId.trim()
        : await DeviceService.obterOuCriarDeviceId();
    final DateTime syncStartedAt = DateTime.now();

    final SyncMutableState state = SyncMutableState(
      historico: List<PartidaRegistrada>.from(historico),
      partidasExcluidasParaSync: List<PartidaRegistrada>.from(
        partidasExcluidasParaSync,
      ),
      syncQueue: List<SyncQueueItem>.from(syncQueue),
      syncRecords: List<LocalSyncRecord>.from(syncRecords),
      perfil: perfil,
      smashCoverPreferences: Map<String, String>.from(smashCoverPreferences),
      personagemAtualNome: personagemAtualNome,
      timePrincipalInvincible: timePrincipalInvincible,
      timePrincipal2XKO: timePrincipal2XKO,
      timePrincipalKofXV: timePrincipalKofXV,
    );

    _normalizarIdsLocaisParaSupabase(state);
    _normalizarIdsInternosParaSupabase(state);
    _garantirMetadadosDaFila(
      state,
      deviceId: resolvedDeviceId,
      userId: resolvedUserId!,
    );

    await _upsertDevice(
      client: client,
      userId: resolvedUserId,
      deviceId: resolvedDeviceId,
      now: syncStartedAt,
    );
    await _upsertProfile(
      client: client,
      userId: resolvedUserId,
      perfil: perfil,
      now: syncStartedAt,
    );

    final SyncCounters counters = SyncCounters();

    await uploadPendingChanges(
      client: client,
      state: state,
      counters: counters,
      userId: resolvedUserId,
      deviceId: resolvedDeviceId,
      jogoAtual: jogoAtual,
      perfil: perfil,
      personagens: personagens,
      now: syncStartedAt,
    );

    await downloadRemoteChanges(
      client: client,
      state: state,
      counters: counters,
      userId: resolvedUserId,
      deviceId: resolvedDeviceId,
      jogoAtual: jogoAtual,
      now: syncStartedAt,
    );

    final bool success = counters.failed == 0;
    final String message = success
        ? 'Sincronizacao concluida.'
        : 'Sincronizacao parcial. Alguns itens ficaram pendentes para tentar de novo.';

    return SyncRunResult(
      success: success,
      message: message,
      uploadedCount: counters.uploaded,
      downloadedCount: counters.downloaded,
      failedCount: counters.failed,
      syncedAt: syncStartedAt,
      userId: resolvedUserId,
      deviceId: resolvedDeviceId,
      historico: state.historico,
      partidasExcluidasParaSync: state.partidasExcluidasParaSync,
      syncQueue: state.syncQueue,
      syncRecords: state.syncRecords,
      perfil: state.perfil,
      smashCoverPreferences: state.smashCoverPreferences,
      personagemAtualNome: state.personagemAtualNome,
      timePrincipalInvincible: state.timePrincipalInvincible,
      timePrincipal2XKO: state.timePrincipal2XKO,
      timePrincipalKofXV: state.timePrincipalKofXV,
    );
  }

  static Future<void> uploadPendingChanges({
    required SupabaseClient client,
    required SyncMutableState state,
    required SyncCounters counters,
    required String userId,
    required String deviceId,
    required String jogoAtual,
    required PlayerProfile perfil,
    required Map<String, Character> personagens,
    required DateTime now,
  }) async {
    final List<SyncQueueItem> itens = state.syncQueue
        .where(
          (item) =>
              item.status == SyncQueueStatus.pending ||
              item.status == SyncQueueStatus.error,
        )
        .toList();

    for (final SyncQueueItem item in itens) {
      state.syncQueue = _replaceQueueItem(
        state.syncQueue,
        item.copyWith(
          status: SyncQueueStatus.syncing,
          lastAttemptAt: now,
          updatedAt: now,
          errorMessage: '',
        ),
      );

      try {
        switch (item.entityType) {
          case SyncEntityType.match:
            await _uploadMatchQueueItem(
              client: client,
              state: state,
              item: item,
              userId: userId,
              deviceId: deviceId,
              now: now,
            );
            break;
          case SyncEntityType.gameProfile:
          case SyncEntityType.selectedCharacter:
          case SyncEntityType.selectedTeam:
            await _uploadGameProfile(
              client: client,
              state: state,
              item: item,
              userId: userId,
              deviceId: deviceId,
              jogoAtual: jogoAtual,
              perfil: perfil,
              now: now,
            );
            break;
          case SyncEntityType.characterProgress:
            await _uploadCharacterProgress(
              client: client,
              state: state,
              item: item,
              userId: userId,
              deviceId: deviceId,
              jogoAtual: jogoAtual,
              personagens: personagens,
              now: now,
            );
            break;
          case SyncEntityType.preference:
            await _uploadPreferences(
              client: client,
              state: state,
              item: item,
              userId: userId,
              deviceId: deviceId,
              now: now,
            );
            break;
          case SyncEntityType.favorite:
            await _uploadFavorites(
              client: client,
              state: state,
              item: item,
              userId: userId,
              deviceId: deviceId,
              now: now,
            );
            break;
        }

        try {
          await _upsertSyncEvent(
            client: client,
            item: item,
            userId: userId,
            deviceId: deviceId,
            status: SyncQueueStatus.done,
            errorMessage: '',
            now: now,
          );
        } catch (_) {}
        state.syncQueue = markAsSynced(state.syncQueue, item, now: now);
        counters.uploaded++;
      } catch (error) {
        counters.failed++;
        final String message = AuthService.friendlyError(error);
        await _tryUpsertSyncEventError(
          client: client,
          item: item,
          userId: userId,
          deviceId: deviceId,
          errorMessage: message,
          now: now,
        );
        state.syncQueue = markAsSyncError(
          state.syncQueue,
          item,
          errorMessage: message,
          now: now,
        );
        _markEntityError(state, item, message);
      }
    }
  }

  static Future<void> downloadRemoteChanges({
    required SupabaseClient client,
    required SyncMutableState state,
    required SyncCounters counters,
    required String userId,
    required String deviceId,
    required String jogoAtual,
    required DateTime now,
  }) async {
    counters.downloaded += await _downloadMatches(
      client: client,
      state: state,
      userId: userId,
      deviceId: deviceId,
      now: now,
    );
    counters.downloaded += await _downloadProfile(
      client: client,
      state: state,
      userId: userId,
    );
    counters.downloaded += await _downloadPreferences(
      client: client,
      state: state,
      userId: userId,
      deviceId: deviceId,
      now: now,
    );
    counters.downloaded += await _downloadGameProfiles(
      client: client,
      state: state,
      userId: userId,
      deviceId: deviceId,
      jogoAtual: jogoAtual,
      now: now,
    );
    counters.downloaded += await _downloadCharacterProgress(
      client: client,
      state: state,
      userId: userId,
      deviceId: deviceId,
      jogoAtual: jogoAtual,
      now: now,
    );
    counters.downloaded += await _downloadFavorites(
      client: client,
      userId: userId,
    );
  }

  static bool resolveConflict({
    required DateTime? localUpdatedAt,
    required DateTime? remoteUpdatedAt,
  }) {
    if (remoteUpdatedAt == null) return false;
    if (localUpdatedAt == null) return true;
    return remoteUpdatedAt.isAfter(localUpdatedAt);
  }

  static List<SyncQueueItem> markAsSynced(
    List<SyncQueueItem> queue,
    SyncQueueItem item, {
    required DateTime now,
  }) {
    return _replaceQueueItem(
      queue,
      item.copyWith(
        status: SyncQueueStatus.done,
        updatedAt: now,
        errorMessage: '',
      ),
    );
  }

  static List<SyncQueueItem> markAsSyncError(
    List<SyncQueueItem> queue,
    SyncQueueItem item, {
    required String errorMessage,
    required DateTime now,
  }) {
    return _replaceQueueItem(
      queue,
      item.copyWith(
        status: SyncQueueStatus.error,
        attempts: item.attempts + 1,
        lastAttemptAt: now,
        updatedAt: now,
        errorMessage: errorMessage,
      ),
    );
  }

  static void _garantirMetadadosDaFila(
    SyncMutableState state, {
    required String deviceId,
    required String userId,
  }) {
    for (final SyncQueueItem item in state.syncQueue) {
      if (item.entityType == SyncEntityType.match ||
          item.status == SyncQueueStatus.done) {
        continue;
      }

      final LocalSyncRecord? existing = _findRecord(
        state.syncRecords,
        item.entityType,
        item.entityId,
      );
      if (existing == null) {
        state.syncRecords.add(
          LocalSyncRecord(
            id: gerarIdLocal('sync_record'),
            entityType: item.entityType,
            entityId: item.entityId,
            userId: userId,
            deviceId: deviceId,
            createdAt: item.createdAt,
            updatedAt: item.updatedAt,
            syncStatus: SyncStatus.pendingSync,
          ),
        );
      } else if (existing.userId != userId || existing.deviceId != deviceId) {
        state.syncRecords = state.syncRecords.map((record) {
          if (record.entityType != item.entityType ||
              record.entityId != item.entityId) {
            return record;
          }
          return record.copyWith(userId: userId, deviceId: deviceId);
        }).toList();
      }
    }
  }

  static void _normalizarIdsLocaisParaSupabase(SyncMutableState state) {
    final Map<String, String> ids = {};

    PartidaRegistrada normalizar(PartidaRegistrada partida) {
      if (_looksLikeUuid(partida.id)) return partida;
      final String novoId = ids.putIfAbsent(
        partida.id,
        () => gerarIdLocal('match'),
      );
      return partida.copyWithSync(
        id: novoId,
        updatedAt: DateTime.now(),
        syncStatus: partida.deletadaLocalmente
            ? SyncStatus.deletedPendingSync
            : SyncStatus.pendingSync,
        clearLastSyncAt: true,
      );
    }

    state.historico = state.historico.map(normalizar).toList();
    state.partidasExcluidasParaSync = state.partidasExcluidasParaSync
        .map(normalizar)
        .toList();

    if (ids.isEmpty) return;

    state.syncQueue = state.syncQueue.map((item) {
      final String? novoId = ids[item.entityId];
      if (novoId == null) return item;
      return item.copyWith(entityId: novoId, status: SyncQueueStatus.pending);
    }).toList();
  }

  static void _normalizarIdsInternosParaSupabase(SyncMutableState state) {
    state.syncRecords = state.syncRecords.map((record) {
      if (_looksLikeUuid(record.id)) return record;
      return record.copyWith(id: gerarIdLocal('sync_record'));
    }).toList();

    state.syncQueue = state.syncQueue.map((item) {
      if (_looksLikeUuid(item.id)) return item;
      return item.copyWith(id: gerarIdLocal('sync_queue'));
    }).toList();
  }

  static Future<void> _upsertProfile({
    required SupabaseClient client,
    required String userId,
    required PlayerProfile perfil,
    required DateTime now,
  }) async {
    await client.from('profiles').upsert({
      'user_id': userId,
      'nickname': _resolvedNickname(perfil),
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    }, onConflict: 'user_id');
  }

  static Future<void> _upsertDevice({
    required SupabaseClient client,
    required String userId,
    required String deviceId,
    required DateTime now,
  }) async {
    await client.from('devices').upsert({
      'user_id': userId,
      'device_id': deviceId,
      'device_name': _deviceName,
      'platform': _platformName,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    }, onConflict: 'user_id,device_id');
  }

  static Future<void> _uploadMatchQueueItem({
    required SupabaseClient client,
    required SyncMutableState state,
    required SyncQueueItem item,
    required String userId,
    required String deviceId,
    required DateTime now,
  }) async {
    PartidaRegistrada? partida = state.historico
        .where((partida) => partida.id == item.entityId)
        .firstOrNull;
    partida ??= state.partidasExcluidasParaSync
        .where((partida) => partida.id == item.entityId)
        .firstOrNull;

    if (partida == null) return;

    if (!_looksLikeUuid(partida.id)) {
      throw Exception('Partida local com ID invalido para sync.');
    }

    final PartidaRegistrada partidaParaUpload =
        item.operation == SyncOperation.delete && partida.deletedAt == null
        ? partida.copyWithSync(
            userId: userId,
            deviceId: deviceId,
            deletedAt: now,
            updatedAt: now,
            syncStatus: SyncStatus.deletedPendingSync,
          )
        : partida.copyWithSync(userId: userId, deviceId: deviceId);

    await client
        .from('matches')
        .upsert(
          _matchRow(partidaParaUpload, userId: userId, deviceId: deviceId),
        );

    state.historico = state.historico.map((partida) {
      if (partida.id != partidaParaUpload.id) return partida;
      return partidaParaUpload.copyWithSync(
        syncStatus: SyncStatus.synced,
        lastSyncAt: now,
        syncErrorMessage: '',
      );
    }).toList();

    state.partidasExcluidasParaSync = state.partidasExcluidasParaSync.map((
      partida,
    ) {
      if (partida.id != partidaParaUpload.id) return partida;
      return partidaParaUpload.copyWithSync(
        syncStatus: SyncStatus.synced,
        lastSyncAt: now,
        syncErrorMessage: '',
      );
    }).toList();
  }

  static Future<void> _uploadGameProfile({
    required SupabaseClient client,
    required SyncMutableState state,
    required SyncQueueItem item,
    required String userId,
    required String deviceId,
    required String jogoAtual,
    required PlayerProfile perfil,
    required DateTime now,
  }) async {
    final LocalSyncRecord record = _recordFor(
      state,
      entityType: SyncEntityType.gameProfile,
      entityId: 'gameProfile:$jogoAtual',
      deviceId: deviceId,
      userId: userId,
      now: now,
    );
    final String selectedTeamKey = _selectedTeamKey(
      jogoAtual,
      state.timePrincipalInvincible,
      state.timePrincipal2XKO,
      state.timePrincipalKofXV,
    );
    final String defaultCharacter = rosterDoJogo(jogoAtual).isEmpty
        ? ''
        : rosterDoJogo(jogoAtual).first.name;
    final bool hasLocalHistory = state.historico.any(
      (partida) => partidaPertenceAoJogo(partida, jogoAtual),
    );
    final bool hasSelectedCharacter =
        state.personagemAtualNome.trim().isNotEmpty &&
        state.personagemAtualNome != defaultCharacter;
    final bool hasProfileData = perfil.toJson().values.any(
      (value) => value.toString().trim().isNotEmpty,
    );

    if (!hasLocalHistory &&
        !hasSelectedCharacter &&
        selectedTeamKey.isEmpty &&
        !hasProfileData) {
      _markRecordSynced(state, record, now: now);
      return;
    }

    await client.from('game_profiles').upsert({
      'id': record.id,
      'user_id': userId,
      'device_id': deviceId,
      'game_name': jogoAtual,
      'selected_character': state.personagemAtualNome,
      'selected_team_key': selectedTeamKey,
      'preferences_json': {
        'profile': perfil.toJson(),
        'teams': {
          jogoInvincibleVs: state.timePrincipalInvincible.toJson(),
          jogo2Xko: state.timePrincipal2XKO.toJson(),
          jogoKofXV: state.timePrincipalKofXV.toJson(),
        },
      },
      'created_at': record.createdAt.toIso8601String(),
      'updated_at': record.updatedAt.toIso8601String(),
      'deleted_at': record.deletedAt?.toIso8601String(),
    });

    _markRecordSynced(state, record, now: now);
    if (item.entityType != SyncEntityType.gameProfile) {
      _markRecordSynced(
        state,
        _recordFor(
          state,
          entityType: item.entityType,
          entityId: item.entityId,
          deviceId: deviceId,
          userId: userId,
          now: now,
        ),
        now: now,
      );
    }
  }

  static Future<void> _uploadCharacterProgress({
    required SupabaseClient client,
    required SyncMutableState state,
    required SyncQueueItem item,
    required String userId,
    required String deviceId,
    required String jogoAtual,
    required Map<String, Character> personagens,
    required DateTime now,
  }) async {
    final List<Map<String, dynamic>> rows = [];

    for (final Character personagem in personagens.values) {
      if (personagem.pdl == 0) continue;

      final LocalSyncRecord record = _recordFor(
        state,
        entityType: SyncEntityType.characterProgress,
        entityId: 'character:$jogoAtual:${personagem.name}',
        deviceId: deviceId,
        userId: userId,
        now: now,
      );

      rows.add({
        'id': record.id,
        'user_id': userId,
        'device_id': deviceId,
        'game_name': jogoAtual,
        'character_or_team_key': personagem.name,
        'rank_name': personagem.rank,
        'pdl': personagem.pdl,
        'stats_json': personagem.toJson(),
        'created_at': record.createdAt.toIso8601String(),
        'updated_at': record.updatedAt.toIso8601String(),
        'deleted_at': record.deletedAt?.toIso8601String(),
      });
      _markRecordSynced(state, record, now: now);
    }

    if (rows.isNotEmpty) {
      await client.from('character_progress').upsert(rows);
    }

    _markRecordSynced(
      state,
      _recordFor(
        state,
        entityType: item.entityType,
        entityId: item.entityId,
        deviceId: deviceId,
        userId: userId,
        now: now,
      ),
      now: now,
    );
  }

  static Future<void> _uploadPreferences({
    required SupabaseClient client,
    required SyncMutableState state,
    required SyncQueueItem item,
    required String userId,
    required String deviceId,
    required DateTime now,
  }) async {
    final LocalSyncRecord record = _recordFor(
      state,
      entityType: SyncEntityType.preference,
      entityId: prefsKeySmashCoverPreferences,
      deviceId: deviceId,
      userId: userId,
      now: now,
    );
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool autoSyncEnabled = prefs.getBool(prefsKeyAutoSyncEnabled) ?? true;
    final Set<String> favoriteGames = await carregarJogosFavoritos();
    final Map<String, List<String>> favoriteCharacters =
        await carregarPersonagensFavoritosPorJogo();
    final List<String> recentGames = await carregarJogosRecentes();
    final Map<String, List<String>> recentCharacters =
        await carregarPersonagensRecentesPorJogo();

    if (state.smashCoverPreferences.isEmpty &&
        favoriteGames.isEmpty &&
        favoriteCharacters.isEmpty &&
        recentGames.isEmpty &&
        recentCharacters.isEmpty &&
        autoSyncEnabled) {
      _markRecordSynced(state, record, now: now);
      return;
    }

    await client.from('user_preferences').upsert({
      'id': record.id,
      'user_id': userId,
      'device_id': deviceId,
      'preferences_json': {
        'schemaVersion': 1,
        'autoSyncEnabled': autoSyncEnabled,
        'smashCoverPreferences': state.smashCoverPreferences,
        'favoriteGames': favoriteGames.toList()..sort(),
        'favoriteCharactersByGame': favoriteCharacters,
        'recentGames': recentGames,
        'recentCharactersByGame': recentCharacters,
      },
      'created_at': record.createdAt.toIso8601String(),
      'updated_at': record.updatedAt.toIso8601String(),
      'deleted_at': record.deletedAt?.toIso8601String(),
    });

    _markRecordSynced(state, record, now: now);
  }

  static Future<void> _uploadFavorites({
    required SupabaseClient client,
    required SyncMutableState state,
    required SyncQueueItem item,
    required String userId,
    required String deviceId,
    required DateTime now,
  }) async {
    final List<Map<String, dynamic>> rows = [];
    final Set<String> favoriteGames = await carregarJogosFavoritos();
    final Map<String, List<String>> favoriteCharacters =
        await carregarPersonagensFavoritosPorJogo();

    for (final String game in favoriteGames) {
      final LocalSyncRecord record = _recordFor(
        state,
        entityType: SyncEntityType.favorite,
        entityId: 'favorite:game:$game',
        deviceId: deviceId,
        userId: userId,
        now: now,
      );
      rows.add({
        'id': record.id,
        'user_id': userId,
        'device_id': deviceId,
        'favorite_type': 'game',
        'game_name': game,
        'target_key': game,
        'created_at': record.createdAt.toIso8601String(),
        'updated_at': record.updatedAt.toIso8601String(),
        'deleted_at': record.deletedAt?.toIso8601String(),
      });
      _markRecordSynced(state, record, now: now);
    }

    for (final MapEntry<String, List<String>> entry
        in favoriteCharacters.entries) {
      for (final String character in entry.value) {
        final LocalSyncRecord record = _recordFor(
          state,
          entityType: SyncEntityType.favorite,
          entityId: 'favorite:character:${entry.key}:$character',
          deviceId: deviceId,
          userId: userId,
          now: now,
        );
        rows.add({
          'id': record.id,
          'user_id': userId,
          'device_id': deviceId,
          'favorite_type': 'character',
          'game_name': entry.key,
          'target_key': character,
          'created_at': record.createdAt.toIso8601String(),
          'updated_at': record.updatedAt.toIso8601String(),
          'deleted_at': record.deletedAt?.toIso8601String(),
        });
        _markRecordSynced(state, record, now: now);
      }
    }

    if (rows.isNotEmpty) {
      await client.from('favorites').upsert(rows);
    }

    _markRecordSynced(
      state,
      _recordFor(
        state,
        entityType: item.entityType,
        entityId: item.entityId,
        deviceId: deviceId,
        userId: userId,
        now: now,
      ),
      now: now,
    );
  }

  static Future<int> _downloadMatches({
    required SupabaseClient client,
    required SyncMutableState state,
    required String userId,
    required String deviceId,
    required DateTime now,
  }) async {
    final dynamic response = await client
        .from('matches')
        .select()
        .eq('user_id', userId);
    int changed = 0;

    for (final Map<String, dynamic> row in _rows(response)) {
      final PartidaRegistrada remote = _matchFromRow(
        row,
        deviceId: deviceId,
        lastSyncAt: now,
      );
      final int localIndex = state.historico.indexWhere(
        (partida) => partida.id == remote.id,
      );
      final int deletedIndex = state.partidasExcluidasParaSync.indexWhere(
        (partida) => partida.id == remote.id,
      );
      final PartidaRegistrada? local = localIndex == -1
          ? deletedIndex == -1
                ? null
                : state.partidasExcluidasParaSync[deletedIndex]
          : state.historico[localIndex];

      if (remote.deletadaLocalmente) {
        if (resolveConflict(
          localUpdatedAt: local?.updatedAt,
          remoteUpdatedAt: remote.updatedAt,
        )) {
          state.historico.removeWhere((partida) => partida.id == remote.id);
          state.partidasExcluidasParaSync.removeWhere(
            (partida) => partida.id == remote.id,
          );
          state.partidasExcluidasParaSync.add(remote);
          changed++;
        }
        continue;
      }

      if (localIndex == -1 && deletedIndex == -1) {
        state.historico.add(remote);
        changed++;
      } else if (resolveConflict(
        localUpdatedAt: local?.updatedAt,
        remoteUpdatedAt: remote.updatedAt,
      )) {
        state.partidasExcluidasParaSync.removeWhere(
          (partida) => partida.id == remote.id,
        );
        if (localIndex == -1) {
          state.historico.add(remote);
        } else {
          state.historico[localIndex] = remote;
        }
        changed++;
      }
    }

    state.historico.sort((a, b) => b.data.compareTo(a.data));
    return changed;
  }

  static Future<int> _downloadProfile({
    required SupabaseClient client,
    required SyncMutableState state,
    required String userId,
  }) async {
    final dynamic response = await client
        .from('profiles')
        .select()
        .eq('user_id', userId);
    final List<Map<String, dynamic>> rows = _rows(response);
    if (rows.isEmpty) return 0;

    rows.sort((a, b) {
      final DateTime aUpdated = _dateFromRemote(a['updated_at']) ?? DateTime(0);
      final DateTime bUpdated = _dateFromRemote(b['updated_at']) ?? DateTime(0);
      return bUpdated.compareTo(aUpdated);
    });

    final String nickname = rows.first['nickname']?.toString().trim() ?? '';
    if (nickname.isEmpty || nickname == state.perfil.nick) return 0;

    state.perfil = state.perfil.copyWith(nick: nickname);
    return 1;
  }

  static Future<int> _downloadPreferences({
    required SupabaseClient client,
    required SyncMutableState state,
    required String userId,
    required String deviceId,
    required DateTime now,
  }) async {
    final dynamic response = await client
        .from('user_preferences')
        .select()
        .eq('user_id', userId);
    final List<Map<String, dynamic>> rows = _rows(response);
    if (rows.isEmpty) return 0;

    rows.sort((a, b) {
      final DateTime aUpdated = _dateFromRemote(a['updated_at']) ?? DateTime(0);
      final DateTime bUpdated = _dateFromRemote(b['updated_at']) ?? DateTime(0);
      return bUpdated.compareTo(aUpdated);
    });

    final Map<String, dynamic> latest = rows.first;
    final DateTime remoteUpdatedAt =
        _dateFromRemote(latest['updated_at']) ?? now;
    final LocalSyncRecord? localRecord = _findRecord(
      state.syncRecords,
      SyncEntityType.preference,
      prefsKeySmashCoverPreferences,
    );

    if (!resolveConflict(
      localUpdatedAt: localRecord?.updatedAt,
      remoteUpdatedAt: remoteUpdatedAt,
    )) {
      return 0;
    }

    final Map<String, dynamic> preferences = _jsonMap(
      latest['preferences_json'],
    );
    state.smashCoverPreferences = _stringMap(
      preferences['smashCoverPreferences'],
    );

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (preferences['autoSyncEnabled'] is bool) {
      await prefs.setBool(
        prefsKeyAutoSyncEnabled,
        preferences['autoSyncEnabled'] as bool,
      );
    }
    await salvarJogosFavoritos(_stringSet(preferences['favoriteGames']));
    await salvarPersonagensFavoritosPorJogo(
      _stringListMap(preferences['favoriteCharactersByGame']),
    );

    await prefs.setStringList(
      prefsKeyRecentGames,
      _stringList(preferences['recentGames']),
    );
    await prefs.setString(
      prefsKeyRecentCharactersByGame,
      jsonEncode(_stringListMap(preferences['recentCharactersByGame'])),
    );

    _upsertRemoteRecordAsSynced(
      state,
      entityType: SyncEntityType.preference,
      entityId: prefsKeySmashCoverPreferences,
      remoteId: latest['id']?.toString() ?? gerarIdLocal('sync_record'),
      userId: userId,
      deviceId: deviceId,
      remoteUpdatedAt: remoteUpdatedAt,
      now: now,
    );

    return 1;
  }

  static Future<int> _downloadGameProfiles({
    required SupabaseClient client,
    required SyncMutableState state,
    required String userId,
    required String deviceId,
    required String jogoAtual,
    required DateTime now,
  }) async {
    final dynamic response = await client
        .from('game_profiles')
        .select()
        .eq('user_id', userId)
        .eq('game_name', jogoAtual);
    final List<Map<String, dynamic>> rows = _rows(response);
    if (rows.isEmpty) return 0;

    rows.sort((a, b) {
      final DateTime aUpdated = _dateFromRemote(a['updated_at']) ?? DateTime(0);
      final DateTime bUpdated = _dateFromRemote(b['updated_at']) ?? DateTime(0);
      return bUpdated.compareTo(aUpdated);
    });

    final Map<String, dynamic> latest = rows.first;
    final DateTime remoteUpdatedAt =
        _dateFromRemote(latest['updated_at']) ?? now;
    final LocalSyncRecord? localRecord = _findRecord(
      state.syncRecords,
      SyncEntityType.gameProfile,
      'gameProfile:$jogoAtual',
    );

    if (!resolveConflict(
      localUpdatedAt: localRecord?.updatedAt,
      remoteUpdatedAt: remoteUpdatedAt,
    )) {
      return 0;
    }

    final String selectedCharacter =
        latest['selected_character']?.toString() ?? '';
    if (selectedCharacter.trim().isNotEmpty) {
      state.personagemAtualNome = selectedCharacter;
    }

    final Map<String, dynamic> preferences = _jsonMap(
      latest['preferences_json'],
    );
    final Map<String, dynamic> profile = _jsonMap(preferences['profile']);
    if (profile.isNotEmpty) {
      state.perfil = PlayerProfile.fromJson(profile).copyWith(
        nick: state.perfil.nick.trim().isNotEmpty
            ? state.perfil.nick
            : profile['nick']?.toString(),
      );
    }
    final Map<String, dynamic> teams = _jsonMap(preferences['teams']);
    if (teams[jogoInvincibleVs] is Map) {
      state.timePrincipalInvincible = TimePrincipalInvincible.fromJson(
        Map<String, dynamic>.from(teams[jogoInvincibleVs] as Map),
      );
    }
    if (teams[jogo2Xko] is Map) {
      state.timePrincipal2XKO = TimePrincipal2XKO.fromJson(
        Map<String, dynamic>.from(teams[jogo2Xko] as Map),
      );
    }
    if (teams[jogoKofXV] is Map) {
      state.timePrincipalKofXV = TimePrincipalKofXV.fromJson(
        Map<String, dynamic>.from(teams[jogoKofXV] as Map),
      );
    }

    _upsertRemoteRecordAsSynced(
      state,
      entityType: SyncEntityType.gameProfile,
      entityId: 'gameProfile:$jogoAtual',
      remoteId: latest['id']?.toString() ?? gerarIdLocal('sync_record'),
      userId: userId,
      deviceId: deviceId,
      remoteUpdatedAt: remoteUpdatedAt,
      now: now,
    );

    return 1;
  }

  static Future<int> _downloadCharacterProgress({
    required SupabaseClient client,
    required SyncMutableState state,
    required String userId,
    required String deviceId,
    required String jogoAtual,
    required DateTime now,
  }) async {
    final dynamic response = await client
        .from('character_progress')
        .select()
        .eq('user_id', userId)
        .eq('game_name', jogoAtual);
    int changed = 0;

    for (final Map<String, dynamic> row in _rows(response)) {
      final String key = row['character_or_team_key']?.toString() ?? '';
      if (key.trim().isEmpty) continue;

      final String entityId = 'character:$jogoAtual:$key';
      final DateTime remoteUpdatedAt =
          _dateFromRemote(row['updated_at']) ?? now;
      final DateTime? remoteDeletedAt = _dateFromRemote(row['deleted_at']);
      final LocalSyncRecord? localRecord = _findRecord(
        state.syncRecords,
        SyncEntityType.characterProgress,
        entityId,
      );

      if (!resolveConflict(
        localUpdatedAt: localRecord?.updatedAt,
        remoteUpdatedAt: remoteUpdatedAt,
      )) {
        continue;
      }

      _upsertRemoteRecordAsSynced(
        state,
        entityType: SyncEntityType.characterProgress,
        entityId: entityId,
        remoteId: row['id']?.toString() ?? gerarIdLocal('sync_record'),
        userId: userId,
        deviceId: deviceId,
        remoteUpdatedAt: remoteUpdatedAt,
        deletedAt: remoteDeletedAt,
        now: now,
      );
      changed++;
    }

    return changed;
  }

  static Future<int> _downloadFavorites({
    required SupabaseClient client,
    required String userId,
  }) async {
    final dynamic response = await client
        .from('favorites')
        .select()
        .eq('user_id', userId);
    final Set<String> favoriteGames = await carregarJogosFavoritos();
    final Map<String, List<String>> favoriteCharacters =
        await carregarPersonagensFavoritosPorJogo();
    int changed = 0;

    for (final Map<String, dynamic> row in _rows(response)) {
      if (_dateFromRemote(row['deleted_at']) != null) continue;
      final String type = row['favorite_type']?.toString() ?? '';
      final String game = row['game_name']?.toString() ?? '';
      final String target = row['target_key']?.toString() ?? '';

      if (type == 'game' && target.isNotEmpty && favoriteGames.add(target)) {
        changed++;
      } else if (type == 'character' && game.isNotEmpty && target.isNotEmpty) {
        final List<String> list = favoriteCharacters.putIfAbsent(
          game,
          () => [],
        );
        if (!list.contains(target)) {
          list.add(target);
          changed++;
        }
      }
    }

    if (changed > 0) {
      await salvarJogosFavoritos(favoriteGames);
      await salvarPersonagensFavoritosPorJogo(favoriteCharacters);
    }

    return changed;
  }

  static Future<void> _upsertSyncEvent({
    required SupabaseClient client,
    required SyncQueueItem item,
    required String userId,
    required String deviceId,
    required SyncQueueStatus status,
    required String errorMessage,
    required DateTime now,
  }) async {
    await client.from('sync_events').upsert({
      'id': item.id,
      'user_id': userId,
      'device_id': deviceId,
      'entity_type': item.entityType.id,
      'entity_id': item.entityId,
      'operation': item.operation.id,
      'status': status.id,
      'error_message': errorMessage,
      'created_at': item.createdAt.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });
  }

  static Future<void> _tryUpsertSyncEventError({
    required SupabaseClient client,
    required SyncQueueItem item,
    required String userId,
    required String deviceId,
    required String errorMessage,
    required DateTime now,
  }) async {
    try {
      await _upsertSyncEvent(
        client: client,
        item: item,
        userId: userId,
        deviceId: deviceId,
        status: SyncQueueStatus.error,
        errorMessage: errorMessage,
        now: now,
      );
    } catch (_) {}
  }

  static Map<String, dynamic> _matchRow(
    PartidaRegistrada partida, {
    required String userId,
    required String deviceId,
  }) {
    final Map<String, dynamic> data = partida
        .copyWithSync(userId: userId, deviceId: deviceId)
        .toJson();

    return {
      'id': partida.id,
      'user_id': userId,
      'device_id': deviceId,
      'game_name': partida.jogo,
      'character_or_team_key': partida.personagemJogador,
      'opponent_nick': partida.nickAdversario,
      'opponent_character': partida.personagemAdversario,
      'result': partida.resultado,
      'score': partida.placarStreetFighter,
      'match_data_json': data,
      'created_at': partida.createdAt.toIso8601String(),
      'updated_at': partida.updatedAt.toIso8601String(),
      'deleted_at': partida.deletedAt?.toIso8601String(),
    };
  }

  static PartidaRegistrada _matchFromRow(
    Map<String, dynamic> row, {
    required String deviceId,
    required DateTime lastSyncAt,
  }) {
    final Map<String, dynamic> data = _jsonMap(row['match_data_json']);
    data['id'] = row['id']?.toString() ?? data['id'];
    data['userId'] = row['user_id']?.toString() ?? data['userId'];
    data['deviceId'] = row['device_id']?.toString() ?? data['deviceId'];
    data['jogo'] = row['game_name']?.toString() ?? data['jogo'];
    data['createdAt'] =
        row['created_at']?.toString() ?? data['createdAt']?.toString();
    data['updatedAt'] =
        row['updated_at']?.toString() ?? data['updatedAt']?.toString();
    data['deletedAt'] =
        row['deleted_at']?.toString() ?? data['deletedAt']?.toString();

    return PartidaRegistrada.fromJson(data).copyWithSync(
      deviceId: data['deviceId']?.toString().trim().isNotEmpty == true
          ? data['deviceId'].toString()
          : deviceId,
      syncStatus: data['deletedAt'] == null
          ? SyncStatus.synced
          : SyncStatus.synced,
      lastSyncAt: lastSyncAt,
      syncErrorMessage: '',
    );
  }

  static LocalSyncRecord _recordFor(
    SyncMutableState state, {
    required SyncEntityType entityType,
    required String entityId,
    required String deviceId,
    required String userId,
    required DateTime now,
  }) {
    final LocalSyncRecord? existing = _findRecord(
      state.syncRecords,
      entityType,
      entityId,
    );

    if (existing != null) {
      final LocalSyncRecord updated = existing.copyWith(
        userId: userId,
        deviceId: existing.deviceId.trim().isEmpty
            ? deviceId
            : existing.deviceId,
      );
      state.syncRecords = state.syncRecords.map((record) {
        if (record.entityType == entityType && record.entityId == entityId) {
          return updated;
        }
        return record;
      }).toList();
      return updated;
    }

    final LocalSyncRecord created = LocalSyncRecord(
      id: gerarIdLocal('sync_record'),
      entityType: entityType,
      entityId: entityId,
      userId: userId,
      deviceId: deviceId,
      createdAt: now,
      updatedAt: now,
      syncStatus: SyncStatus.pendingSync,
    );
    state.syncRecords.add(created);
    return created;
  }

  static LocalSyncRecord? _findRecord(
    List<LocalSyncRecord> records,
    SyncEntityType entityType,
    String entityId,
  ) {
    for (final LocalSyncRecord record in records) {
      if (record.entityType == entityType && record.entityId == entityId) {
        return record;
      }
    }
    return null;
  }

  static void _markRecordSynced(
    SyncMutableState state,
    LocalSyncRecord record, {
    required DateTime now,
  }) {
    state.syncRecords = state.syncRecords.map((item) {
      if (item.entityType != record.entityType ||
          item.entityId != record.entityId) {
        return item;
      }
      return item.copyWith(
        syncStatus: SyncStatus.synced,
        lastSyncAt: now,
        syncErrorMessage: '',
      );
    }).toList();
  }

  static void _upsertRemoteRecordAsSynced(
    SyncMutableState state, {
    required SyncEntityType entityType,
    required String entityId,
    required String remoteId,
    required String userId,
    required String deviceId,
    required DateTime remoteUpdatedAt,
    DateTime? deletedAt,
    required DateTime now,
  }) {
    final LocalSyncRecord? existing = _findRecord(
      state.syncRecords,
      entityType,
      entityId,
    );
    final LocalSyncRecord record =
        existing ??
        LocalSyncRecord(
          id: remoteId,
          entityType: entityType,
          entityId: entityId,
          userId: userId,
          deviceId: deviceId,
          createdAt: remoteUpdatedAt,
          updatedAt: remoteUpdatedAt,
        );

    final LocalSyncRecord synced = record.copyWith(
      id: record.id.trim().isEmpty ? remoteId : record.id,
      userId: userId,
      deviceId: deviceId,
      updatedAt: remoteUpdatedAt,
      deletedAt: deletedAt,
      clearDeletedAt: deletedAt == null,
      syncStatus: SyncStatus.synced,
      lastSyncAt: now,
      syncErrorMessage: '',
    );

    state.syncRecords = [
      ...state.syncRecords.where(
        (item) => item.entityType != entityType || item.entityId != entityId,
      ),
      synced,
    ];
  }

  static void _markEntityError(
    SyncMutableState state,
    SyncQueueItem item,
    String errorMessage,
  ) {
    state.syncRecords = state.syncRecords.map((record) {
      if (record.entityType != item.entityType ||
          record.entityId != item.entityId) {
        return record;
      }
      return record.copyWith(
        syncStatus: SyncStatus.syncError,
        syncErrorMessage: errorMessage,
      );
    }).toList();

    state.historico = state.historico.map((partida) {
      if (item.entityType != SyncEntityType.match ||
          partida.id != item.entityId) {
        return partida;
      }
      return partida.copyWithSync(
        syncStatus: SyncStatus.syncError,
        syncErrorMessage: errorMessage,
      );
    }).toList();
  }

  static List<SyncQueueItem> _replaceQueueItem(
    List<SyncQueueItem> queue,
    SyncQueueItem item,
  ) {
    return queue.map((current) {
      if (current.id == item.id) return item;
      return current;
    }).toList();
  }

  static String _selectedTeamKey(
    String jogoAtual,
    TimePrincipalInvincible invincible,
    TimePrincipal2XKO twoXko,
    TimePrincipalKofXV kof,
  ) {
    if (jogoAtual == jogoInvincibleVs && invincible.completo) {
      return invincible.personagens.join(' / ');
    }
    if (jogoAtual == jogo2Xko && twoXko.completo) return twoXko.key;
    if (jogoAtual == jogoKofXV && kof.completo) return kof.key;
    return '';
  }

  static String _resolvedNickname(PlayerProfile perfil) {
    if (perfil.nick.trim().isNotEmpty) return perfil.nick.trim();
    final String? authNick = AuthService.currentUserNick;
    if ((authNick ?? '').trim().isNotEmpty) return authNick!.trim();
    final String? email = AuthService.currentUserEmail;
    if ((email ?? '').trim().isNotEmpty) {
      return email!.split('@').first.trim();
    }
    return '';
  }

  static List<Map<String, dynamic>> _rows(dynamic response) {
    if (response is! List) return const [];
    return response
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  static Map<String, dynamic> _jsonMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String && value.trim().isNotEmpty) {
      try {
        final dynamic decoded = jsonDecode(value);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return {};
  }

  static Map<String, String> _stringMap(dynamic value) {
    if (value is! Map) return {};
    return value.map(
      (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
    );
  }

  static Set<String> _stringSet(dynamic value) {
    return _stringList(value).toSet();
  }

  static List<String> _stringList(dynamic value) {
    if (value is! Iterable) return const [];
    return value
        .map((item) => item?.toString() ?? '')
        .where((item) => item.trim().isNotEmpty)
        .toList();
  }

  static Map<String, List<String>> _stringListMap(dynamic value) {
    if (value is! Map) return {};
    final Map<String, List<String>> result = {};
    for (final MapEntry<dynamic, dynamic> entry in value.entries) {
      result[entry.key.toString()] = _stringList(entry.value);
    }
    return result;
  }

  static DateTime? _dateFromRemote(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static bool _looksLikeUuid(String value) {
    return _uuidRegex.hasMatch(value.trim());
  }

  static String get _deviceName {
    try {
      return Platform.localHostname;
    } catch (_) {
      return 'LabTracker';
    }
  }

  static String get _platformName {
    try {
      return Platform.operatingSystem;
    } catch (_) {
      return 'unknown';
    }
  }
}
