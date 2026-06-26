part of '../../main.dart';

String _textoPorCodigos(List<int> codigos) {
  return String.fromCharCodes(codigos);
}

String corrigirTextoLegado(String texto) {
  String corrigido = texto;

  final List<MapEntry<String, String>> substituicoes = [
    MapEntry(
      _textoPorCodigos([0x00C3, 0x0192, 0x00C2]),
      _textoPorCodigos([0x00C3]),
    ),
    MapEntry(
      _textoPorCodigos([0x00C3, 0x0192, 0x00C5, 0x00A0]),
      _textoPorCodigos([0x00C3, 0x0160]),
    ),
    MapEntry(
      _textoPorCodigos([0x00C3, 0x0192, 0x00E2, 0x20AC, 0x0161]),
      _textoPorCodigos([0x00C2]),
    ),
    MapEntry(_textoPorCodigos([0x00C3, 0x201A]), _textoPorCodigos([0x00C2])),
    MapEntry(
      _textoPorCodigos([0x00E2, 0x20AC, 0x00A2]),
      _textoPorCodigos([0x2022]),
    ),
    MapEntry(
      _textoPorCodigos([0x00E2, 0x20AC, 0x201D]),
      _textoPorCodigos([0x2014]),
    ),
  ];

  for (final substituicao in substituicoes) {
    corrigido = corrigido.replaceAll(substituicao.key, substituicao.value);
  }

  for (int tentativa = 0; tentativa < 2; tentativa++) {
    try {
      final String proximo = utf8.decode(
        latin1.encode(corrigido),
        allowMalformed: false,
      );

      if (proximo == corrigido) break;
      corrigido = proximo;
    } catch (_) {
      break;
    }
  }

  return corrigido;
}

bool resultadoEhVitoria(String resultado) {
  return corrigirTextoLegado(resultado) == 'Vitória';
}

bool resultadoEhDerrota(String resultado) {
  return corrigirTextoLegado(resultado) == 'Derrota';
}

String calcularRank(int pdl) {
  if (pdl < 100) return 'Starter V';
  if (pdl < 200) return 'Starter IV';
  if (pdl < 300) return 'Starter III';
  if (pdl < 400) return 'Starter II';
  if (pdl < 500) return 'Starter';

  if (pdl < 650) return 'For Fun V';
  if (pdl < 800) return 'For Fun IV';
  if (pdl < 950) return 'For Fun III';
  if (pdl < 1100) return 'For Fun II';
  if (pdl < 1250) return 'For Fun';

  if (pdl < 1450) return 'Quick Play V';
  if (pdl < 1650) return 'Quick Play IV';
  if (pdl < 1850) return 'Quick Play III';
  if (pdl < 2050) return 'Quick Play II';
  if (pdl < 2250) return 'Quick Play';

  if (pdl < 2500) return 'Brawl V';
  if (pdl < 2750) return 'Brawl IV';
  if (pdl < 3000) return 'Brawl III';
  if (pdl < 3250) return 'Brawl II';
  if (pdl < 3500) return 'Brawl';

  if (pdl < 3800) return 'For Glory V';
  if (pdl < 4100) return 'For Glory IV';
  if (pdl < 4400) return 'For Glory III';
  if (pdl < 4700) return 'For Glory II';
  if (pdl < 5000) return 'For Glory';

  if (pdl < 5400) return 'Melee V';
  if (pdl < 5800) return 'Melee IV';
  if (pdl < 6200) return 'Melee III';
  if (pdl < 6600) return 'Melee II';
  if (pdl < 7000) return 'Melee';

  return 'Elite Smash';
}

bool usaLp(String jogo) {
  return jogo == jogoInvincibleVs;
}

bool usaRankStreetFighter(String jogo) {
  return jogo == jogoStreetFighter6;
}

String labelPontosRank(String jogo) {
  return usaLp(jogo) ? 'LP' : 'PDL';
}

String rankInicialDoJogo(String jogo) {
  if (usaLp(jogo)) return 'New Blood IV';
  if (usaRankStreetFighter(jogo)) return 'Rookie I';
  return 'Starter V';
}

String calcularRankInvincible(int lp) {
  const List<String> ranks = [
    'New Blood',
    'Rookie',
    'Bronze',
    'Silver',
    'Gold',
    'Platinum',
    'Diamond',
    'Superhero',
  ];
  const List<String> divisoes = ['IV', 'III', 'II', 'I'];

  final int lpCorrigido = lp < 0 ? 0 : lp;
  final int indiceDivisao = lpCorrigido ~/ 100;

  if (indiceDivisao >= ranks.length * divisoes.length) {
    return 'Guardian of the Globe';
  }

  final String rank = ranks[indiceDivisao ~/ divisoes.length];
  final String divisao = divisoes[indiceDivisao % divisoes.length];

  return '$rank $divisao';
}

String calcularRankStreetFighter(int pdl) {
  const List<String> ranks = [
    'Rookie',
    'Iron',
    'Bronze',
    'Silver',
    'Gold',
    'Platinum',
    'Diamond',
  ];
  const List<String> divisoes = ['I', 'II', 'III', 'IV', 'V'];

  final int pdlCorrigido = pdl < 0 ? 0 : pdl;
  final int indiceDivisao = pdlCorrigido ~/ 120;

  if (indiceDivisao >= ranks.length * divisoes.length) {
    return 'Master';
  }

  final String rank = ranks[indiceDivisao ~/ divisoes.length];
  final String divisao = divisoes[indiceDivisao % divisoes.length];

  return '$rank $divisao';
}

String calcularRankDoJogo(String jogo, int pontos) {
  if (usaLp(jogo)) return calcularRankInvincible(pontos);
  if (usaRankStreetFighter(jogo)) return calcularRankStreetFighter(pontos);
  return calcularRank(pontos);
}

bool partidaPertenceAoJogo(PartidaRegistrada partida, String jogo) {
  if (jogo == jogoInvincibleVs) {
    return partida.isInvincible;
  }

  if (partida.isInvincible) {
    return false;
  }

  if (jogo == jogoStreetFighter6) {
    return partida.isStreetFighter;
  }

  if (partida.isStreetFighter) {
    return false;
  }

  if (partida.jogo.isEmpty) {
    return jogo == 'Super Smash Bros. Ultimate';
  }

  return partida.jogo == jogo;
}

bool partidaPertenceAoContextoAtual(
  PartidaRegistrada partida, {
  required String jogo,
  String personagemAtual = '',
  TimePrincipalInvincible timePrincipalInvincible =
      timePrincipalInvincibleVazio,
}) {
  if (!partidaPertenceAoJogo(partida, jogo)) {
    return false;
  }

  if (jogo == jogoInvincibleVs) {
    return partida.isInvincible &&
        timePrincipalInvincible.completo &&
        timePrincipalInvincible.mesmaComposicao(partida.meuTime);
  }

  final String personagem = personagemAtual.trim();
  if (personagem.isEmpty) return false;

  return partida.personagemJogador == personagem;
}

List<PartidaRegistrada> filtrarHistoricoPorContextoAtual(
  List<PartidaRegistrada> historico, {
  required String jogo,
  String personagemAtual = '',
  TimePrincipalInvincible timePrincipalInvincible =
      timePrincipalInvincibleVazio,
}) {
  return historico
      .where(
        (partida) => partidaPertenceAoContextoAtual(
          partida,
          jogo: jogo,
          personagemAtual: personagemAtual,
          timePrincipalInvincible: timePrincipalInvincible,
        ),
      )
      .toList();
}

int calcularLpInvincible({
  required String resultado,
  required String condicaoVitoria,
  required String motivoDerrota,
}) {
  if (resultadoEhVitoria(resultado)) {
    int lp = 24;

    switch (corrigirTextoLegado(condicaoVitoria)) {
      case 'Perfeito / Quase Perfeito':
        lp += 8;
        break;
      case 'Com Personagem Âncora':
      case 'Virada':
        lp += 6;
        break;
      case 'Confirmação com Assist':
      case 'Controle de Espaço':
        lp += 4;
        break;
      case 'Combo':
      case 'Ultimate':
      case 'Pressão':
      case 'Mix-up':
      case 'Whiff Punish':
      case 'Anti-air':
      case 'Punição':
        lp += 3;
        break;
      case 'Tempo Esgotado':
        lp += 1;
        break;
    }

    return lp;
  }

  int lp = -18;

  switch (corrigirTextoLegado(motivoDerrota)) {
    case 'Erro de Tag':
    case 'Erro Meu / Miss Input':
    case 'Drop de Combo':
      lp -= 6;
      break;
    case 'Personagem Caiu Cedo':
    case 'Não Consegui Sair da Pressão':
    case 'Pressão no Canto':
      lp -= 5;
      break;
    case 'Assist Mal Usado':
    case 'Erro de Defesa':
    case 'Falta de Controle de Espaço':
      lp -= 4;
      break;
    case 'Comeback do Adversário':
    case 'Perdi no Mix-up':
    case 'Tomei Whiff Punish':
    case 'Tomei Anti-air':
    case 'Punição':
    case 'Ultimate':
      lp -= 3;
      break;
    case 'Tempo Esgotado':
      lp -= 1;
      break;
  }

  return lp;
}

int bonusPorKill(String formaDeKill) {
  switch (formaDeKill) {
    case 'Kill confirm':
      return 4;
    case 'Edgeguard':
      return 4;
    case 'Ledgetrap':
      return 3;
    case 'Read':
      return 5;
    case 'Punish':
      return 3;
    case 'F-smash':
    case 'Up smash':
    case 'Down smash':
    case 'Shield break':
      return 4;
    case 'Back throw':
    case 'Forward throw':
    case 'Up throw':
    case 'Down throw':
    case 'Bair':
    case 'Up air':
    case 'Down air':
      return 3;
    case 'F-tilt':
    case 'Up tilt':
    case 'Down tilt':
    case 'Fair':
    case 'Nair':
    case 'Dash attack':
    case 'Side B':
    case 'Up B':
    case 'Down B':
    case 'Neutral B':
      return 2;
    case 'Jab':
    case 'Grab':
      return 1;
    case 'Magia':
      return 3;
    case 'Spike':
      return 5;
    case 'Gimp':
      return 4;
    case 'Outro':
      return 1;
    case 'Não matou':
      return 0;
    default:
      return 0;
  }
}

int penalidadePorMorte(String formaDeMorte) {
  switch (formaDeMorte) {
    case 'SD':
      return -8;
    case 'Recovery errado':
      return -6;
    case 'Panic option':
      return -5;
    case 'Punish sofrido':
      return -4;
    case 'Edgeguard sofrido':
      return -4;
    case 'Ledgetrap sofrido':
      return -3;
    case 'Morreu cedo':
      return -5;
    case 'Read do adversário':
      return -4;
    case 'F-smash':
    case 'Up smash':
    case 'Down smash':
    case 'Shield break':
    case 'Spike':
    case 'Gimp':
      return -5;
    case 'Back throw':
    case 'Forward throw':
    case 'Up throw':
    case 'Down throw':
    case 'Bair':
    case 'Up air':
    case 'Down air':
    case 'Magia':
      return -4;
    case 'F-tilt':
    case 'Up tilt':
    case 'Down tilt':
    case 'Fair':
    case 'Nair':
    case 'Dash attack':
    case 'Side B':
    case 'Up B':
    case 'Down B':
    case 'Neutral B':
      return -3;
    case 'Jab':
    case 'Grab':
      return -2;
    case 'Outro':
      return -2;
    case 'Não morreu':
      return 0;
    default:
      return 0;
  }
}

String normalizarTexto(String texto) {
  return texto.trim().toLowerCase();
}

String formatarData(DateTime data) {
  String doisDigitos(int numero) => numero.toString().padLeft(2, '0');

  final dia = doisDigitos(data.day);
  final mes = doisDigitos(data.month);
  final ano = data.year;
  final hora = doisDigitos(data.hour);
  final minuto = doisDigitos(data.minute);

  return '$dia/$mes/$ano às $hora:$minuto';
}

String formatarDataCurta(DateTime data) {
  String doisDigitos(int numero) => numero.toString().padLeft(2, '0');

  return '${doisDigitos(data.day)}/'
      '${doisDigitos(data.month)}/${data.year}';
}

List<String> _listaUnicaOrdenada(dynamic raw) {
  if (raw is! Iterable) return const [];

  final List<String> itens = [];
  for (final item in raw) {
    final String valor = item.toString().trim();
    if (valor.isNotEmpty && !itens.contains(valor)) {
      itens.add(valor);
    }
  }

  return itens;
}

Map<String, List<String>> normalizarMapaListasString(dynamic raw) {
  final Map<String, List<String>> mapa = {};
  if (raw is! Map) return mapa;

  raw.forEach((key, value) {
    final String jogo = key.toString().trim();
    if (jogo.isEmpty) return;

    final List<String> itens = _listaUnicaOrdenada(value);
    if (itens.isNotEmpty) {
      mapa[jogo] = itens;
    }
  });

  return mapa;
}

List<String> _inserirRecente(String item, List<String> atuais, int limite) {
  final String valor = item.trim();
  if (valor.isEmpty) return atuais;

  final List<String> atualizados = [
    valor,
    ...atuais.where((existente) => existente != valor),
  ];

  return atualizados.take(limite).toList();
}

Future<List<PartidaRegistrada>> carregarHistoricoPersistido() async {
  final Map<String, dynamic>? dadosArquivo = await _lerDadosArquivo();
  final dynamic historicoArquivo = dadosArquivo?['historico'];

  if (historicoArquivo is List) {
    return historicoArquivo
        .whereType<Map<String, dynamic>>()
        .map((item) => PartidaRegistrada.fromJson(item))
        .toList();
  }

  final prefs = await SharedPreferences.getInstance();
  final String? historicoPrefs = prefs.getString('historico');
  if (historicoPrefs == null) return const [];

  try {
    final dynamic decoded = jsonDecode(historicoPrefs);
    if (decoded is List) {
      return decoded
          .whereType<Map<String, dynamic>>()
          .map((item) => PartidaRegistrada.fromJson(item))
          .toList();
    }
  } catch (_) {}

  return const [];
}

Future<Set<String>> carregarJogosFavoritos() async {
  final prefs = await SharedPreferences.getInstance();
  return (prefs.getStringList(prefsKeyFavoriteGames) ?? const []).toSet();
}

Future<void> salvarJogosFavoritos(Set<String> favoritos) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList(prefsKeyFavoriteGames, favoritos.toList()..sort());
}

Future<List<String>> carregarJogosRecentes() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getStringList(prefsKeyRecentGames) ?? const [];
}

Future<List<String>> marcarJogoRecente(String jogo) async {
  final prefs = await SharedPreferences.getInstance();
  final List<String> recentes = _inserirRecente(
    jogo,
    prefs.getStringList(prefsKeyRecentGames) ?? const [],
    8,
  );
  await prefs.setStringList(prefsKeyRecentGames, recentes);
  return recentes;
}

Future<Map<String, List<String>>> carregarPersonagensFavoritosPorJogo() async {
  final prefs = await SharedPreferences.getInstance();
  final String? raw = prefs.getString(prefsKeyFavoriteCharactersByGame);
  if (raw == null) return {};

  try {
    return normalizarMapaListasString(jsonDecode(raw));
  } catch (_) {
    return {};
  }
}

Future<void> salvarPersonagensFavoritosPorJogo(
  Map<String, List<String>> favoritos,
) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    prefsKeyFavoriteCharactersByGame,
    jsonEncode(favoritos),
  );
}

Future<Map<String, List<String>>> carregarPersonagensRecentesPorJogo() async {
  final prefs = await SharedPreferences.getInstance();
  final String? raw = prefs.getString(prefsKeyRecentCharactersByGame);
  if (raw == null) return {};

  try {
    return normalizarMapaListasString(jsonDecode(raw));
  } catch (_) {
    return {};
  }
}

Future<Map<String, List<String>>> marcarPersonagemRecente(
  String jogo,
  String personagem,
) async {
  final Map<String, List<String>> recentes =
      await carregarPersonagensRecentesPorJogo();
  recentes[jogo] = _inserirRecente(personagem, recentes[jogo] ?? const [], 10);

  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(prefsKeyRecentCharactersByGame, jsonEncode(recentes));
  return recentes;
}

Map<String, GameUsageStats> calcularUsoPorJogo(
  List<PartidaRegistrada> historico,
) {
  final Map<String, GameUsageStats> stats = {
    for (final jogo in jogosDisponiveis) jogo: const GameUsageStats(),
  };

  for (final jogo in jogosDisponiveis) {
    for (final partida in historico) {
      if (partidaPertenceAoJogo(partida, jogo)) {
        stats[jogo] = (stats[jogo] ?? const GameUsageStats()).adicionar(
          partida,
        );
      }
    }
  }

  return stats;
}

bool partidaUsaPersonagemNoJogo(
  PartidaRegistrada partida,
  String jogo,
  String personagem,
) {
  if (!partidaPertenceAoJogo(partida, jogo)) return false;

  final String nome = normalizarNomePersonagem(personagem);
  if (jogo == jogoInvincibleVs) {
    return partida.meuTime.contains(nome) || partida.personagemJogador == nome;
  }

  return partida.personagemJogador == nome;
}

Map<String, CharacterUsageStats> calcularUsoPersonagensPorJogo(
  List<PartidaRegistrada> historico,
  String jogo,
) {
  final Map<String, CharacterUsageStats> stats = {
    for (final personagem in rosterDoJogo(jogo))
      personagem.name: const CharacterUsageStats(),
  };

  for (final personagem in rosterDoJogo(jogo)) {
    CharacterUsageStats acumulado =
        stats[personagem.name] ?? const CharacterUsageStats();

    for (final partida in historico) {
      if (partidaUsaPersonagemNoJogo(partida, jogo, personagem.name)) {
        acumulado = acumulado.adicionar(partida);
      }
    }

    stats[personagem.name] = acumulado;
  }

  return stats;
}

bool isMesmoDia(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String normalizarNomePersonagem(String nome) {
  final String nomeCorrigido = corrigirTextoLegado(nome).trim();

  switch (nomeCorrigido) {
    case 'Squirtle':
    case 'Ivysaur':
    case 'Charizard':
      return 'Pokémon Trainer';
    case 'Alex':
    case 'Zombie':
    case 'Enderman':
      return 'Steve';
    case 'Pyra':
    case 'Mythra':
      return 'Pyra/Mythra';
    default:
      return nomeCorrigido;
  }
}

String _nomeArquivoPersonagem(String nome) {
  return nome
      .trim()
      .replaceAll("'", '')
      .replaceAll('#', '')
      .replaceAll('?', '')
      .replaceAll('&', 'and')
      .replaceAll(RegExp(r'\s+'), '_');
}

String _nomeArquivoPersonagemLower(String nome) {
  return _nomeArquivoPersonagem(nome).toLowerCase();
}

String _nomeArquivoPersonagemKebab(String nome) {
  return nome
      .trim()
      .replaceAll("'", '')
      .replaceAll('#', '')
      .replaceAll('?', '')
      .replaceAll('&', 'and')
      .replaceAll('.', '')
      .replaceAll(RegExp(r'\s+'), '-');
}

String _nomeArquivoPersonagemKebabLower(String nome) {
  return _nomeArquivoPersonagemKebab(nome).toLowerCase();
}

String _urlArquivoFandom(String wiki, String arquivo) {
  final String caminho = arquivo.trim();
  if (caminho.isEmpty) return '';
  if (caminho.startsWith('http://') || caminho.startsWith('https://')) {
    return caminho;
  }

  return 'https://$wiki/wiki/Special:Redirect/file/${Uri.encodeComponent(caminho)}';
}

List<String> _urlsArquivosFandom(String wiki, Iterable<String> arquivos) {
  return arquivos
      .where((arquivo) => arquivo.trim().isNotEmpty)
      .map((arquivo) => _urlArquivoFandom(wiki, arquivo))
      .toSet()
      .toList();
}

String _nomeSeguroAsset(String valor) {
  String texto = corrigirTextoLegado(valor).toLowerCase().trim();
  final Map<String, String> substituicoes = {
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ã': 'a',
    'ä': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'í': 'i',
    'ì': 'i',
    'î': 'i',
    'ï': 'i',
    'ó': 'o',
    'ò': 'o',
    'ô': 'o',
    'õ': 'o',
    'ö': 'o',
    'ú': 'u',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
    'ñ': 'n',
    '&': ' and ',
  };

  substituicoes.forEach((origem, destino) {
    texto = texto.replaceAll(origem, destino);
  });

  return texto
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}

List<AppImageSource> _fontesComFallbackOffline(
  Iterable<String> urls,
  String localAsset,
) {
  final List<String> urlsValidas = urls
      .map((url) => url.trim())
      .where((url) => url.isNotEmpty)
      .toSet()
      .toList();
  final String asset = localAsset.trim();

  if (urlsValidas.isEmpty) {
    return asset.isEmpty ? const [] : [AppImageSource(localAsset: asset)];
  }

  return [
    for (int i = 0; i < urlsValidas.length; i++)
      AppImageSource(
        remoteUrl: urlsValidas[i],
        localAsset: i == 0 ? asset : '',
      ),
  ];
}

String? getCharacterOfflineAsset(String gameName, String characterName) {
  final String? pasta = pastasPersonagensOfflinePorJogo[gameName];
  if (pasta == null) return null;

  final String nomeSeguro = _nomeSeguroAsset(
    normalizarNomePersonagem(characterName),
  );
  if (nomeSeguro.isEmpty) return null;

  return 'assets/offline_images/characters/$pasta/$nomeSeguro.webp';
}

AppImageSource getGameLogoSource(String gameName) {
  return AppImageSource(
    remoteUrl: logoDoJogo(gameName),
    localAsset: logosJogosOffline[gameName] ?? '',
  );
}

List<AppImageSource> fontesLogoDoJogo(String gameName) {
  final AppImageSource source = getGameLogoSource(gameName);
  return source.isEmpty ? const [] : [source];
}

AppImageSource? getSmashCoverImageSource(
  String characterName,
  String preference,
) {
  final String personagem = normalizarPersonagemCapaSmash(characterName);
  final SmashCoverOption? opcao = opcaoCapaSmashPorId(personagem, preference);
  if (opcao == null) return null;

  final String localAsset =
      smashCoverAssetsOffline[personagem]?[opcao.id] ?? '';
  final String remoteUrl = opcao.imageUrls.isNotEmpty
      ? opcao.imageUrls.first
      : '';

  return AppImageSource(remoteUrl: remoteUrl, localAsset: localAsset);
}

List<AppImageSource> getSmashCoverImageSources(
  String characterName,
  String preference,
) {
  final String personagem = normalizarPersonagemCapaSmash(characterName);
  final SmashCoverOption? opcao = opcaoCapaSmashPorId(personagem, preference);
  if (opcao == null) return const [];

  final String localAsset =
      smashCoverAssetsOffline[personagem]?[opcao.id] ?? '';
  return _fontesComFallbackOffline(opcao.imageUrls, localAsset);
}

List<AppImageSource> getCharacterImageSources(
  String gameName,
  String characterName,
) {
  final String personagem = normalizarNomePersonagem(characterName);
  final String localAsset =
      getCharacterOfflineAsset(gameName, personagem) ?? '';
  return _fontesComFallbackOffline(
    urlsImagemPersonagem(personagem, gameName),
    localAsset,
  );
}

List<AppImageSource> getCharacterImageSourcesWithSmashPreference(
  String characterName,
  String gameName,
  Map<String, String> preferences,
) {
  if (!jogoEhSmash(gameName)) {
    return getCharacterImageSources(gameName, characterName);
  }

  final String personagem = normalizarPersonagemCapaSmash(characterName);
  final String? preference = preferences[personagem];
  if (preference == null || preference.trim().isEmpty) {
    return getCharacterImageSources(gameName, personagem);
  }

  final List<AppImageSource> preferredSources = getSmashCoverImageSources(
    personagem,
    preference,
  );
  if (preferredSources.isNotEmpty) return preferredSources;

  return getCharacterImageSources(gameName, personagem);
}

bool jogoEhSmash(String jogo) {
  return jogo == jogoSmashUltimate;
}

String normalizarPersonagemCapaSmash(String personagem) {
  return normalizarNomePersonagem(personagem);
}

List<SmashCoverOption> opcoesCapaSmash(String personagem) {
  final String nome = normalizarPersonagemCapaSmash(personagem);
  return opcoesCapaSmashPorPersonagem[nome] ?? const [];
}

bool personagemTemPreferenciaCapaSmash(String personagem) {
  return opcoesCapaSmash(personagem).isNotEmpty;
}

SmashCoverOption? opcaoCapaSmashPorId(String personagem, String id) {
  final String preferencia = id.trim();
  if (preferencia.isEmpty) return null;

  for (final opcao in opcoesCapaSmash(personagem)) {
    if (opcao.id == preferencia) return opcao;
  }

  return null;
}

Map<String, String> normalizarPreferenciasCapaSmash(dynamic raw) {
  final Map<String, String> preferencias = {};
  if (raw is! Map) return preferencias;

  raw.forEach((key, value) {
    if (key == null || value == null) return;

    final String personagem = normalizarPersonagemCapaSmash(key.toString());
    final String preferencia = value.toString().trim();

    if (opcaoCapaSmashPorId(personagem, preferencia) != null) {
      preferencias[personagem] = preferencia;
    }
  });

  return preferencias;
}

Future<Map<String, String>> carregarPreferenciasCapaSmashPrefs() async {
  final prefs = await SharedPreferences.getInstance();
  final String? preferenciasRaw = prefs.getString(
    prefsKeySmashCoverPreferences,
  );

  if (preferenciasRaw == null) return {};

  try {
    return normalizarPreferenciasCapaSmash(jsonDecode(preferenciasRaw));
  } catch (_) {
    return {};
  }
}

String rotuloPreferenciaCapaSmash(
  String personagem,
  Map<String, String> preferencias,
) {
  final String nome = normalizarPersonagemCapaSmash(personagem);
  final String? preferencia = preferencias[nome];
  final SmashCoverOption? opcao = preferencia == null
      ? null
      : opcaoCapaSmashPorId(nome, preferencia);

  return opcao?.label ?? 'Padrão';
}

List<String> urlsImagemPersonagemComPreferenciaVisual(
  String nome,
  String jogo,
  Map<String, String> preferencias,
) {
  if (!jogoEhSmash(jogo)) {
    return urlsImagemPersonagem(nome, jogo);
  }

  final String personagem = normalizarPersonagemCapaSmash(nome);
  final String? preferencia = preferencias[personagem];
  final SmashCoverOption? opcao = preferencia == null
      ? null
      : opcaoCapaSmashPorId(personagem, preferencia);
  final List<String> urlsPadrao = urlsImagemPersonagem(personagem, jogo);

  if (opcao == null) {
    return urlsPadrao;
  }

  return opcao.imageUrls;
}

List<String> urlsImagemPersonagem(
  String nome, [
  String jogo = jogoSmashUltimate,
]) {
  final String nomeLimpo = nome.trim();
  final String slug = _nomeArquivoPersonagem(nomeLimpo);
  final String slugLower = _nomeArquivoPersonagemLower(nomeLimpo);
  final String slugKebabLower = _nomeArquivoPersonagemKebabLower(nomeLimpo);
  final String nomeSemPontos = nomeLimpo
      .replaceAll('.', '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  final String nomeSemEspacos = nomeLimpo
      .replaceAll("'", '')
      .replaceAll('#', '')
      .replaceAll('?', '')
      .replaceAll('&', 'and')
      .replaceAll('.', '')
      .replaceAll('-', '')
      .replaceAll(RegExp(r'\s+'), '');
  final String? idKofXV = idsKofXV[nomeLimpo];

  // Jogos cujas imagens vêm de mapas diretos (nome -> URL).
  switch (jogo) {
    case 'Street Fighter 6':
      return _urlsArquivosFandom('streetfighter.fandom.com', [
        imagensStreetFighter6[nomeLimpo] ?? '',
        ...?imagensAlternativasStreetFighter6[nomeLimpo],
        'Sf6-$slugKebabLower.png',
        '$nomeLimpo SF6 Render.png',
        '$nomeSemPontos SF6 Render.png',
        '$nomeLimpo SF6.png',
        '$nomeSemPontos SF6.png',
        'SF6 $nomeLimpo.png',
        'SF6 $nomeSemPontos.png',
        'SF6_$slug.png',
        'SF6_${slug}_Render.png',
        '${slug}_SF6_Render.png',
      ]);
    case 'Mortal Kombat 1':
      return _urlsArquivosFandom('mortalkombat.fandom.com', [
        imagensMortalKombat1[nomeLimpo] ?? '',
        ...?imagensAlternativasMortalKombat1[nomeLimpo],
        'https://www.mortalkombatwarehouse.com/mk12/renders/'
            '${nomeSemEspacos.toLowerCase()}.png',
        '$nomeLimpo MK1 render.webp',
        '$nomeLimpo MK1 Render.png',
        '$nomeLimpo (MK1) Render.png',
        '$nomeLimpo (MK1) - Default.png',
        '$nomeLimpo-MK1.png',
        '$nomeSemEspacos MK1 render.webp',
        '$nomeSemEspacos MK1 Render.png',
        '${nomeSemEspacos}MK1.png',
        '${nomeSemEspacos}rendermk1.png',
        '${nomeSemEspacos.toLowerCase()}rendermk1.png',
        '$slug-MK1.png',
        '$slugLower-mk1.png',
        '${slug}_MK1_render.webp',
        '${slug}_MK1_Render.webp',
        '${slug}_MK1_Render.png',
        'MK1_${slug}_Render.png',
        'MK1 $nomeLimpo.jpg',
        'MK1 $nomeLimpo.png',
      ]);
    case 'Avatar Legends: The Fighting Game':
      return _urlsArquivosFandom('avatar.fandom.com', [
        imagensAvatarLegends[nomeLimpo] ?? '',
        '$nomeLimpo.png',
        '$slug.png',
        '${slug}_Avatar.png',
      ]);
    case 'Guilty Gear -Strive-':
      return _urlsArquivosFandom('guiltygear.fandom.com', [
        imagensOficiaisGuiltyGearStrive[nomeLimpo] ?? '',
        imagensGuiltyGearStrive[nomeLimpo] ?? '',
        ...?imagensAlternativasGuiltyGearStrive[nomeLimpo],
        '${slug}_Guilty_Gear_Strive.png',
        '${slug}_Strive.png',
        'GGST_${slug}_Render.png',
        'GGST_$slug.png',
        '${slug}_GGST.png',
      ]);
    case 'The King of Fighters XV':
      return _urlsArquivosFandom('snk.fandom.com', [
        if (idKofXV != null)
          'https://www.snk-corp.co.jp/us/games/kof-xv/characters/img/'
              'character_$idKofXV.png',
        ...?imagensAlternativasKofXV[nomeLimpo],
        imagensKofXV[nomeLimpo] ?? '',
        'Kof_xv_${slugLower}_render.png',
        'KOFXV_$slug.png',
        'KOF_XV_$slug.png',
        '${slug}_KOFXV.png',
      ]);
    case jogoTekken8:
      return _urlsArquivosFandom('tekken.fandom.com', [
        imagensTekken8[nomeLimpo] ?? '',
        ...?imagensAlternativasTekken8[nomeLimpo],
        '$nomeLimpo TK8.png',
        '$nomeLimpo T8.png',
        '$nomeLimpo Tekken 8.png',
        '$nomeLimpo Tekken 8 Render.png',
        '$nomeSemPontos TK8.png',
        '$nomeSemPontos T8.png',
        '$nomeSemPontos Tekken 8 Render.png',
        '${slug}_TK8.png',
        '${slug}_T8.png',
        '${slug}_Tekken_8.png',
        '${slug}_Tekken_8_Render.png',
        'TK8_$slug.png',
        'T8_$slug.png',
        'Tekken_8_$slug.png',
        'Tekken_8_${slug}_Render.png',
      ]);
    case jogo2Xko:
      return [
        imagens2XKO[nomeLimpo] ?? '',
      ].where((url) => url.isNotEmpty).toList();
    case jogoRivalsOfAether2:
      return _urlsArquivosFandom('rivals-of-aether.fandom.com', [
        imagensRivalsOfAether2[nomeLimpo] ?? '',
        ...?imagensAlternativasRivalsOfAether2[nomeLimpo],
        '$nomeLimpo Rivals 2.png',
        '$nomeLimpo Rivals of Aether II.png',
        '$nomeLimpo ROA2.png',
        '$nomeLimpo Artwork.png',
        '$nomeLimpo 3D Model.png',
        '$nomeSemPontos Rivals 2.png',
        '$nomeSemPontos Rivals of Aether II.png',
        '$nomeSemPontos Artwork.png',
        '${slug}_Rivals_2.png',
        '${slug}_Rivals_of_Aether_II.png',
        '${slug}_ROA2.png',
        '${slug}_Artwork.png',
        '${slug}_3D_Model.png',
        'Rivals_2_$slug.png',
        'Rivals_of_Aether_II_$slug.png',
      ]);
    case 'Dragon Ball FighterZ':
      return [
        imagensDBFZ[nomeLimpo] ?? '',
      ].where((url) => url.isNotEmpty).toList();
    case 'Fatal Fury':
      return [
        imagensFatalFury[nomeLimpo] ?? '',
      ].where((url) => url.isNotEmpty).toList();
    case 'Invincible VS':
      return [
        imagensInvincible[nomeLimpo] ?? '',
      ].where((url) => url.isNotEmpty).toList();
  }

  // Super Smash Bros. Ultimate (padrão): imagem do CDN do Fandom.
  // (O site oficial smashbros.com bloqueia hotlink, então as imagens não
  // carregavam; usamos o mesmo CDN confiável dos demais jogos.)
  return [
    imagensSmash[normalizarNomePersonagem(nome)] ?? '',
  ].where((url) => url.isNotEmpty).toList();
}

String urlImagemPersonagem(String nome, [String jogo = jogoSmashUltimate]) {
  final List<String> urls = urlsImagemPersonagem(nome, jogo);
  return urls.isEmpty ? '' : urls.first;
}

Character personagemPorNome(String nome) {
  final String nomeNormalizado = normalizarNomePersonagem(nome);

  for (final personagem in [
    ...personagensSmash,
    ...personagensStreetFighter6,
    ...personagensMortalKombat1,
    ...personagensAvatarLegends,
    ...personagensGuiltyGearStrive,
    ...personagensKofXV,
    ...personagensTekken8,
    ...personagens2XKO,
    ...personagensRivalsOfAether2,
    ...personagensDBFZ,
    ...personagensFatalFury,
    ...personagensInvincible,
  ]) {
    if (personagem.name == nomeNormalizado) {
      return personagem;
    }
  }

  return Character(
    name: nomeNormalizado,
    initial: nomeNormalizado.isNotEmpty
        ? nomeNormalizado[0].toUpperCase()
        : '?',
    rank: 'Starter V',
    pdl: 0,
  );
}

List<FrequenciaItem> gerarRankingFrequencia(List<String> itens) {
  final Map<String, int> contagem = {};
  final Map<String, String> nomeOriginal = {};

  for (final item in itens) {
    final textoLimpo = item.trim();

    if (textoLimpo.isEmpty || textoLimpo == 'Sem dados') {
      continue;
    }

    final chave = normalizarTexto(textoLimpo);

    contagem[chave] = (contagem[chave] ?? 0) + 1;
    nomeOriginal.putIfAbsent(chave, () => textoLimpo);
  }

  final List<FrequenciaItem> ranking = contagem.entries.map((entry) {
    return FrequenciaItem(
      nome: nomeOriginal[entry.key] ?? entry.key,
      quantidade: entry.value,
    );
  }).toList();

  ranking.sort((a, b) {
    final comparacaoQuantidade = b.quantidade.compareTo(a.quantidade);

    if (comparacaoQuantidade != 0) {
      return comparacaoQuantidade;
    }

    return a.nome.compareTo(b.nome);
  });

  return ranking;
}

List<PlayerResumo> gerarRankingPlayers(List<PartidaRegistrada> partidas) {
  final Map<String, int> total = {};
  final Map<String, int> vitorias = {};
  final Map<String, int> derrotas = {};
  final Map<String, String> nomeOriginal = {};

  for (final partida in partidas) {
    final nickLimpo = partida.nickAdversario.trim();

    if (nickLimpo.isEmpty || nickLimpo == 'Sem nick') {
      continue;
    }

    final chave = normalizarTexto(nickLimpo);

    nomeOriginal.putIfAbsent(chave, () => nickLimpo);
    total[chave] = (total[chave] ?? 0) + 1;

    if (partida.resultado == 'Vitória') {
      vitorias[chave] = (vitorias[chave] ?? 0) + 1;
    } else if (partida.resultado == 'Derrota') {
      derrotas[chave] = (derrotas[chave] ?? 0) + 1;
    }
  }

  final List<PlayerResumo> ranking = total.keys.map((chave) {
    return PlayerResumo(
      nick: nomeOriginal[chave] ?? chave,
      total: total[chave] ?? 0,
      vitorias: vitorias[chave] ?? 0,
      derrotas: derrotas[chave] ?? 0,
    );
  }).toList();

  ranking.sort((a, b) {
    final comparacaoTotal = b.total.compareTo(a.total);

    if (comparacaoTotal != 0) {
      return comparacaoTotal;
    }

    return a.nick.compareTo(b.nick);
  });

  return ranking;
}

List<MatchupResumo> gerarRankingMatchups(List<PartidaRegistrada> partidas) {
  final Map<String, List<PartidaRegistrada>> partidasPorMatchup = {};

  for (final partida in partidas) {
    final chave = partida.personagemAdversario.trim();

    if (chave.isEmpty) {
      continue;
    }

    partidasPorMatchup.putIfAbsent(chave, () => []);
    partidasPorMatchup[chave]!.add(partida);
  }

  final List<MatchupResumo> ranking = partidasPorMatchup.entries.map((entry) {
    final personagemAdversario = entry.key;
    final partidasDoMatchup = entry.value;

    final int total = partidasDoMatchup.length;
    final int vitorias = partidasDoMatchup
        .where((partida) => partida.resultado == 'Vitória')
        .length;
    final int derrotas = partidasDoMatchup
        .where((partida) => partida.resultado == 'Derrota')
        .length;

    final int saldoPdl = partidasDoMatchup.fold(
      0,
      (soma, partida) => soma + partida.pdlGerado,
    );

    return MatchupResumo(
      personagemAdversario: personagemAdversario,
      total: total,
      vitorias: vitorias,
      derrotas: derrotas,
      saldoPdl: saldoPdl,
      killMaisComum: encontrarMaisFrequente(
        partidasDoMatchup.map((partida) => partida.formaDeKill).toList(),
      ),
      morteMaisComum: encontrarMaisFrequente(
        partidasDoMatchup.map((partida) => partida.formaDeMorte).toList(),
      ),
      stageMaisJogado: encontrarMaisFrequente(
        partidasDoMatchup.map((partida) => partida.stage).toList(),
      ),
    );
  }).toList();

  ranking.sort((a, b) {
    final comparacaoTotal = b.total.compareTo(a.total);

    if (comparacaoTotal != 0) {
      return comparacaoTotal;
    }

    return a.personagemAdversario.compareTo(b.personagemAdversario);
  });

  return ranking;
}

String encontrarMaisFrequente(List<String> itens) {
  final ranking = gerarRankingFrequencia(itens);

  if (ranking.isEmpty) {
    return 'Sem dados';
  }

  return ranking.first.nome;
}

int calcularPdlDaPartida({
  required String resultado,
  required int stocks,
  required int porcentagem,
  required String formaDeKill,
  required String formaDeMorte,
}) {
  int pdl = 0;

  if (resultado == 'Vitória') {
    pdl += 20;

    if (stocks == 2) {
      pdl += 8;
    } else if (stocks == 3) {
      pdl += 15;
    }

    if (porcentagem <= 50) {
      pdl += 5;
    } else if (porcentagem >= 150) {
      pdl -= 3;
    }
  } else {
    pdl -= 18;

    if (stocks == 2) {
      pdl -= 8;
    } else if (stocks == 3) {
      pdl -= 15;
    }

    if (porcentagem >= 120) {
      pdl += 5;
    } else if (porcentagem <= 50) {
      pdl -= 5;
    }
  }

  pdl += bonusPorKill(formaDeKill);
  pdl += penalidadePorMorte(formaDeMorte);

  return pdl;
}

int calcularPdlStreetFighter({
  required int roundsVencidos,
  required int roundsPerdidos,
  required bool venceuRound1,
  required bool chegouAoRound3,
  required bool venceuRound3,
}) {
  final bool venceuPartida = roundsVencidos >= 2;
  int pdl = venceuPartida ? 24 : -20;

  if (venceuPartida && roundsPerdidos == 0) {
    pdl += 8;
  } else if (!venceuPartida && roundsVencidos == 0) {
    pdl -= 8;
  }

  if (venceuRound1) {
    pdl += 3;
  } else {
    pdl -= 2;
  }

  if (chegouAoRound3) {
    pdl += venceuRound3 ? 5 : -5;
  }

  return pdl;
}

List<String> gerarOpcoesFiltro(List<String> itens) {
  final List<String> opcoes = itens
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty && item != 'Sem dados')
      .toSet()
      .toList();

  opcoes.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

  return ['Todos', ...opcoes];
}

List<String> gerarSugestoesPlayers(List<PartidaRegistrada> partidas) {
  return gerarRankingPlayers(partidas).map((player) => player.nick).toList();
}

String formatarSaldo(int valor) {
  return valor >= 0 ? '+$valor' : '$valor';
}

MatchupResumo? melhorMatchupPorWinrate(List<MatchupResumo> matchups) {
  if (matchups.isEmpty) return null;

  final List<MatchupResumo> ordenados = [...matchups];
  ordenados.sort((a, b) {
    final winrateCompare = b.winrate.compareTo(a.winrate);
    if (winrateCompare != 0) return winrateCompare;

    final saldoCompare = b.saldoPdl.compareTo(a.saldoPdl);
    if (saldoCompare != 0) return saldoCompare;

    return b.total.compareTo(a.total);
  });

  return ordenados.first;
}

MatchupResumo? piorMatchupPorWinrate(List<MatchupResumo> matchups) {
  if (matchups.isEmpty) return null;

  final List<MatchupResumo> ordenados = [...matchups];
  ordenados.sort((a, b) {
    final winrateCompare = a.winrate.compareTo(b.winrate);
    if (winrateCompare != 0) return winrateCompare;

    final saldoCompare = a.saldoPdl.compareTo(b.saldoPdl);
    if (saldoCompare != 0) return saldoCompare;

    return b.total.compareTo(a.total);
  });

  return ordenados.first;
}

MatchupResumo? maiorGanhoPdlPorMatchup(List<MatchupResumo> matchups) {
  if (matchups.isEmpty) return null;

  final List<MatchupResumo> ordenados = [...matchups];
  ordenados.sort((a, b) => b.saldoPdl.compareTo(a.saldoPdl));
  return ordenados.first;
}

MatchupResumo? maiorPerdaPdlPorMatchup(List<MatchupResumo> matchups) {
  if (matchups.isEmpty) return null;

  final List<MatchupResumo> ordenados = [...matchups];
  ordenados.sort((a, b) => a.saldoPdl.compareTo(b.saldoPdl));
  return ordenados.first;
}

String gerarFocoAutomatico(String morteMaisComum, String piorMatchup) {
  switch (morteMaisComum) {
    case 'SD':
      return 'Foco: diminuir SDs e revisar controle de risco fora do palco.';
    case 'Recovery errado':
      return 'Foco: treinar recovery, mixups de volta e rotas seguras para o ledge.';
    case 'Panic option':
      return 'Foco: jogar mais calmo sob pressão e escolher opções defensivas melhores.';
    case 'Punish sofrido':
      return 'Foco: atacar menos no automático e deixar suas opções mais seguras.';
    case 'Edgeguard sofrido':
      return 'Foco: variar timing de recovery e evitar voltar sempre pelo mesmo caminho.';
    case 'Ledgetrap sofrido':
      return 'Foco: treinar saída da ledge e parar de escolher sempre a mesma opção.';
    case 'Morreu cedo':
      return 'Foco: revisar DI, sobrevivência e situações em que você toma kill cedo.';
    case 'Read do adversário':
      return 'Foco: variar hábitos e não repetir a mesma resposta em pressão.';
    default:
      if (piorMatchup != 'Sem dados') {
        return 'Foco: revisar o matchup contra $piorMatchup e anotar o que mais te prende nele.';
      }
      return 'Foco: registrar mais partidas para o LabTracker encontrar padrões mais confiáveis.';
  }
}
