part of '../../main.dart';

class Character {
  final String name;
  final String initial;
  final String rank;
  final int pdl;

  const Character({
    required this.name,
    required this.initial,
    required this.rank,
    required this.pdl,
  });

  Character copyWith({String? name, String? initial, String? rank, int? pdl}) {
    return Character(
      name: name ?? this.name,
      initial: initial ?? this.initial,
      rank: rank ?? this.rank,
      pdl: pdl ?? this.pdl,
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'initial': initial, 'rank': rank, 'pdl': pdl};
  }

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      name: normalizarNomePersonagem(json['name'] ?? ''),
      initial: json['initial'] ?? '?',
      rank: json['rank'] ?? 'Starter V',
      pdl: json['pdl'] ?? 0,
    );
  }
}

class PlayerProfile {
  final String nick;
  final String tagSecundaria;
  final String regiao;
  final String jogoPrincipal;
  final String mainPrincipal;
  final String bio;
  final String email;
  final String fotoUrl;

  const PlayerProfile({
    required this.nick,
    required this.tagSecundaria,
    required this.regiao,
    required this.jogoPrincipal,
    required this.mainPrincipal,
    required this.bio,
    this.email = '',
    this.fotoUrl = '',
  });

  PlayerProfile copyWith({
    String? nick,
    String? tagSecundaria,
    String? regiao,
    String? jogoPrincipal,
    String? mainPrincipal,
    String? bio,
    String? email,
    String? fotoUrl,
  }) {
    return PlayerProfile(
      nick: nick ?? this.nick,
      tagSecundaria: tagSecundaria ?? this.tagSecundaria,
      regiao: regiao ?? this.regiao,
      jogoPrincipal: jogoPrincipal ?? this.jogoPrincipal,
      mainPrincipal: mainPrincipal ?? this.mainPrincipal,
      bio: bio ?? this.bio,
      email: email ?? this.email,
      fotoUrl: fotoUrl ?? this.fotoUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nick': nick,
      'tagSecundaria': tagSecundaria,
      'regiao': regiao,
      'jogoPrincipal': jogoPrincipal,
      'mainPrincipal': mainPrincipal,
      'bio': bio,
      'email': email,
      'fotoUrl': fotoUrl,
    };
  }

  factory PlayerProfile.fromJson(Map<String, dynamic> json) {
    return PlayerProfile(
      nick: json['nick'] ?? 'Flawlees',
      tagSecundaria: json['tagSecundaria'] ?? '',
      regiao: json['regiao'] ?? '',
      jogoPrincipal: json['jogoPrincipal'] ?? '',
      mainPrincipal: json['mainPrincipal'] ?? '',
      bio: json['bio'] ?? '',
      email: json['email'] ?? '',
      fotoUrl: json['fotoUrl'] ?? '',
    );
  }
}

const PlayerProfile perfilPadrao = PlayerProfile(
  nick: '',
  tagSecundaria: '',
  regiao: '',
  jogoPrincipal: '',
  mainPrincipal: '',
  bio: '',
);

class SmashCoverOption {
  final String id;
  final String label;
  final List<String> imageUrls;

  const SmashCoverOption({
    required this.id,
    required this.label,
    this.imageUrls = const [],
  });
}

class AppImageSource {
  final String remoteUrl;
  final String localAsset;

  const AppImageSource({this.remoteUrl = '', this.localAsset = ''});

  bool get isEmpty => remoteUrl.trim().isEmpty && localAsset.trim().isEmpty;
}

const String jogoSmashUltimate = 'Super Smash Bros. Ultimate';
const String jogoStreetFighter6 = 'Street Fighter 6';
const String jogoMortalKombat1 = 'Mortal Kombat 1';
const String jogoGuiltyGearStrive = 'Guilty Gear -Strive-';
const String jogoKofXV = 'The King of Fighters XV';
const String jogoInvincibleVs = 'Invincible VS';
const String jogoTekken8 = 'Tekken 8';
const String jogo2Xko = '2XKO';
const String jogoRivalsOfAether2 = 'Rivals of Aether II';
const String jogoFatalFury = 'Fatal Fury';

const String prefsKeySmashCoverPreferences = 'smashCoverPreferences';
const String prefsKeyFavoriteGames = 'favoriteGames';
const String prefsKeyRecentGames = 'recentGames';
const String prefsKeyFavoriteCharactersByGame = 'favoriteCharactersByGame';
const String prefsKeyRecentCharactersByGame = 'recentCharactersByGame';
const String prefsKeyAutoSyncEnabled = 'autoSyncEnabled';
const String prefsKeyPendingExternalSyncSnapshot =
    'pendingExternalSyncSnapshot';
const String smashCoverMale = 'male';
const String smashCoverFemale = 'female';

class CharacterUsageStats {
  final int partidas;
  final int vitorias;
  final int pdl;
  final DateTime? ultimaPartida;

  const CharacterUsageStats({
    this.partidas = 0,
    this.vitorias = 0,
    this.pdl = 0,
    this.ultimaPartida,
  });

  bool get temPartidas => partidas > 0;

  double get winrate {
    if (partidas == 0) return 0;
    return (vitorias / partidas) * 100;
  }

  CharacterUsageStats adicionar(PartidaRegistrada partida) {
    final bool venceu = resultadoEhVitoria(partida.resultado);
    final DateTime? dataMaisRecente =
        ultimaPartida == null || partida.data.isAfter(ultimaPartida!)
        ? partida.data
        : ultimaPartida;

    return CharacterUsageStats(
      partidas: partidas + 1,
      vitorias: vitorias + (venceu ? 1 : 0),
      pdl: pdl + partida.pdlGerado,
      ultimaPartida: dataMaisRecente,
    );
  }
}

class GameUsageStats {
  final int partidas;
  final DateTime? ultimaPartida;

  const GameUsageStats({this.partidas = 0, this.ultimaPartida});

  bool get temPartidas => partidas > 0;

  GameUsageStats adicionar(PartidaRegistrada partida) {
    final DateTime? dataMaisRecente =
        ultimaPartida == null || partida.data.isAfter(ultimaPartida!)
        ? partida.data
        : ultimaPartida;

    return GameUsageStats(
      partidas: partidas + 1,
      ultimaPartida: dataMaisRecente,
    );
  }
}

enum GameRegisterType {
  platformFighter,
  twoDFighter,
  twoDAssistFighter,
  animeFighter,
  snkFighter,
  threeDFighter,
  tagFighter,
  tagFighter2v2,
  teamFighter,
  teamOrderFighter,
}

enum SyncStatus {
  localOnly,
  pendingSync,
  syncing,
  synced,
  syncError,
  deletedPendingSync,
}

enum SyncQueueStatus { pending, syncing, done, error }

enum SyncOperation { create, update, delete }

enum SyncEntityType {
  match,
  gameProfile,
  characterProgress,
  preference,
  favorite,
  selectedCharacter,
  selectedTeam,
}

extension SyncStatusData on SyncStatus {
  String get id {
    return switch (this) {
      SyncStatus.localOnly => 'localOnly',
      SyncStatus.pendingSync => 'pendingSync',
      SyncStatus.syncing => 'syncing',
      SyncStatus.synced => 'synced',
      SyncStatus.syncError => 'syncError',
      SyncStatus.deletedPendingSync => 'deletedPendingSync',
    };
  }

  String get label {
    return switch (this) {
      SyncStatus.localOnly => 'Somente local',
      SyncStatus.pendingSync => 'Sincronizacao pendente',
      SyncStatus.syncing => 'Sincronizando',
      SyncStatus.synced => 'Sincronizado',
      SyncStatus.syncError => 'Erro de sync',
      SyncStatus.deletedPendingSync => 'Exclusao pendente',
    };
  }

  static SyncStatus fromJson(dynamic value) {
    final String id = value?.toString() ?? '';
    for (final SyncStatus status in SyncStatus.values) {
      if (status.id == id || status.name == id) return status;
    }
    return SyncStatus.localOnly;
  }
}

extension SyncQueueStatusData on SyncQueueStatus {
  String get id {
    return switch (this) {
      SyncQueueStatus.pending => 'pending',
      SyncQueueStatus.syncing => 'syncing',
      SyncQueueStatus.done => 'done',
      SyncQueueStatus.error => 'error',
    };
  }

  static SyncQueueStatus fromJson(dynamic value) {
    final String id = value?.toString() ?? '';
    for (final SyncQueueStatus status in SyncQueueStatus.values) {
      if (status.id == id || status.name == id) return status;
    }
    return SyncQueueStatus.pending;
  }
}

extension SyncOperationData on SyncOperation {
  String get id {
    return switch (this) {
      SyncOperation.create => 'create',
      SyncOperation.update => 'update',
      SyncOperation.delete => 'delete',
    };
  }

  static SyncOperation fromJson(dynamic value) {
    final String id = value?.toString() ?? '';
    for (final SyncOperation operation in SyncOperation.values) {
      if (operation.id == id || operation.name == id) return operation;
    }
    return SyncOperation.update;
  }
}

extension SyncEntityTypeData on SyncEntityType {
  String get id {
    return switch (this) {
      SyncEntityType.match => 'match',
      SyncEntityType.gameProfile => 'gameProfile',
      SyncEntityType.characterProgress => 'characterProgress',
      SyncEntityType.preference => 'preference',
      SyncEntityType.favorite => 'favorite',
      SyncEntityType.selectedCharacter => 'selectedCharacter',
      SyncEntityType.selectedTeam => 'selectedTeam',
    };
  }

  static SyncEntityType fromJson(dynamic value) {
    final String id = value?.toString() ?? '';
    for (final SyncEntityType type in SyncEntityType.values) {
      if (type.id == id || type.name == id) return type;
    }
    return SyncEntityType.match;
  }
}

class LocalSyncRecord {
  final String id;
  final SyncEntityType entityType;
  final String entityId;
  final String? userId;
  final String deviceId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final SyncStatus syncStatus;
  final DateTime? lastSyncAt;
  final String syncErrorMessage;

  const LocalSyncRecord({
    required this.id,
    required this.entityType,
    required this.entityId,
    this.userId,
    required this.deviceId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.syncStatus = SyncStatus.localOnly,
    this.lastSyncAt,
    this.syncErrorMessage = '',
  });

  LocalSyncRecord copyWith({
    String? id,
    SyncEntityType? entityType,
    String? entityId,
    String? userId,
    String? deviceId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    SyncStatus? syncStatus,
    DateTime? lastSyncAt,
    bool clearLastSyncAt = false,
    String? syncErrorMessage,
  }) {
    return LocalSyncRecord(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      userId: userId ?? this.userId,
      deviceId: deviceId ?? this.deviceId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncAt: clearLastSyncAt ? null : lastSyncAt ?? this.lastSyncAt,
      syncErrorMessage: syncErrorMessage ?? this.syncErrorMessage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entityType': entityType.id,
      'entityId': entityId,
      'userId': userId,
      'deviceId': deviceId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'syncStatus': syncStatus.id,
      'lastSyncAt': lastSyncAt?.toIso8601String(),
      'syncErrorMessage': syncErrorMessage,
    };
  }

  factory LocalSyncRecord.fromJson(Map<String, dynamic> json) {
    final DateTime now = DateTime.now();
    return LocalSyncRecord(
      id: json['id']?.toString() ?? gerarIdLocal('sync_record'),
      entityType: SyncEntityTypeData.fromJson(json['entityType']),
      entityId: json['entityId']?.toString() ?? '',
      userId: json['userId']?.toString(),
      deviceId: json['deviceId']?.toString() ?? '',
      createdAt: LocalSyncRepository.dateTimeFromJson(json['createdAt']) ?? now,
      updatedAt: LocalSyncRepository.dateTimeFromJson(json['updatedAt']) ?? now,
      deletedAt: LocalSyncRepository.dateTimeFromJson(json['deletedAt']),
      syncStatus: SyncStatusData.fromJson(json['syncStatus']),
      lastSyncAt: LocalSyncRepository.dateTimeFromJson(json['lastSyncAt']),
      syncErrorMessage: json['syncErrorMessage']?.toString() ?? '',
    );
  }
}

class SyncQueueItem {
  final String id;
  final SyncEntityType entityType;
  final String entityId;
  final SyncOperation operation;
  final SyncQueueStatus status;
  final int attempts;
  final DateTime? lastAttemptAt;
  final String errorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SyncQueueItem({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    this.status = SyncQueueStatus.pending,
    this.attempts = 0,
    this.lastAttemptAt,
    this.errorMessage = '',
    required this.createdAt,
    required this.updatedAt,
  });

  SyncQueueItem copyWith({
    String? id,
    SyncEntityType? entityType,
    String? entityId,
    SyncOperation? operation,
    SyncQueueStatus? status,
    int? attempts,
    DateTime? lastAttemptAt,
    bool clearLastAttemptAt = false,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SyncQueueItem(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      lastAttemptAt: clearLastAttemptAt
          ? null
          : lastAttemptAt ?? this.lastAttemptAt,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entityType': entityType.id,
      'entityId': entityId,
      'operation': operation.id,
      'status': status.id,
      'attempts': attempts,
      'lastAttemptAt': lastAttemptAt?.toIso8601String(),
      'errorMessage': errorMessage,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory SyncQueueItem.fromJson(Map<String, dynamic> json) {
    final DateTime now = DateTime.now();
    return SyncQueueItem(
      id: json['id']?.toString() ?? gerarIdLocal('sync_queue'),
      entityType: SyncEntityTypeData.fromJson(json['entityType']),
      entityId: json['entityId']?.toString() ?? '',
      operation: SyncOperationData.fromJson(json['operation']),
      status: SyncQueueStatusData.fromJson(json['status']),
      attempts: json['attempts'] is int ? json['attempts'] as int : 0,
      lastAttemptAt: LocalSyncRepository.dateTimeFromJson(
        json['lastAttemptAt'],
      ),
      errorMessage: json['errorMessage']?.toString() ?? '',
      createdAt: LocalSyncRepository.dateTimeFromJson(json['createdAt']) ?? now,
      updatedAt: LocalSyncRepository.dateTimeFromJson(json['updatedAt']) ?? now,
    );
  }
}

class HistoricoAlteracaoSync {
  final SyncOperation operation;
  final PartidaRegistrada original;
  final PartidaRegistrada? atualizada;

  const HistoricoAlteracaoSync({
    required this.operation,
    required this.original,
    this.atualizada,
  });
}

const List<String> jogosDisponiveis = [
  jogoSmashUltimate,
  jogoStreetFighter6,
  jogoMortalKombat1,
  'Avatar Legends: The Fighting Game',
  jogoGuiltyGearStrive,
  jogoKofXV,
  jogoInvincibleVs,
  jogoTekken8,
  jogo2Xko,
  jogoRivalsOfAether2,
  jogoFatalFury,
];

const List<String> jogosArquivados = ['Dragon Ball FighterZ'];

const List<String> jogosDesativados = [];

bool jogoEstaAtivo(String jogo) => !jogosDesativados.contains(jogo);

class PartidaRegistrada {
  final String id;
  final String? userId;
  final String deviceId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final SyncStatus syncStatus;
  final DateTime? lastSyncAt;
  final String syncErrorMessage;
  final String jogo;
  final String personagemJogador;
  final String nickAdversario;
  final String personagemAdversario;
  final String stage;
  final String resultado;
  final int stocks;
  final int porcentagem;
  final String formaDeKill;
  final String formaDeMorte;
  final String observacoes;
  final int pdlGerado;
  final DateTime data;
  final String meuTimeSlot1;
  final String meuTimeSlot2;
  final String meuTimeSlot3;
  final String timeAdversarioSlot1;
  final String timeAdversarioSlot2;
  final String timeAdversarioSlot3;
  final String personagemDestaque;
  final String primeiroDerrotado;
  final String personagemInimigoProblema;
  final String condicaoVitoria;
  final String motivoDerrota;
  final String round1Resultado;
  final String round2Resultado;
  final String round3Resultado;
  final String placarRounds;

  const PartidaRegistrada({
    this.id = '',
    this.userId,
    this.deviceId = '',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.deletedAt,
    this.syncStatus = SyncStatus.localOnly,
    this.lastSyncAt,
    this.syncErrorMessage = '',
    this.jogo = '',
    required this.personagemJogador,
    required this.nickAdversario,
    required this.personagemAdversario,
    required this.stage,
    required this.resultado,
    required this.stocks,
    required this.porcentagem,
    required this.formaDeKill,
    required this.formaDeMorte,
    required this.observacoes,
    required this.pdlGerado,
    required this.data,
    this.meuTimeSlot1 = '',
    this.meuTimeSlot2 = '',
    this.meuTimeSlot3 = '',
    this.timeAdversarioSlot1 = '',
    this.timeAdversarioSlot2 = '',
    this.timeAdversarioSlot3 = '',
    this.personagemDestaque = '',
    this.primeiroDerrotado = '',
    this.personagemInimigoProblema = '',
    this.condicaoVitoria = '',
    this.motivoDerrota = '',
    this.round1Resultado = '',
    this.round2Resultado = '',
    this.round3Resultado = '',
    this.placarRounds = '',
  }) : createdAt = createdAt ?? data,
       updatedAt = updatedAt ?? data;

  String get syncId {
    return id.trim().isNotEmpty ? id : '';
  }

  bool get deletadaLocalmente {
    return deletedAt != null || syncStatus == SyncStatus.deletedPendingSync;
  }

  List<String> get meuTime {
    return [
      meuTimeSlot1,
      meuTimeSlot2,
      meuTimeSlot3,
    ].map((nome) => nome.trim()).where((nome) => nome.isNotEmpty).toList();
  }

  List<String> get timeAdversario {
    return [
      timeAdversarioSlot1,
      timeAdversarioSlot2,
      timeAdversarioSlot3,
    ].map((nome) => nome.trim()).where((nome) => nome.isNotEmpty).toList();
  }

  bool get isKofXV {
    return jogo == jogoKofXV;
  }

  bool get isInvincible {
    return jogo == jogoInvincibleVs ||
        (jogo.isEmpty && (meuTime.length == 3 || timeAdversario.length == 3));
  }

  bool get isStreetFighter {
    return jogo == jogoStreetFighter6 ||
        round1Resultado.trim().isNotEmpty ||
        round2Resultado.trim().isNotEmpty ||
        round3Resultado.trim().isNotEmpty;
  }

  bool get isMortalKombat1 {
    return jogo == jogoMortalKombat1;
  }

  bool get isGuiltyGear {
    return jogo == jogoGuiltyGearStrive;
  }

  bool get isRivalsOfAether2 {
    return jogo == jogoRivalsOfAether2;
  }

  bool get isTekken8 {
    return jogo == jogoTekken8;
  }

  bool get isFatalFury {
    return jogo == jogoFatalFury;
  }

  bool get is2XKO {
    return jogo == jogo2Xko;
  }

  List<String> get roundsStreetFighter {
    return [
      round1Resultado,
      round2Resultado,
      round3Resultado,
    ].map((round) => round.trim()).where((round) => round.isNotEmpty).toList();
  }

  int get roundsVencidos {
    return roundsStreetFighter.where(resultadoEhVitoria).length;
  }

  int get roundsPerdidos {
    return roundsStreetFighter.where(resultadoEhDerrota).length;
  }

  bool get chegouAoRound3 {
    return round3Resultado.trim().isNotEmpty;
  }

  String get placarStreetFighter {
    final String placarSalvo = placarRounds.trim();
    if (placarSalvo.isNotEmpty) return placarSalvo;

    if (roundsStreetFighter.isEmpty) return stage;
    return '${roundsVencidos}x$roundsPerdidos';
  }

  String get meuTimeTexto {
    final List<String> time = meuTime;
    return time.isEmpty ? personagemJogador : time.join(' / ');
  }

  String get timeAdversarioTexto {
    final List<String> time = timeAdversario;
    return time.isEmpty ? personagemAdversario : time.join(' / ');
  }

  String get analiseResultado {
    if (resultadoEhVitoria(resultado) && condicaoVitoria.trim().isNotEmpty) {
      return condicaoVitoria;
    }

    if (resultadoEhDerrota(resultado) && motivoDerrota.trim().isNotEmpty) {
      return motivoDerrota;
    }

    return resultado;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'deviceId': deviceId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'syncStatus': syncStatus.id,
      'lastSyncAt': lastSyncAt?.toIso8601String(),
      'syncErrorMessage': syncErrorMessage,
      'jogo': jogo,
      'personagemJogador': personagemJogador,
      'nickAdversario': nickAdversario,
      'personagemAdversario': personagemAdversario,
      'stage': stage,
      'resultado': resultado,
      'stocks': stocks,
      'porcentagem': porcentagem,
      'formaDeKill': formaDeKill,
      'formaDeMorte': formaDeMorte,
      'observacoes': observacoes,
      'pdlGerado': pdlGerado,
      'data': data.toIso8601String(),
      'meuTimeSlot1': meuTimeSlot1,
      'meuTimeSlot2': meuTimeSlot2,
      'meuTimeSlot3': meuTimeSlot3,
      'timeAdversarioSlot1': timeAdversarioSlot1,
      'timeAdversarioSlot2': timeAdversarioSlot2,
      'timeAdversarioSlot3': timeAdversarioSlot3,
      'personagemDestaque': personagemDestaque,
      'primeiroDerrotado': primeiroDerrotado,
      'personagemInimigoProblema': personagemInimigoProblema,
      'condicaoVitoria': condicaoVitoria,
      'motivoDerrota': motivoDerrota,
      'round1Resultado': round1Resultado,
      'round2Resultado': round2Resultado,
      'round3Resultado': round3Resultado,
      'placarRounds': placarRounds,
    };
  }

  PartidaRegistrada copyWithSync({
    String? id,
    String? userId,
    bool clearUserId = false,
    String? deviceId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    SyncStatus? syncStatus,
    DateTime? lastSyncAt,
    bool clearLastSyncAt = false,
    String? syncErrorMessage,
  }) {
    return PartidaRegistrada(
      id: id ?? this.id,
      userId: clearUserId ? null : userId ?? this.userId,
      deviceId: deviceId ?? this.deviceId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncAt: clearLastSyncAt ? null : lastSyncAt ?? this.lastSyncAt,
      syncErrorMessage: syncErrorMessage ?? this.syncErrorMessage,
      jogo: jogo,
      personagemJogador: personagemJogador,
      nickAdversario: nickAdversario,
      personagemAdversario: personagemAdversario,
      stage: stage,
      resultado: resultado,
      stocks: stocks,
      porcentagem: porcentagem,
      formaDeKill: formaDeKill,
      formaDeMorte: formaDeMorte,
      observacoes: observacoes,
      pdlGerado: pdlGerado,
      data: data,
      meuTimeSlot1: meuTimeSlot1,
      meuTimeSlot2: meuTimeSlot2,
      meuTimeSlot3: meuTimeSlot3,
      timeAdversarioSlot1: timeAdversarioSlot1,
      timeAdversarioSlot2: timeAdversarioSlot2,
      timeAdversarioSlot3: timeAdversarioSlot3,
      personagemDestaque: personagemDestaque,
      primeiroDerrotado: primeiroDerrotado,
      personagemInimigoProblema: personagemInimigoProblema,
      condicaoVitoria: condicaoVitoria,
      motivoDerrota: motivoDerrota,
      round1Resultado: round1Resultado,
      round2Resultado: round2Resultado,
      round3Resultado: round3Resultado,
      placarRounds: placarRounds,
    );
  }

  PartidaRegistrada copyWithSyncFrom(PartidaRegistrada original) {
    return copyWithSync(
      id: original.id,
      userId: original.userId,
      deviceId: original.deviceId,
      createdAt: original.createdAt,
      updatedAt: original.updatedAt,
      deletedAt: original.deletedAt,
      syncStatus: original.syncStatus,
      lastSyncAt: original.lastSyncAt,
      syncErrorMessage: original.syncErrorMessage,
    );
  }

  factory PartidaRegistrada.fromJson(Map<String, dynamic> json) {
    final DateTime dataPartida =
        DateTime.tryParse(json['data']?.toString() ?? '') ?? DateTime.now();
    return PartidaRegistrada(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString(),
      deviceId: json['deviceId']?.toString() ?? '',
      createdAt:
          LocalSyncRepository.dateTimeFromJson(json['createdAt']) ??
          dataPartida,
      updatedAt:
          LocalSyncRepository.dateTimeFromJson(json['updatedAt']) ??
          dataPartida,
      deletedAt: LocalSyncRepository.dateTimeFromJson(json['deletedAt']),
      syncStatus: SyncStatusData.fromJson(json['syncStatus']),
      lastSyncAt: LocalSyncRepository.dateTimeFromJson(json['lastSyncAt']),
      syncErrorMessage: json['syncErrorMessage']?.toString() ?? '',
      jogo: json['jogo'] ?? json['game'] ?? '',
      personagemJogador: normalizarNomePersonagem(
        json['personagemJogador'] ?? '',
      ),
      nickAdversario: corrigirTextoLegado(json['nickAdversario'] ?? 'Sem nick'),
      personagemAdversario: normalizarNomePersonagem(
        json['personagemAdversario'] ?? '',
      ),
      stage: corrigirTextoLegado(json['stage'] ?? ''),
      resultado: corrigirTextoLegado(json['resultado'] ?? ''),
      stocks: json['stocks'] ?? 1,
      porcentagem: json['porcentagem'] ?? 0,
      formaDeKill: corrigirTextoLegado(json['formaDeKill'] ?? 'Sem dados'),
      formaDeMorte: corrigirTextoLegado(json['formaDeMorte'] ?? 'Sem dados'),
      observacoes: corrigirTextoLegado(json['observacoes'] ?? ''),
      pdlGerado: json['pdlGerado'] ?? 0,
      data: dataPartida,
      meuTimeSlot1: normalizarNomePersonagem(
        json['meuTimeSlot1'] ?? json['personagem_slot_1'] ?? '',
      ),
      meuTimeSlot2: normalizarNomePersonagem(
        json['meuTimeSlot2'] ?? json['personagem_slot_2'] ?? '',
      ),
      meuTimeSlot3: normalizarNomePersonagem(
        json['meuTimeSlot3'] ?? json['personagem_slot_3'] ?? '',
      ),
      timeAdversarioSlot1: normalizarNomePersonagem(
        json['timeAdversarioSlot1'] ??
            json['adversario_personagem_slot_1'] ??
            '',
      ),
      timeAdversarioSlot2: normalizarNomePersonagem(
        json['timeAdversarioSlot2'] ??
            json['adversario_personagem_slot_2'] ??
            '',
      ),
      timeAdversarioSlot3: normalizarNomePersonagem(
        json['timeAdversarioSlot3'] ??
            json['adversario_personagem_slot_3'] ??
            '',
      ),
      personagemDestaque: normalizarNomePersonagem(
        json['personagemDestaque'] ?? json['personagem_destaque'] ?? '',
      ),
      primeiroDerrotado: normalizarNomePersonagem(
        json['primeiroDerrotado'] ?? json['primeiro_derrotado'] ?? '',
      ),
      personagemInimigoProblema: normalizarNomePersonagem(
        json['personagemInimigoProblema'] ??
            json['personagem_inimigo_problema'] ??
            '',
      ),
      condicaoVitoria: corrigirTextoLegado(
        json['condicaoVitoria'] ?? json['condicao_vitoria'] ?? '',
      ),
      motivoDerrota: corrigirTextoLegado(
        json['motivoDerrota'] ?? json['motivo_derrota'] ?? '',
      ),
      round1Resultado: corrigirTextoLegado(
        json['round1Resultado'] ?? json['round_1_resultado'] ?? '',
      ),
      round2Resultado: corrigirTextoLegado(
        json['round2Resultado'] ?? json['round_2_resultado'] ?? '',
      ),
      round3Resultado: corrigirTextoLegado(
        json['round3Resultado'] ?? json['round_3_resultado'] ?? '',
      ),
      placarRounds: corrigirTextoLegado(
        json['placarRounds'] ?? json['placar_rounds'] ?? '',
      ),
    );
  }
}

class TimePrincipalInvincible {
  final String slot1;
  final String slot2;
  final String slot3;

  const TimePrincipalInvincible({
    required this.slot1,
    required this.slot2,
    required this.slot3,
  });

  List<String> get personagens {
    return [
      slot1,
      slot2,
      slot3,
    ].map((nome) => nome.trim()).where((nome) => nome.isNotEmpty).toList();
  }

  bool get completo {
    return personagens.length == 3;
  }

  String get texto {
    return completo
        ? personagens.join(' / ')
        : 'Nenhum time principal definido';
  }

  bool mesmaComposicao(List<String> time) {
    final List<String> meuTime = personagens;
    if (meuTime.length != 3 || time.length != 3) return false;

    for (int index = 0; index < meuTime.length; index++) {
      if (meuTime[index] != time[index]) return false;
    }

    return true;
  }

  Map<String, dynamic> toJson() {
    return {'slot1': slot1, 'slot2': slot2, 'slot3': slot3};
  }

  factory TimePrincipalInvincible.fromJson(Map<String, dynamic> json) {
    return TimePrincipalInvincible(
      slot1: normalizarNomePersonagem(json['slot1'] ?? ''),
      slot2: normalizarNomePersonagem(json['slot2'] ?? ''),
      slot3: normalizarNomePersonagem(json['slot3'] ?? ''),
    );
  }
}

const TimePrincipalInvincible timePrincipalInvincibleVazio =
    TimePrincipalInvincible(slot1: '', slot2: '', slot3: '');

class TimePrincipal2XKO {
  final String point;
  final String assist;

  const TimePrincipal2XKO({required this.point, required this.assist});

  List<String> get personagens {
    return [
      point,
      assist,
    ].map((nome) => nome.trim()).where((nome) => nome.isNotEmpty).toList();
  }

  bool get completo {
    return personagens.length == 2;
  }

  String get key {
    return completo ? chaveDupla2XKO(point, assist) : '';
  }

  String get texto {
    return completo
        ? 'Point: $point / Assist: $assist'
        : 'Nenhuma dupla definida';
  }

  bool mesmaComposicao(List<String> time) {
    final List<String> minhaDupla = personagens;
    if (minhaDupla.length != 2 || time.length < 2) return false;

    return minhaDupla[0] == time[0] && minhaDupla[1] == time[1];
  }

  Map<String, dynamic> toJson() {
    return {'point': point, 'assist': assist};
  }

  factory TimePrincipal2XKO.fromJson(Map<String, dynamic> json) {
    return TimePrincipal2XKO(
      point: normalizarNomePersonagem(json['point'] ?? json['slot1'] ?? ''),
      assist: normalizarNomePersonagem(json['assist'] ?? json['slot2'] ?? ''),
    );
  }
}

const TimePrincipal2XKO timePrincipal2XKOVazio = TimePrincipal2XKO(
  point: '',
  assist: '',
);

class TimePrincipalKofXV {
  final String point;
  final String mid;
  final String anchor;

  const TimePrincipalKofXV({
    required this.point,
    required this.mid,
    required this.anchor,
  });

  List<String> get personagens {
    return [
      point,
      mid,
      anchor,
    ].map((nome) => nome.trim()).where((nome) => nome.isNotEmpty).toList();
  }

  bool get completo {
    return personagens.length == 3;
  }

  String get key {
    return completo ? chaveTimeKofXV(point, mid, anchor) : '';
  }

  String get texto {
    return completo
        ? 'Point: $point / Mid: $mid / Anchor: $anchor'
        : 'Nenhum time definido';
  }

  bool mesmaComposicao(List<String> time) {
    final List<String> meuTime = personagens;
    if (meuTime.length != 3 || time.length < 3) return false;

    for (int index = 0; index < meuTime.length; index++) {
      if (meuTime[index] != time[index]) return false;
    }

    return true;
  }

  Map<String, dynamic> toJson() {
    return {'point': point, 'mid': mid, 'anchor': anchor};
  }

  factory TimePrincipalKofXV.fromJson(Map<String, dynamic> json) {
    return TimePrincipalKofXV(
      point: normalizarNomePersonagem(json['point'] ?? json['slot1'] ?? ''),
      mid: normalizarNomePersonagem(json['mid'] ?? json['slot2'] ?? ''),
      anchor: normalizarNomePersonagem(json['anchor'] ?? json['slot3'] ?? ''),
    );
  }
}

const TimePrincipalKofXV timePrincipalKofVazio = TimePrincipalKofXV(
  point: '',
  mid: '',
  anchor: '',
);

class FrequenciaItem {
  final String nome;
  final int quantidade;

  const FrequenciaItem({required this.nome, required this.quantidade});
}

class PlayerResumo {
  final String nick;
  final int total;
  final int vitorias;
  final int derrotas;

  const PlayerResumo({
    required this.nick,
    required this.total,
    required this.vitorias,
    required this.derrotas,
  });
}

class MatchupResumo {
  final String personagemAdversario;
  final int total;
  final int vitorias;
  final int derrotas;
  final int saldoPdl;
  final String killMaisComum;
  final String morteMaisComum;
  final String stageMaisJogado;

  const MatchupResumo({
    required this.personagemAdversario,
    required this.total,
    required this.vitorias,
    required this.derrotas,
    required this.saldoPdl,
    required this.killMaisComum,
    required this.morteMaisComum,
    required this.stageMaisJogado,
  });

  double get winrate {
    if (total == 0) return 0;
    return (vitorias / total) * 100;
  }
}

class ResultadoDetalhesPartida {
  final String acao;
  final PartidaRegistrada? partidaEditada;

  const ResultadoDetalhesPartida.apagar()
    : acao = 'apagar',
      partidaEditada = null;

  const ResultadoDetalhesPartida.editar(this.partidaEditada) : acao = 'editar';
}
