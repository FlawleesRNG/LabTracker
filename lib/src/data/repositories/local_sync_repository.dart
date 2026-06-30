part of '../../../main.dart';

String gerarIdLocal(String prefixo) {
  final Random random = Random.secure();
  final List<int> bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;

  String hexByte(int byte) => byte.toRadixString(16).padLeft(2, '0');
  final String hex = bytes.map(hexByte).join();

  return [
    hex.substring(0, 8),
    hex.substring(8, 12),
    hex.substring(12, 16),
    hex.substring(16, 20),
    hex.substring(20),
  ].join('-');
}

abstract final class LocalSyncRepository {
  static DateTime? dateTimeFromJson(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static PartidaRegistrada prepararPartidaParaSalvar({
    required PartidaRegistrada partida,
    required String deviceId,
    String? userId,
    required SyncOperation operation,
    DateTime? now,
  }) {
    final DateTime resolvedNow = now ?? DateTime.now();
    final bool nova =
        partida.id.trim().isEmpty || operation == SyncOperation.create;
    final DateTime createdAt = nova ? resolvedNow : partida.createdAt;

    return partida.copyWithSync(
      id: partida.id.trim().isEmpty ? gerarIdLocal('match') : partida.id,
      userId: userId,
      deviceId: deviceId,
      createdAt: createdAt,
      updatedAt: resolvedNow,
      clearDeletedAt: true,
      syncStatus: SyncStatus.pendingSync,
      clearLastSyncAt: true,
      syncErrorMessage: '',
    );
  }

  static PartidaRegistrada prepararPartidaExcluida({
    required PartidaRegistrada partida,
    required String deviceId,
    String? userId,
    DateTime? now,
  }) {
    final DateTime resolvedNow = now ?? DateTime.now();
    return partida.copyWithSync(
      id: partida.id.trim().isEmpty ? gerarIdLocal('match') : partida.id,
      userId: userId,
      deviceId: deviceId,
      createdAt: partida.createdAt,
      updatedAt: resolvedNow,
      deletedAt: resolvedNow,
      syncStatus: SyncStatus.deletedPendingSync,
      clearLastSyncAt: true,
      syncErrorMessage: '',
    );
  }

  static PartidaRegistrada garantirMetadadosPartida({
    required PartidaRegistrada partida,
    required String deviceId,
    DateTime? now,
  }) {
    final bool semId = partida.id.trim().isEmpty;
    final bool semDevice = partida.deviceId.trim().isEmpty;

    if (!semId && !semDevice) return partida;

    return partida.copyWithSync(
      id: semId ? gerarIdLocal('match') : partida.id,
      deviceId: semDevice ? deviceId : partida.deviceId,
      createdAt: partida.createdAt,
      updatedAt: partida.updatedAt,
      syncStatus: partida.deletadaLocalmente
          ? SyncStatus.deletedPendingSync
          : SyncStatus.pendingSync,
      clearLastSyncAt: partida.lastSyncAt == null,
      syncErrorMessage: partida.syncErrorMessage,
    );
  }

  static List<SyncQueueItem> upsertQueueItem({
    required List<SyncQueueItem> queue,
    required SyncEntityType entityType,
    required String entityId,
    required SyncOperation operation,
    DateTime? now,
  }) {
    if (entityId.trim().isEmpty) return queue;

    final DateTime resolvedNow = now ?? DateTime.now();
    final List<SyncQueueItem> atualizada = [...queue];
    final int index = atualizada.indexWhere((item) {
      return item.entityType == entityType &&
          item.entityId == entityId &&
          item.status != SyncQueueStatus.done;
    });

    if (index == -1) {
      atualizada.add(
        SyncQueueItem(
          id: gerarIdLocal('sync_queue'),
          entityType: entityType,
          entityId: entityId,
          operation: operation,
          createdAt: resolvedNow,
          updatedAt: resolvedNow,
        ),
      );
      return atualizada;
    }

    final SyncQueueItem existente = atualizada[index];
    final SyncOperation operacaoFinal =
        existente.operation == SyncOperation.create &&
            operation == SyncOperation.update
        ? SyncOperation.create
        : operation;

    atualizada[index] = existente.copyWith(
      operation: operacaoFinal,
      status: SyncQueueStatus.pending,
      updatedAt: resolvedNow,
      clearLastAttemptAt: true,
      errorMessage: '',
    );

    return atualizada;
  }

  static List<LocalSyncRecord> upsertRecord({
    required List<LocalSyncRecord> records,
    required SyncEntityType entityType,
    required String entityId,
    required String deviceId,
    String? userId,
    SyncStatus status = SyncStatus.pendingSync,
    DateTime? now,
  }) {
    if (entityId.trim().isEmpty) return records;

    final DateTime resolvedNow = now ?? DateTime.now();
    final List<LocalSyncRecord> atualizados = [...records];
    final int index = atualizados.indexWhere((record) {
      return record.entityType == entityType && record.entityId == entityId;
    });

    if (index == -1) {
      atualizados.add(
        LocalSyncRecord(
          id: gerarIdLocal('sync_record'),
          entityType: entityType,
          entityId: entityId,
          userId: userId,
          deviceId: deviceId,
          createdAt: resolvedNow,
          updatedAt: resolvedNow,
          syncStatus: status,
        ),
      );
      return atualizados;
    }

    atualizados[index] = atualizados[index].copyWith(
      deviceId: atualizados[index].deviceId.trim().isEmpty
          ? deviceId
          : atualizados[index].deviceId,
      userId: userId ?? atualizados[index].userId,
      updatedAt: resolvedNow,
      clearDeletedAt: true,
      syncStatus: status,
      clearLastSyncAt: status == SyncStatus.pendingSync,
      syncErrorMessage: status == SyncStatus.pendingSync
          ? ''
          : atualizados[index].syncErrorMessage,
    );

    return atualizados;
  }

  static List<SyncQueueItem> queueRecordUpdate({
    required List<SyncQueueItem> queue,
    required SyncEntityType entityType,
    required String entityId,
    DateTime? now,
  }) {
    return upsertQueueItem(
      queue: queue,
      entityType: entityType,
      entityId: entityId,
      operation: SyncOperation.update,
      now: now,
    );
  }
}
