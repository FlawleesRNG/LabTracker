
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const LabTrackerApp());
}

class LabTrackerApp extends StatelessWidget {
  const LabTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LabTracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const RootPage(),
    );
  }
}

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

  Character copyWith({
    String? name,
    String? initial,
    String? rank,
    int? pdl,
  }) {
    return Character(
      name: name ?? this.name,
      initial: initial ?? this.initial,
      rank: rank ?? this.rank,
      pdl: pdl ?? this.pdl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'initial': initial,
      'rank': rank,
      'pdl': pdl,
    };
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

  const PlayerProfile({
    required this.nick,
    required this.tagSecundaria,
    required this.regiao,
    required this.jogoPrincipal,
    required this.mainPrincipal,
    required this.bio,
  });

  PlayerProfile copyWith({
    String? nick,
    String? tagSecundaria,
    String? regiao,
    String? jogoPrincipal,
    String? mainPrincipal,
    String? bio,
  }) {
    return PlayerProfile(
      nick: nick ?? this.nick,
      tagSecundaria: tagSecundaria ?? this.tagSecundaria,
      regiao: regiao ?? this.regiao,
      jogoPrincipal: jogoPrincipal ?? this.jogoPrincipal,
      mainPrincipal: mainPrincipal ?? this.mainPrincipal,
      bio: bio ?? this.bio,
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

const List<String> jogosDisponiveis = [
  'Super Smash Bros. Ultimate',
  'Invincible VS',
  'Dragon Ball FighterZ',
  'Fatal Fury',
];

class PartidaRegistrada {
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

  const PartidaRegistrada({
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
  });

  Map<String, dynamic> toJson() {
    return {
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
    };
  }

  factory PartidaRegistrada.fromJson(Map<String, dynamic> json) {
    return PartidaRegistrada(
      personagemJogador: normalizarNomePersonagem(json['personagemJogador'] ?? ''),
      nickAdversario: json['nickAdversario'] ?? 'Sem nick',
      personagemAdversario: normalizarNomePersonagem(json['personagemAdversario'] ?? ''),
      stage: json['stage'] ?? '',
      resultado: json['resultado'] ?? '',
      stocks: json['stocks'] ?? 1,
      porcentagem: json['porcentagem'] ?? 0,
      formaDeKill: json['formaDeKill'] ?? 'Sem dados',
      formaDeMorte: json['formaDeMorte'] ?? 'Sem dados',
      observacoes: json['observacoes'] ?? '',
      pdlGerado: json['pdlGerado'] ?? 0,
      data: DateTime.tryParse(json['data'] ?? '') ?? DateTime.now(),
    );
  }
}

class FrequenciaItem {
  final String nome;
  final int quantidade;

  const FrequenciaItem({
    required this.nome,
    required this.quantidade,
  });
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

  const ResultadoDetalhesPartida.editar(this.partidaEditada)
      : acao = 'editar';
}

const List<Character> personagensSmash = [
  Character(name: 'Mario', initial: 'M', rank: 'Starter V', pdl: 0),
  Character(name: 'Donkey Kong', initial: 'DK', rank: 'Starter V', pdl: 0),
  Character(name: 'Link', initial: 'L', rank: 'Starter V', pdl: 0),
  Character(name: 'Samus', initial: 'S', rank: 'Starter V', pdl: 0),
  Character(name: 'Dark Samus', initial: 'DS', rank: 'Starter V', pdl: 0),
  Character(name: 'Yoshi', initial: 'Y', rank: 'Starter V', pdl: 0),
  Character(name: 'Kirby', initial: 'K', rank: 'Starter V', pdl: 0),
  Character(name: 'Fox', initial: 'F', rank: 'Starter V', pdl: 0),
  Character(name: 'Pikachu', initial: 'P', rank: 'Starter V', pdl: 0),
  Character(name: 'Luigi', initial: 'L', rank: 'Starter V', pdl: 0),
  Character(name: 'Ness', initial: 'N', rank: 'Starter V', pdl: 0),
  Character(name: 'Captain Falcon', initial: 'CF', rank: 'Starter V', pdl: 0),
  Character(name: 'Jigglypuff', initial: 'J', rank: 'Starter V', pdl: 0),
  Character(name: 'Peach', initial: 'P', rank: 'Starter V', pdl: 0),
  Character(name: 'Daisy', initial: 'D', rank: 'Starter V', pdl: 0),
  Character(name: 'Bowser', initial: 'B', rank: 'Starter V', pdl: 0),
  Character(name: 'Ice Climbers', initial: 'IC', rank: 'Starter V', pdl: 0),
  Character(name: 'Sheik', initial: 'S', rank: 'Starter V', pdl: 0),
  Character(name: 'Zelda', initial: 'Z', rank: 'Starter V', pdl: 0),
  Character(name: 'Dr. Mario', initial: 'DM', rank: 'Starter V', pdl: 0),
  Character(name: 'Pichu', initial: 'P', rank: 'Starter V', pdl: 0),
  Character(name: 'Falco', initial: 'F', rank: 'Starter V', pdl: 0),
  Character(name: 'Marth', initial: 'M', rank: 'Starter V', pdl: 0),
  Character(name: 'Lucina', initial: 'L', rank: 'Starter V', pdl: 0),
  Character(name: 'Young Link', initial: 'YL', rank: 'Starter V', pdl: 0),
  Character(name: 'Ganondorf', initial: 'G', rank: 'Starter V', pdl: 0),
  Character(name: 'Mewtwo', initial: 'M2', rank: 'Starter V', pdl: 0),
  Character(name: 'Roy', initial: 'R', rank: 'Starter V', pdl: 0),
  Character(name: 'Chrom', initial: 'C', rank: 'Starter V', pdl: 0),
  Character(name: 'Mr. Game & Watch', initial: 'GW', rank: 'Starter V', pdl: 0),
  Character(name: 'Meta Knight', initial: 'MK', rank: 'Starter V', pdl: 0),
  Character(name: 'Pit', initial: 'P', rank: 'Starter V', pdl: 0),
  Character(name: 'Dark Pit', initial: 'DP', rank: 'Starter V', pdl: 0),
  Character(name: 'Zero Suit Samus', initial: 'ZS', rank: 'Starter V', pdl: 0),
  Character(name: 'Wario', initial: 'W', rank: 'Starter V', pdl: 0),
  Character(name: 'Snake', initial: 'S', rank: 'Starter V', pdl: 0),
  Character(name: 'Ike', initial: 'I', rank: 'Starter V', pdl: 0),
  Character(name: 'Pokémon Trainer', initial: 'PT', rank: 'Starter V', pdl: 0),
  Character(name: 'Diddy Kong', initial: 'DD', rank: 'Starter V', pdl: 0),
  Character(name: 'Lucas', initial: 'Lu', rank: 'Starter V', pdl: 0),
  Character(name: 'Sonic', initial: 'So', rank: 'Starter V', pdl: 0),
  Character(name: 'King Dedede', initial: 'KD', rank: 'Starter V', pdl: 0),
  Character(name: 'Olimar', initial: 'O', rank: 'Starter V', pdl: 0),
  Character(name: 'Lucario', initial: 'Lc', rank: 'Starter V', pdl: 0),
  Character(name: 'R.O.B.', initial: 'ROB', rank: 'Starter V', pdl: 0),
  Character(name: 'Toon Link', initial: 'TL', rank: 'Starter V', pdl: 0),
  Character(name: 'Wolf', initial: 'W', rank: 'Starter V', pdl: 0),
  Character(name: 'Villager', initial: 'V', rank: 'Starter V', pdl: 0),
  Character(name: 'Mega Man', initial: 'MM', rank: 'Starter V', pdl: 0),
  Character(name: 'Wii Fit Trainer', initial: 'WF', rank: 'Starter V', pdl: 0),
  Character(name: 'Rosalina & Luma', initial: 'RL', rank: 'Starter V', pdl: 0),
  Character(name: 'Little Mac', initial: 'LM', rank: 'Starter V', pdl: 0),
  Character(name: 'Greninja', initial: 'G', rank: 'Starter V', pdl: 0),
  Character(name: 'Mii Brawler', initial: 'MB', rank: 'Starter V', pdl: 0),
  Character(name: 'Mii Swordfighter', initial: 'MS', rank: 'Starter V', pdl: 0),
  Character(name: 'Mii Gunner', initial: 'MG', rank: 'Starter V', pdl: 0),
  Character(name: 'Palutena', initial: 'P', rank: 'Starter V', pdl: 0),
  Character(name: 'Pac-Man', initial: 'PM', rank: 'Starter V', pdl: 0),
  Character(name: 'Robin', initial: 'R', rank: 'Starter V', pdl: 0),
  Character(name: 'Shulk', initial: 'S', rank: 'Starter V', pdl: 0),
  Character(name: 'Bowser Jr.', initial: 'BJ', rank: 'Starter V', pdl: 0),
  Character(name: 'Duck Hunt', initial: 'DH', rank: 'Starter V', pdl: 0),
  Character(name: 'Ryu', initial: 'R', rank: 'Starter V', pdl: 0),
  Character(name: 'Ken', initial: 'K', rank: 'Starter V', pdl: 0),
  Character(name: 'Cloud', initial: 'C', rank: 'Starter V', pdl: 0),
  Character(name: 'Corrin', initial: 'Co', rank: 'Starter V', pdl: 0),
  Character(name: 'Bayonetta', initial: 'B', rank: 'Starter V', pdl: 0),
  Character(name: 'Inkling', initial: 'I', rank: 'Starter V', pdl: 0),
  Character(name: 'Ridley', initial: 'R', rank: 'Starter V', pdl: 0),
  Character(name: 'Simon', initial: 'S', rank: 'Starter V', pdl: 0),
  Character(name: 'Richter', initial: 'Ri', rank: 'Starter V', pdl: 0),
  Character(name: 'King K. Rool', initial: 'KR', rank: 'Starter V', pdl: 0),
  Character(name: 'Isabelle', initial: 'Is', rank: 'Starter V', pdl: 0),
  Character(name: 'Incineroar', initial: 'In', rank: 'Starter V', pdl: 0),
  Character(name: 'Piranha Plant', initial: 'PP', rank: 'Starter V', pdl: 0),
  Character(name: 'Joker', initial: 'J', rank: 'Starter V', pdl: 0),
  Character(name: 'Hero', initial: 'H', rank: 'Starter V', pdl: 0),
  Character(name: 'Banjo & Kazooie', initial: 'BK', rank: 'Starter V', pdl: 0),
  Character(name: 'Terry', initial: 'T', rank: 'Starter V', pdl: 0),
  Character(name: 'Byleth', initial: 'By', rank: 'Starter V', pdl: 0),
  Character(name: 'Min Min', initial: 'Mn', rank: 'Starter V', pdl: 0),
  Character(name: 'Steve', initial: 'St', rank: 'Starter V', pdl: 0),
  Character(name: 'Sephiroth', initial: 'Se', rank: 'Starter V', pdl: 0),
  Character(name: 'Pyra/Mythra', initial: 'PM', rank: 'Starter V', pdl: 0),
  Character(name: 'Kazuya', initial: 'Ka', rank: 'Starter V', pdl: 0),
  Character(name: 'Sora', initial: 'So', rank: 'Starter V', pdl: 0),
];

const List<String> stagesSmash = [
  'Battlefield',
  'Small Battlefield',
  'Final Destination',
  'Pokémon Stadium 2',
  'Smashville',
  'Town and City',
  'Kalos Pokémon League',
  'Hollow Bastion',
  "Yoshi's Story",
];

const List<String> formasDeKill = [
  'Kill confirm',
  'Edgeguard',
  'Ledgetrap',
  'Read',
  'Punish',
  'Smash attack',
  'Magia',
  'Spike',
  'Gimp',
  'Outro',
];

const List<String> formasDeMorte = [
  'SD',
  'Recovery errado',
  'Panic option',
  'Punish sofrido',
  'Edgeguard sofrido',
  'Ledgetrap sofrido',
  'Morreu cedo',
  'Read do adversário',
  'Outro',
];

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
    case 'Smash attack':
      return 2;
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

bool isMesmoDia(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String normalizarNomePersonagem(String nome) {
  switch (nome.trim()) {
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
      return nome.trim();
  }
}

Character personagemPorNome(String nome) {
  final String nomeNormalizado = normalizarNomePersonagem(nome);

  for (final personagem in personagensSmash) {
    if (personagem.name == nomeNormalizado) {
      return personagem;
    }
  }

  return Character(
    name: nomeNormalizado,
    initial: nomeNormalizado.isNotEmpty ? nomeNormalizado[0].toUpperCase() : '?',
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


List<String> gerarOpcoesFiltro(List<String> itens) {
  final List<String> opcoes = itens
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty && item != 'Sem dados')
      .toSet()
      .toList();

  opcoes.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

  return ['Todos', ...opcoes];
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


class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  bool carregando = true;
  bool perfilExiste = false;

  @override
  void initState() {
    super.initState();
    verificarPerfil();
  }

  Future<void> verificarPerfil() async {
    final prefs = await SharedPreferences.getInstance();
    final String? perfilSalvo = prefs.getString('perfilJogador');

    bool existe = false;

    if (perfilSalvo != null) {
      try {
        final perfil = PlayerProfile.fromJson(jsonDecode(perfilSalvo));
        existe = perfil.nick.trim().isNotEmpty;
      } catch (_) {
        existe = false;
      }
    }

    setState(() {
      perfilExiste = existe;
      carregando = false;
    });
  }

  Future<void> concluirPerfil(PlayerProfile perfil) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('perfilJogador', jsonEncode(perfil.toJson()));

    setState(() {
      perfilExiste = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (carregando) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!perfilExiste) {
      return CriarPerfilInicialPage(
        onPerfilCriado: concluirPerfil,
      );
    }

    return const SelecionarJogoInicialPage();
  }
}

class CriarPerfilInicialPage extends StatefulWidget {
  final Future<void> Function(PlayerProfile perfil) onPerfilCriado;

  const CriarPerfilInicialPage({
    super.key,
    required this.onPerfilCriado,
  });

  @override
  State<CriarPerfilInicialPage> createState() => _CriarPerfilInicialPageState();
}

class _CriarPerfilInicialPageState extends State<CriarPerfilInicialPage> {
  final TextEditingController nickController = TextEditingController();
  final TextEditingController regiaoController = TextEditingController();

  bool salvando = false;

  @override
  void dispose() {
    nickController.dispose();
    regiaoController.dispose();
    super.dispose();
  }

  Future<void> salvarPerfilInicial() async {
    if (nickController.text.trim().isEmpty) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Nick não informado'),
            content: const Text('Digite seu nick para continuar.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Ok'),
              ),
            ],
          );
        },
      );
      return;
    }

    final perfil = PlayerProfile(
      nick: nickController.text.trim(),
      tagSecundaria: '',
      regiao: regiaoController.text.trim(),
      jogoPrincipal: '',
      mainPrincipal: '',
      bio: '',
    );

    setState(() {
      salvando = true;
    });

    await widget.onPerfilCriado(perfil);

    if (!mounted) return;

    setState(() {
      salvando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar perfil'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bem-vindo ao LabTracker',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Antes de começar, só preciso saber como você quer aparecer no app.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        TextField(
                          controller: nickController,
                          decoration: const InputDecoration(
                            labelText: 'Seu nick',
                            border: OutlineInputBorder(),
                            hintText: 'Ex: Flawlees',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: regiaoController,
                          decoration: const InputDecoration(
                            labelText: 'Região opcional',
                            border: OutlineInputBorder(),
                            hintText: 'Ex: SC - Brasil',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: salvando ? null : salvarPerfilInicial,
                    icon: const Icon(Icons.arrow_forward),
                    label: Text(salvando ? 'Salvando...' : 'Continuar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SelecionarJogoInicialPage extends StatelessWidget {
  const SelecionarJogoInicialPage({super.key});

  void abrirSelecaoPersonagem(BuildContext context, String jogo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelecionarPersonagemInicialPage(
          jogoSelecionado: jogo,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escolher jogo'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Qual jogo você vai treinar agora?',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Por enquanto o tracker completo está pronto para Smash. Os outros jogos já ficam preparados para expansão.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: jogosDisponiveis.length,
                itemBuilder: (context, index) {
                  final jogo = jogosDisponiveis[index];
                  final bool completo = jogo == 'Super Smash Bros. Ultimate';

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(jogo[0]),
                      ),
                      title: Text(jogo),
                      subtitle: Text(
                        completo
                            ? 'Tracker completo disponível'
                            : 'Base preparada para update futuro',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        abrirSelecaoPersonagem(context, jogo);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SelecionarPersonagemInicialPage extends StatelessWidget {
  final String jogoSelecionado;

  const SelecionarPersonagemInicialPage({
    super.key,
    required this.jogoSelecionado,
  });

  void entrarNoTracker(BuildContext context, Character personagem) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomePage(
          jogoAtual: jogoSelecionado,
          personagemInicialNome: personagem.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escolher personagem'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              jogoSelecionado,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Escolha o personagem que você vai usar nesta sessão.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                itemCount: personagensSmash.length,
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 230,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.55,
                ),
                itemBuilder: (context, index) {
                  final personagem = personagensSmash[index];

                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      entrarNoTracker(context, personagem);
                    },
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              child: Text(
                                personagem.initial,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    personagem.name,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(personagem.rank),
                                  Text('${personagem.pdl} PDL'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final String jogoAtual;
  final String? personagemInicialNome;

  const HomePage({
    super.key,
    required this.jogoAtual,
    this.personagemInicialNome,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  PlayerProfile perfil = perfilPadrao;

  Map<String, Character> personagens = {
    for (final personagem in personagensSmash) personagem.name: personagem,
  };

  String personagemAtualNome = 'Hero';

  List<PartidaRegistrada> historico = [];

  bool carregando = true;

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  Character get personagemAtual {
    return personagens[personagemAtualNome]!;
  }

  Future<void> carregarDados() async {
    final prefs = await SharedPreferences.getInstance();

    final String? personagensSalvos = prefs.getString('personagens');
    final String? historicoSalvo = prefs.getString('historico');
    final String? personagemAtualSalvo = prefs.getString('personagemAtualNome');
    final String? perfilSalvo = prefs.getString('perfilJogador');

    if (personagensSalvos != null) {
      final List<dynamic> listaPersonagens = jsonDecode(personagensSalvos);

      personagens = {
        for (final item in listaPersonagens)
          Character.fromJson(item).name: Character.fromJson(item),
      };

      for (final personagemBase in personagensSmash) {
        personagens.putIfAbsent(personagemBase.name, () => personagemBase);
      }
    }

    if (historicoSalvo != null) {
      final List<dynamic> listaHistorico = jsonDecode(historicoSalvo);

      historico = listaHistorico
          .map((item) => PartidaRegistrada.fromJson(item))
          .toList();
    }

    if (personagemAtualSalvo != null &&
        personagens.containsKey(personagemAtualSalvo)) {
      personagemAtualNome = personagemAtualSalvo;
    }

    if (widget.personagemInicialNome != null &&
        personagens.containsKey(widget.personagemInicialNome)) {
      personagemAtualNome = widget.personagemInicialNome!;
    }

    if (perfilSalvo != null) {
      perfil = PlayerProfile.fromJson(jsonDecode(perfilSalvo));
    }

    recalcularPersonagensPeloHistorico();

    setState(() {
      carregando = false;
    });
  }

  Future<void> salvarDados() async {
    final prefs = await SharedPreferences.getInstance();

    final String personagensJson = jsonEncode(
      personagens.values.map((personagem) => personagem.toJson()).toList(),
    );

    final String historicoJson = jsonEncode(
      historico.map((partida) => partida.toJson()).toList(),
    );

    await prefs.setString('personagens', personagensJson);
    await prefs.setString('historico', historicoJson);
    await prefs.setString('personagemAtualNome', personagemAtualNome);
    await prefs.setString('perfilJogador', jsonEncode(perfil.toJson()));
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
      'perfilJogador': perfil.toJson(),
      'jogoAtual': widget.jogoAtual,
      'personagemAtualNome': personagemAtualNome,
      'personagens': personagens.values.map((personagem) => personagem.toJson()).toList(),
      'historico': historico.map((partida) => partida.toJson()).toList(),
    };
  }

  Future<String> exportarBackup() async {
    final Directory pastaBackup = Directory(pastaBackupPath);

    if (!await pastaBackup.exists()) {
      await pastaBackup.create(recursive: true);
    }

    final DateTime agora = DateTime.now();
    String doisDigitos(int numero) => numero.toString().padLeft(2, '0');

    final String nomeArquivo = 'labtracker_backup_'
        '${agora.year}${doisDigitos(agora.month)}${doisDigitos(agora.day)}_'
        '${doisDigitos(agora.hour)}${doisDigitos(agora.minute)}${doisDigitos(agora.second)}.json';

    final String caminhoArquivo = '${pastaBackup.path}${Platform.pathSeparator}$nomeArquivo';

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
      throw Exception('A pasta de backup ainda não existe. Exporte um backup primeiro.');
    }

    final List<File> arquivos = pastaBackup
        .listSync()
        .whereType<File>()
        .where((arquivo) => arquivo.path.toLowerCase().endsWith('.json'))
        .toList();

    if (arquivos.isEmpty) {
      throw Exception('Nenhum arquivo .json de backup foi encontrado na pasta.');
    }

    arquivos.sort((a, b) {
      return b.lastModifiedSync().compareTo(a.lastModifiedSync());
    });

    final File arquivoMaisRecente = arquivos.first;
    final String conteudo = await arquivoMaisRecente.readAsString();
    final Map<String, dynamic> dados = jsonDecode(conteudo);

    if (dados['app'] != 'LabTracker') {
      throw Exception('Esse arquivo não parece ser um backup válido do LabTracker.');
    }

    final List<dynamic> personagensBackup = dados['personagens'] ?? [];
    final List<dynamic> historicoBackup = dados['historico'] ?? [];
    final String personagemAtualBackup = dados['personagemAtualNome'] ?? 'Hero';
    final Map<String, dynamic>? perfilBackup = dados['perfilJogador'];

    setState(() {
      personagens = {
        for (final item in personagensBackup)
          Character.fromJson(item).name: Character.fromJson(item),
      };

      for (final personagemBase in personagensSmash) {
        personagens.putIfAbsent(personagemBase.name, () => personagemBase);
      }

      historico = historicoBackup
          .map((item) => PartidaRegistrada.fromJson(item))
          .toList();

      personagemAtualNome = personagens.containsKey(personagemAtualBackup)
          ? personagemAtualBackup
          : 'Hero';

      if (perfilBackup != null) {
        perfil = PlayerProfile.fromJson(perfilBackup);
      }

      recalcularPersonagensPeloHistorico();
    });

    await salvarDados();

    return arquivoMaisRecente.path;
  }

  void recalcularPersonagensPeloHistorico() {
    final Map<String, Character> novosPersonagens = {
      for (final personagem in personagensSmash) personagem.name: personagem,
    };

    final List<PartidaRegistrada> partidasEmOrdemCronologica =
        historico.reversed.toList();

    for (final partida in partidasEmOrdemCronologica) {
      final Character personagem =
          novosPersonagens[partida.personagemJogador] ??
              Character(
                name: partida.personagemJogador,
                initial: partida.personagemJogador.isNotEmpty
                    ? partida.personagemJogador[0].toUpperCase()
                    : '?',
                rank: 'Starter V',
                pdl: 0,
              );

      final int novoPdl = personagem.pdl + partida.pdlGerado;
      final int pdlCorrigido = novoPdl < 0 ? 0 : novoPdl;

      novosPersonagens[personagem.name] = personagem.copyWith(
        pdl: pdlCorrigido,
        rank: calcularRank(pdlCorrigido),
      );
    }

    personagens = novosPersonagens;

    if (!personagens.containsKey(personagemAtualNome)) {
      personagemAtualNome = 'Hero';
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

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('personagens');
    await prefs.remove('historico');
    await prefs.remove('personagemAtualNome');
    await prefs.remove('perfilJogador');

    setState(() {
      personagens = {
        for (final personagem in personagensSmash) personagem.name: personagem,
      };
      historico = [];
      personagemAtualNome = 'Hero';
      perfil = perfilPadrao;
    });
  }

  Future<void> abrirSelecaoDePersonagem() async {
    final Character? personagemEscolhido = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelecionarPersonagemPage(
          titulo: 'Escolher seu personagem',
          personagens: personagens.values.toList(),
        ),
      ),
    );

    if (personagemEscolhido != null) {
      setState(() {
        personagemAtualNome = personagemEscolhido.name;
      });

      await salvarDados();
    }
  }

  Future<void> abrirRegistrarPartida() async {
    final PartidaRegistrada? partida = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegistrarPartidaPage(
          personagemAtual: personagemAtual,
        ),
      ),
    );

    if (partida != null) {
      setState(() {
        historico.insert(0, partida);
        recalcularPersonagensPeloHistorico();
      });

      await salvarDados();
    }
  }

  Future<void> abrirHistorico() async {
    final bool? houveAlteracao = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HistoricoPage(
          historico: historico,
          personagemAtual: personagemAtual,
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
        builder: (context) => EstatisticasPage(
          personagemAtual: personagemAtual,
          historico: historico,
        ),
      ),
    );
  }

  void abrirResumoTreino() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResumoTreinoPage(
          personagemAtual: personagemAtual,
          historico: historico,
        ),
      ),
    );
  }

  Future<void> abrirPerfil() async {
    final PlayerProfile? perfilEditado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PerfilJogadorPage(
          perfil: perfil,
          personagemAtual: personagemAtual,
        ),
      ),
    );

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

  int get totalVitorias {
    return historico.where((partida) => partida.resultado == 'Vitória').length;
  }

  int get totalDerrotas {
    return historico.where((partida) => partida.resultado == 'Derrota').length;
  }

  @override
  Widget build(BuildContext context) {
    if (carregando) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final Character personagem = personagemAtual;

    return Scaffold(
      appBar: AppBar(
        title: const Text('LabTracker'),
        centerTitle: true,
        actions: [
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
        ],
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
            Text(
              perfil.regiao.trim().isEmpty
                  ? '${widget.jogoAtual} • ${personagem.name}'
                  : '${widget.jogoAtual} • ${personagem.name} • ${perfil.regiao}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      child: Text(
                        personagem.initial,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Perfil atual',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text('Jogo: ${widget.jogoAtual}'),
                          Text('Personagem: ${personagem.name}'),
                          Text('Rank: ${personagem.rank}'),
                          Text('PDL: ${personagem.pdl}'),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: abrirSelecaoDePersonagem,
                      child: const Text('Trocar personagem'),
                    ),
                  ],
                ),
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
                        valor: '${historico.length}',
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
                    onPressed: abrirRegistrarPartida,
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
                label: const Text('Resumo do treino de hoje'),
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

class InfoBox extends StatelessWidget {
  final String titulo;
  final String valor;

  const InfoBox({
    super.key,
    required this.titulo,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          valor,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(titulo),
      ],
    );
  }
}

class SelecionarPersonagemPage extends StatelessWidget {
  final String titulo;
  final List<Character> personagens;

  const SelecionarPersonagemPage({
    super.key,
    required this.titulo,
    this.personagens = personagensSmash,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: GridView.builder(
          itemCount: personagens.length,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 230,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.55,
          ),
          itemBuilder: (context, index) {
            final personagem = personagens[index];

            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.pop(context, personagem);
              },
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        child: Text(
                          personagem.initial,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              personagem.name,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(personagem.rank),
                            Text('${personagem.pdl} PDL'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class RegistrarPartidaPage extends StatefulWidget {
  final Character personagemAtual;

  const RegistrarPartidaPage({
    super.key,
    required this.personagemAtual,
  });

  @override
  State<RegistrarPartidaPage> createState() => _RegistrarPartidaPageState();
}

class _RegistrarPartidaPageState extends State<RegistrarPartidaPage> {
  String resultado = 'Vitória';
  String nickAdversario = '';
  Character? personagemAdversario;
  String stageSelecionado = stagesSmash[0];
  int stocks = 1;
  int porcentagem = 0;
  String formaDeKill = formasDeKill[0];
  String formaDeMorte = formasDeMorte[0];
  String observacoes = '';
  int pdlCalculado = 0;

  bool get venceu {
    return resultado == 'Vitória';
  }

  bool get naoMorreu {
    return resultado == 'Vitória' && stocks == 3;
  }

  bool get naoMatou {
    return resultado == 'Derrota' && stocks == 3;
  }

  String get labelStocks {
    return venceu ? 'Suas stocks restantes' : 'Stocks restantes do adversário';
  }

  String get labelPorcentagem {
    return venceu ? 'Sua porcentagem final' : 'Porcentagem final do adversário';
  }

  String get textoAvisoResultado {
    if (venceu) {
      return 'Vitória: informe quantas stocks VOCÊ terminou a partida e qual era a SUA porcentagem final.';
    }

    return 'Derrota: informe quantas stocks o ADVERSÁRIO terminou a partida e qual era a porcentagem final DELE.';
  }

  Future<void> escolherAdversario() async {
    final Character? adversarioEscolhido = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SelecionarPersonagemPage(
          titulo: 'Escolher personagem adversário',
        ),
      ),
    );

    if (adversarioEscolhido != null) {
      setState(() {
        personagemAdversario = adversarioEscolhido;
      });
    }
  }

  int gerarPdl() {
    final String killFinal = naoMatou ? 'Não matou' : formaDeKill;
    final String morteFinal = naoMorreu ? 'Não morreu' : formaDeMorte;

    return calcularPdlDaPartida(
      resultado: resultado,
      stocks: stocks,
      porcentagem: porcentagem,
      formaDeKill: killFinal,
      formaDeMorte: morteFinal,
    );
  }

  void calcularPdl() {
    setState(() {
      pdlCalculado = gerarPdl();
    });
  }

  void salvarPartida() {
    if (nickAdversario.trim().isEmpty) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Nick não informado'),
            content: const Text(
              'Digite o nick do adversário antes de salvar a partida.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Ok'),
              ),
            ],
          );
        },
      );

      return;
    }

    if (personagemAdversario == null) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Personagem adversário não escolhido'),
            content: const Text(
              'Escolha o personagem do adversário antes de salvar a partida.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Ok'),
              ),
            ],
          );
        },
      );

      return;
    }

    final int pdlFinal = gerarPdl();
    final String killFinal = naoMatou ? 'Não matou' : formaDeKill;
    final String morteFinal = naoMorreu ? 'Não morreu' : formaDeMorte;

    setState(() {
      pdlCalculado = pdlFinal;
    });

    final PartidaRegistrada partida = PartidaRegistrada(
      personagemJogador: widget.personagemAtual.name,
      nickAdversario: nickAdversario.trim(),
      personagemAdversario: personagemAdversario!.name,
      stage: stageSelecionado,
      resultado: resultado,
      stocks: stocks,
      porcentagem: porcentagem,
      formaDeKill: killFinal,
      formaDeMorte: morteFinal,
      observacoes: observacoes.trim(),
      pdlGerado: pdlFinal,
      data: DateTime.now(),
    );

    showDialog(
      context: context,
      builder: (context) {
        final String textoObservacoes =
            partida.observacoes.isEmpty ? 'Sem observações' : partida.observacoes;

        return AlertDialog(
          title: const Text('Partida registrada'),
          content: Text(
            'Seu personagem: ${partida.personagemJogador}\n'
            'Nick adversário: ${partida.nickAdversario}\n'
            'Personagem adversário: ${partida.personagemAdversario}\n'
            'Stage: ${partida.stage}\n'
            'Resultado: ${partida.resultado}\n'
            '$labelStocks: ${partida.stocks}\n'
            '$labelPorcentagem: ${partida.porcentagem}%\n'
            'Como matou: ${partida.formaDeKill}\n'
            'Como morreu: ${partida.formaDeMorte}\n'
            'Observações: $textoObservacoes\n'
            'PDL gerado: ${partida.pdlGerado}',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, partida);
              },
              child: const Text('Voltar para Home'),
            ),
          ],
        );
      },
    );
  }

  String get tituloConfronto {
    final adversario = personagemAdversario?.name ?? '???';
    final nick = nickAdversario.trim().isEmpty ? 'Sem nick' : nickAdversario;
    return '${widget.personagemAtual.name} vs $adversario • $nick';
  }

  @override
  Widget build(BuildContext context) {
    final String nomeAdversario =
        personagemAdversario?.name ?? 'Nenhum escolhido';
    final String inicialAdversario = personagemAdversario?.initial ?? '?';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar partida'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tituloConfronto,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Stage: $stageSelecionado',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            const Text(
              'Resultado',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'Vitória',
                  label: Text('Vitória'),
                ),
                ButtonSegment(
                  value: 'Derrota',
                  label: Text('Derrota'),
                ),
              ],
              selected: {resultado},
              onSelectionChanged: (valor) {
                setState(() {
                  resultado = valor.first;
                  pdlCalculado = gerarPdl();
                });
              },
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Atenção ao registrar stocks e porcentagem'),
                subtitle: Text(textoAvisoResultado),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Nick do adversário',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Nick do player',
                border: OutlineInputBorder(),
                hintText: 'Ex: SpitTrap19, Rafarofael, Grandmemes...',
              ),
              onChanged: (valor) {
                setState(() {
                  nickAdversario = valor;
                });
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Personagem adversário',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      child: Text(
                        inicialAdversario,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        nomeAdversario,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: escolherAdversario,
                      child: const Text('Escolher'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Stage / Mapa',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: stageSelecionado,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: stagesSmash.map((stage) {
                return DropdownMenuItem(
                  value: stage,
                  child: Text(stage),
                );
              }).toList(),
              onChanged: (valor) {
                setState(() {
                  stageSelecionado = valor ?? stagesSmash[0];
                });
              },
            ),
            const SizedBox(height: 24),
            Text(
              labelStocks,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: stocks,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 1,
                  child: Text('1 stock'),
                ),
                DropdownMenuItem(
                  value: 2,
                  child: Text('2 stocks'),
                ),
                DropdownMenuItem(
                  value: 3,
                  child: Text('3 stocks'),
                ),
              ],
              onChanged: (valor) {
                setState(() {
                  stocks = valor ?? 1;
                  pdlCalculado = gerarPdl();
                });
              },
            ),
            const SizedBox(height: 24),
            Text(
              labelPorcentagem,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: labelPorcentagem,
                border: const OutlineInputBorder(),
                hintText: 'Ex: 87',
                suffixText: '%',
              ),
              onChanged: (valor) {
                setState(() {
                  porcentagem = int.tryParse(valor) ?? 0;
                  pdlCalculado = gerarPdl();
                });
              },
            ),
            const SizedBox(height: 24),
            if (!naoMatou) ...[
              const Text(
                'Como você matou?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: formaDeKill,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: formasDeKill.map((forma) {
                  return DropdownMenuItem(
                    value: forma,
                    child: Text(forma),
                  );
                }).toList(),
                onChanged: (valor) {
                  setState(() {
                    formaDeKill = valor ?? formasDeKill[0];
                    pdlCalculado = gerarPdl();
                  });
                },
              ),
            ] else ...[
              Card(
                child: ListTile(
                  leading: const Icon(Icons.close_outlined),
                  title: const Text('Como você matou?'),
                  subtitle: const Text(
                    'Não matou — derrota sofrida com 3 stocks.',
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (!naoMorreu) ...[
              const Text(
                'Como você morreu?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: formaDeMorte,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: formasDeMorte.map((forma) {
                  return DropdownMenuItem(
                    value: forma,
                    child: Text(forma),
                  );
                }).toList(),
                onChanged: (valor) {
                  setState(() {
                    formaDeMorte = valor ?? formasDeMorte[0];
                    pdlCalculado = gerarPdl();
                  });
                },
              ),
            ] else ...[
              Card(
                child: ListTile(
                  leading: const Icon(Icons.shield_outlined),
                  title: const Text('Como você morreu?'),
                  subtitle: const Text(
                    'Não morreu — vitória com 3 stocks.',
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            const Text(
              'Observações da partida',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Anotações',
                border: OutlineInputBorder(),
                hintText:
                    'Ex: perdi muito no ledge, ataquei shield demais, adaptei bem no final...',
              ),
              onChanged: (valor) {
                observacoes = valor;
              },
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(Icons.trending_up),
                    const SizedBox(width: 16),
                    Text(
                      'PDL calculado: $pdlCalculado',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
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
                  child: OutlinedButton(
                    onPressed: calcularPdl,
                    child: const Text('Calcular PDL'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: salvarPartida,
                    child: const Text('Salvar partida'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class HistoricoPage extends StatefulWidget {
  final List<PartidaRegistrada> historico;
  final Character personagemAtual;

  const HistoricoPage({
    super.key,
    required this.historico,
    required this.personagemAtual,
  });

  @override
  State<HistoricoPage> createState() => _HistoricoPageState();
}

class _HistoricoPageState extends State<HistoricoPage> {
  String filtroResultado = 'Todos';
  bool apenasPersonagemAtual = false;
  String busca = '';
  bool houveAlteracao = false;

  String filtroPlayer = 'Todos';
  String filtroPersonagemAdversario = 'Todos';
  String filtroStage = 'Todos';
  String filtroKill = 'Todos';
  String filtroMorte = 'Todos';

  List<String> get opcoesPlayers {
    return gerarOpcoesFiltro(
      widget.historico.map((partida) => partida.nickAdversario).toList(),
    );
  }

  List<String> get opcoesPersonagensAdversarios {
    return gerarOpcoesFiltro(
      widget.historico.map((partida) => partida.personagemAdversario).toList(),
    );
  }

  List<String> get opcoesStages {
    return gerarOpcoesFiltro(
      widget.historico.map((partida) => partida.stage).toList(),
    );
  }

  List<String> get opcoesKills {
    return gerarOpcoesFiltro(
      widget.historico.map((partida) => partida.formaDeKill).toList(),
    );
  }

  List<String> get opcoesMortes {
    return gerarOpcoesFiltro(
      widget.historico.map((partida) => partida.formaDeMorte).toList(),
    );
  }

  bool get filtrosAvancadosAtivos {
    return filtroPlayer != 'Todos' ||
        filtroPersonagemAdversario != 'Todos' ||
        filtroStage != 'Todos' ||
        filtroKill != 'Todos' ||
        filtroMorte != 'Todos';
  }

  List<PartidaRegistrada> get historicoFiltrado {
    return widget.historico.where((partida) {
      final bool passaResultado =
          filtroResultado == 'Todos' || partida.resultado == filtroResultado;

      final bool passaPersonagem = !apenasPersonagemAtual ||
          partida.personagemJogador == widget.personagemAtual.name;

      final bool passaPlayer =
          filtroPlayer == 'Todos' || partida.nickAdversario == filtroPlayer;

      final bool passaAdversario = filtroPersonagemAdversario == 'Todos' ||
          partida.personagemAdversario == filtroPersonagemAdversario;

      final bool passaStage =
          filtroStage == 'Todos' || partida.stage == filtroStage;

      final bool passaKill =
          filtroKill == 'Todos' || partida.formaDeKill == filtroKill;

      final bool passaMorte =
          filtroMorte == 'Todos' || partida.formaDeMorte == filtroMorte;

      final textoBusca = busca.trim().toLowerCase();

      final bool passaBusca = textoBusca.isEmpty ||
          partida.nickAdversario.toLowerCase().contains(textoBusca) ||
          partida.personagemAdversario.toLowerCase().contains(textoBusca) ||
          partida.stage.toLowerCase().contains(textoBusca) ||
          partida.personagemJogador.toLowerCase().contains(textoBusca) ||
          partida.formaDeKill.toLowerCase().contains(textoBusca) ||
          partida.formaDeMorte.toLowerCase().contains(textoBusca) ||
          partida.observacoes.toLowerCase().contains(textoBusca);

      return passaResultado &&
          passaPersonagem &&
          passaPlayer &&
          passaAdversario &&
          passaStage &&
          passaKill &&
          passaMorte &&
          passaBusca;
    }).toList();
  }

  void limparFiltrosAvancados() {
    setState(() {
      filtroPlayer = 'Todos';
      filtroPersonagemAdversario = 'Todos';
      filtroStage = 'Todos';
      filtroKill = 'Todos';
      filtroMorte = 'Todos';
    });
  }

  Widget construirDropdownFiltro({
    required String label,
    required String valor,
    required List<String> opcoes,
    required ValueChanged<String> onChanged,
  }) {
    final String valorSeguro = opcoes.contains(valor) ? valor : 'Todos';

    return DropdownButtonFormField<String>(
      value: valorSeguro,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: opcoes.map((opcao) {
        return DropdownMenuItem(
          value: opcao,
          child: Text(opcao),
        );
      }).toList(),
      onChanged: (novoValor) {
        onChanged(novoValor ?? 'Todos');
      },
    );
  }

  Future<void> abrirDetalhes(PartidaRegistrada partida) async {
    final ResultadoDetalhesPartida? resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetalhesPartidaPage(
          partida: partida,
        ),
      ),
    );

    if (resultado == null) return;

    if (resultado.acao == 'apagar') {
      setState(() {
        widget.historico.remove(partida);
        houveAlteracao = true;
      });
    }

    if (resultado.acao == 'editar' && resultado.partidaEditada != null) {
      final int index = widget.historico.indexOf(partida);

      if (index != -1) {
        setState(() {
          widget.historico[index] = resultado.partidaEditada!;
          houveAlteracao = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final partidas = historicoFiltrado;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, houveAlteracao);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Histórico de partidas'),
          centerTitle: true,
        ),
        body: widget.historico.isEmpty
            ? const Center(
                child: Text(
                  'Nenhuma partida registrada ainda.',
                  style: TextStyle(fontSize: 18),
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                      children: [
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'Buscar no histórico',
                            hintText:
                                'Nick, personagem, stage, kill, morte ou observação...',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: (valor) {
                            setState(() {
                              busca = valor;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                              value: 'Todos',
                              label: Text('Todos'),
                            ),
                            ButtonSegment(
                              value: 'Vitória',
                              label: Text('Vitórias'),
                            ),
                            ButtonSegment(
                              value: 'Derrota',
                              label: Text('Derrotas'),
                            ),
                          ],
                          selected: {filtroResultado},
                          onSelectionChanged: (valor) {
                            setState(() {
                              filtroResultado = valor.first;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Mostrar só partidas com ${widget.personagemAtual.name}',
                          ),
                          value: apenasPersonagemAtual,
                          onChanged: (valor) {
                            setState(() {
                              apenasPersonagemAtual = valor;
                            });
                          },
                        ),
                        Card(
                          child: ExpansionTile(
                            initiallyExpanded: filtrosAvancadosAtivos,
                            leading: const Icon(Icons.filter_alt_outlined),
                            title: const Text('Filtros avançados'),
                            subtitle: Text(
                              filtrosAvancadosAtivos
                                  ? 'Filtros específicos ativos'
                                  : 'Player, personagem, stage, kill e morte',
                            ),
                            childrenPadding: const EdgeInsets.fromLTRB(
                              16,
                              0,
                              16,
                              16,
                            ),
                            children: [
                              construirDropdownFiltro(
                                label: 'Player',
                                valor: filtroPlayer,
                                opcoes: opcoesPlayers,
                                onChanged: (valor) {
                                  setState(() {
                                    filtroPlayer = valor;
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              construirDropdownFiltro(
                                label: 'Personagem adversário',
                                valor: filtroPersonagemAdversario,
                                opcoes: opcoesPersonagensAdversarios,
                                onChanged: (valor) {
                                  setState(() {
                                    filtroPersonagemAdversario = valor;
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              construirDropdownFiltro(
                                label: 'Stage',
                                valor: filtroStage,
                                opcoes: opcoesStages,
                                onChanged: (valor) {
                                  setState(() {
                                    filtroStage = valor;
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              construirDropdownFiltro(
                                label: 'Como matou',
                                valor: filtroKill,
                                opcoes: opcoesKills,
                                onChanged: (valor) {
                                  setState(() {
                                    filtroKill = valor;
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              construirDropdownFiltro(
                                label: 'Como morreu',
                                valor: filtroMorte,
                                opcoes: opcoesMortes,
                                onChanged: (valor) {
                                  setState(() {
                                    filtroMorte = valor;
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: limparFiltrosAvancados,
                                  icon: const Icon(Icons.clear),
                                  label: const Text('Limpar filtros avançados'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${partidas.length} partida(s) encontrada(s)',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (partidas.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 48),
                            child: Center(
                              child: Text(
                                'Nenhuma partida encontrada com esses filtros.',
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                          )
                        else
                          ...partidas.map((partida) {
                            final bool venceu = partida.resultado == 'Vitória';
                            final String sinalPdl =
                                partida.pdlGerado >= 0 ? '+' : '';

                            final String labelStocksHistorico = venceu
                                ? 'Suas stocks'
                                : 'Stocks do adversário';

                            final String labelPorcentagemHistorico =
                                venceu ? 'Sua %' : '% do adversário';

                            return Card(
                              child: ListTile(
                                onTap: () {
                                  abrirDetalhes(partida);
                                },
                                leading: CircleAvatar(
                                  child: Icon(
                                    venceu
                                        ? Icons.arrow_upward
                                        : Icons.arrow_downward,
                                  ),
                                ),
                                title: Text(
                                  '${partida.personagemJogador} vs ${partida.personagemAdversario}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  '${partida.resultado} • ${partida.stage}\n'
                                  'Nick: ${partida.nickAdversario} • $labelStocksHistorico: ${partida.stocks} • $labelPorcentagemHistorico: ${partida.porcentagem}%\n'
                                  'Kill: ${partida.formaDeKill} • Morte: ${partida.formaDeMorte}',
                                ),
                                trailing: Text(
                                  '$sinalPdl${partida.pdlGerado} PDL',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class DetalhesPartidaPage extends StatelessWidget {
  final PartidaRegistrada partida;

  const DetalhesPartidaPage({
    super.key,
    required this.partida,
  });

  Future<void> confirmarApagar(BuildContext context) async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Apagar partida?'),
          content: const Text(
            'Essa ação vai remover a partida do histórico e recalcular o PDL do personagem.',
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
              child: const Text('Apagar'),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      Navigator.pop(context, const ResultadoDetalhesPartida.apagar());
    }
  }

  Future<void> abrirEditar(BuildContext context) async {
    final PartidaRegistrada? partidaEditada = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditarPartidaPage(
          partida: partida,
        ),
      ),
    );

    if (partidaEditada != null) {
      Navigator.pop(
        context,
        ResultadoDetalhesPartida.editar(partidaEditada),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool venceu = partida.resultado == 'Vitória';
    final String sinalPdl = partida.pdlGerado >= 0 ? '+' : '';

    final String labelStocks =
        venceu ? 'Suas stocks restantes' : 'Stocks restantes do adversário';

    final String labelPorcentagem =
        venceu ? 'Sua porcentagem final' : 'Porcentagem final do adversário';

    final String textoObservacoes =
        partida.observacoes.trim().isEmpty ? 'Sem observações' : partida.observacoes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da partida'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              abrirEditar(context);
            },
            tooltip: 'Editar partida',
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            onPressed: () {
              confirmarApagar(context);
            },
            tooltip: 'Apagar partida',
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${partida.personagemJogador} vs ${partida.personagemAdversario}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Contra ${partida.nickAdversario}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    LinhaEstatistica(
                      titulo: 'Resultado',
                      valor: partida.resultado,
                    ),
                    LinhaEstatistica(
                      titulo: 'PDL gerado',
                      valor: '$sinalPdl${partida.pdlGerado}',
                    ),
                    LinhaEstatistica(
                      titulo: 'Stage',
                      valor: partida.stage,
                    ),
                    LinhaEstatistica(
                      titulo: labelStocks,
                      valor: '${partida.stocks}',
                    ),
                    LinhaEstatistica(
                      titulo: labelPorcentagem,
                      valor: '${partida.porcentagem}%',
                    ),
                    LinhaEstatistica(
                      titulo: 'Como matou',
                      valor: partida.formaDeKill,
                    ),
                    LinhaEstatistica(
                      titulo: 'Como morreu',
                      valor: partida.formaDeMorte,
                    ),
                    LinhaEstatistica(
                      titulo: 'Data',
                      valor: formatarData(partida.data),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Observações',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(textoObservacoes),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  abrirEditar(context);
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Editar partida'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  confirmarApagar(context);
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Apagar partida'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EditarPartidaPage extends StatefulWidget {
  final PartidaRegistrada partida;

  const EditarPartidaPage({
    super.key,
    required this.partida,
  });

  @override
  State<EditarPartidaPage> createState() => _EditarPartidaPageState();
}

class _EditarPartidaPageState extends State<EditarPartidaPage> {
  late Character personagemJogador;
  late Character? personagemAdversario;
  late String resultado;
  late String nickAdversario;
  late String stageSelecionado;
  late int stocks;
  late int porcentagem;
  late String formaDeKill;
  late String formaDeMorte;
  late String observacoes;
  late int pdlCalculado;

  late TextEditingController nickController;
  late TextEditingController porcentagemController;
  late TextEditingController observacoesController;

  @override
  void initState() {
    super.initState();

    personagemJogador = personagemPorNome(widget.partida.personagemJogador);
    personagemAdversario = personagemPorNome(widget.partida.personagemAdversario);

    resultado = widget.partida.resultado;
    nickAdversario = widget.partida.nickAdversario;
    stageSelecionado = stagesSmash.contains(widget.partida.stage)
        ? widget.partida.stage
        : stagesSmash[0];
    stocks = widget.partida.stocks;
    porcentagem = widget.partida.porcentagem;

    formaDeKill = formasDeKill.contains(widget.partida.formaDeKill)
        ? widget.partida.formaDeKill
        : formasDeKill[0];

    formaDeMorte = formasDeMorte.contains(widget.partida.formaDeMorte)
        ? widget.partida.formaDeMorte
        : formasDeMorte[0];

    observacoes = widget.partida.observacoes;
    pdlCalculado = gerarPdl();

    nickController = TextEditingController(text: nickAdversario);
    porcentagemController = TextEditingController(text: porcentagem.toString());
    observacoesController = TextEditingController(text: observacoes);
  }

  @override
  void dispose() {
    nickController.dispose();
    porcentagemController.dispose();
    observacoesController.dispose();
    super.dispose();
  }

  bool get venceu {
    return resultado == 'Vitória';
  }

  bool get naoMorreu {
    return resultado == 'Vitória' && stocks == 3;
  }

  bool get naoMatou {
    return resultado == 'Derrota' && stocks == 3;
  }

  String get labelStocks {
    return venceu ? 'Suas stocks restantes' : 'Stocks restantes do adversário';
  }

  String get labelPorcentagem {
    return venceu ? 'Sua porcentagem final' : 'Porcentagem final do adversário';
  }

  String get textoAvisoResultado {
    if (venceu) {
      return 'Vitória: informe quantas stocks VOCÊ terminou a partida e qual era a SUA porcentagem final.';
    }

    return 'Derrota: informe quantas stocks o ADVERSÁRIO terminou a partida e qual era a porcentagem final DELE.';
  }

  Future<void> escolherPersonagemJogador() async {
    final Character? personagemEscolhido = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SelecionarPersonagemPage(
          titulo: 'Editar seu personagem',
        ),
      ),
    );

    if (personagemEscolhido != null) {
      setState(() {
        personagemJogador = personagemEscolhido;
      });
    }
  }

  Future<void> escolherAdversario() async {
    final Character? adversarioEscolhido = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SelecionarPersonagemPage(
          titulo: 'Editar personagem adversário',
        ),
      ),
    );

    if (adversarioEscolhido != null) {
      setState(() {
        personagemAdversario = adversarioEscolhido;
      });
    }
  }

  int gerarPdl() {
    final String killFinal = naoMatou ? 'Não matou' : formaDeKill;
    final String morteFinal = naoMorreu ? 'Não morreu' : formaDeMorte;

    return calcularPdlDaPartida(
      resultado: resultado,
      stocks: stocks,
      porcentagem: porcentagem,
      formaDeKill: killFinal,
      formaDeMorte: morteFinal,
    );
  }

  void salvarEdicao() {
    if (nickAdversario.trim().isEmpty) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Nick não informado'),
            content: const Text(
              'Digite o nick do adversário antes de salvar a edição.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Ok'),
              ),
            ],
          );
        },
      );

      return;
    }

    if (personagemAdversario == null) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Personagem adversário não escolhido'),
            content: const Text(
              'Escolha o personagem do adversário antes de salvar a edição.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Ok'),
              ),
            ],
          );
        },
      );

      return;
    }

    final int pdlFinal = gerarPdl();
    final String killFinal = naoMatou ? 'Não matou' : formaDeKill;
    final String morteFinal = naoMorreu ? 'Não morreu' : formaDeMorte;

    final PartidaRegistrada partidaEditada = PartidaRegistrada(
      personagemJogador: personagemJogador.name,
      nickAdversario: nickAdversario.trim(),
      personagemAdversario: personagemAdversario!.name,
      stage: stageSelecionado,
      resultado: resultado,
      stocks: stocks,
      porcentagem: porcentagem,
      formaDeKill: killFinal,
      formaDeMorte: morteFinal,
      observacoes: observacoes.trim(),
      pdlGerado: pdlFinal,
      data: widget.partida.data,
    );

    Navigator.pop(context, partidaEditada);
  }

  String get tituloConfronto {
    final adversario = personagemAdversario?.name ?? '???';
    final nick = nickAdversario.trim().isEmpty ? 'Sem nick' : nickAdversario;
    return '${personagemJogador.name} vs $adversario • $nick';
  }

  @override
  Widget build(BuildContext context) {
    final String nomeAdversario =
        personagemAdversario?.name ?? 'Nenhum escolhido';
    final String inicialAdversario = personagemAdversario?.initial ?? '?';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar partida'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tituloConfronto,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Stage: $stageSelecionado',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            const Text(
              'Seu personagem',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      child: Text(
                        personagemJogador.initial,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        personagemJogador.name,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: escolherPersonagemJogador,
                      child: const Text('Trocar'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Resultado',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'Vitória',
                  label: Text('Vitória'),
                ),
                ButtonSegment(
                  value: 'Derrota',
                  label: Text('Derrota'),
                ),
              ],
              selected: {resultado},
              onSelectionChanged: (valor) {
                setState(() {
                  resultado = valor.first;
                  pdlCalculado = gerarPdl();
                });
              },
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Atenção ao editar stocks e porcentagem'),
                subtitle: Text(textoAvisoResultado),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Nick do adversário',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: nickController,
              decoration: const InputDecoration(
                labelText: 'Nick do player',
                border: OutlineInputBorder(),
              ),
              onChanged: (valor) {
                setState(() {
                  nickAdversario = valor;
                });
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Personagem adversário',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      child: Text(
                        inicialAdversario,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        nomeAdversario,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: escolherAdversario,
                      child: const Text('Trocar'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Stage / Mapa',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: stagesSmash.contains(stageSelecionado)
                  ? stageSelecionado
                  : stagesSmash[0],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: stagesSmash.map((stage) {
                return DropdownMenuItem(
                  value: stage,
                  child: Text(stage),
                );
              }).toList(),
              onChanged: (valor) {
                setState(() {
                  stageSelecionado = valor ?? stagesSmash[0];
                });
              },
            ),
            const SizedBox(height: 24),
            Text(
              labelStocks,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: stocks,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 1,
                  child: Text('1 stock'),
                ),
                DropdownMenuItem(
                  value: 2,
                  child: Text('2 stocks'),
                ),
                DropdownMenuItem(
                  value: 3,
                  child: Text('3 stocks'),
                ),
              ],
              onChanged: (valor) {
                setState(() {
                  stocks = valor ?? 1;
                  pdlCalculado = gerarPdl();
                });
              },
            ),
            const SizedBox(height: 24),
            Text(
              labelPorcentagem,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: porcentagemController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: labelPorcentagem,
                border: const OutlineInputBorder(),
                suffixText: '%',
              ),
              onChanged: (valor) {
                setState(() {
                  porcentagem = int.tryParse(valor) ?? 0;
                  pdlCalculado = gerarPdl();
                });
              },
            ),
            const SizedBox(height: 24),
            if (!naoMatou) ...[
              const Text(
                'Como você matou?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: formaDeKill,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: formasDeKill.map((forma) {
                  return DropdownMenuItem(
                    value: forma,
                    child: Text(forma),
                  );
                }).toList(),
                onChanged: (valor) {
                  setState(() {
                    formaDeKill = valor ?? formasDeKill[0];
                    pdlCalculado = gerarPdl();
                  });
                },
              ),
            ] else ...[
              Card(
                child: ListTile(
                  leading: const Icon(Icons.close_outlined),
                  title: const Text('Como você matou?'),
                  subtitle: const Text(
                    'Não matou — derrota sofrida com 3 stocks.',
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (!naoMorreu) ...[
              const Text(
                'Como você morreu?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: formaDeMorte,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: formasDeMorte.map((forma) {
                  return DropdownMenuItem(
                    value: forma,
                    child: Text(forma),
                  );
                }).toList(),
                onChanged: (valor) {
                  setState(() {
                    formaDeMorte = valor ?? formasDeMorte[0];
                    pdlCalculado = gerarPdl();
                  });
                },
              ),
            ] else ...[
              Card(
                child: ListTile(
                  leading: const Icon(Icons.shield_outlined),
                  title: const Text('Como você morreu?'),
                  subtitle: const Text(
                    'Não morreu — vitória com 3 stocks.',
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            const Text(
              'Observações da partida',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: observacoesController,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Anotações',
                border: OutlineInputBorder(),
              ),
              onChanged: (valor) {
                observacoes = valor;
              },
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(Icons.trending_up),
                    const SizedBox(width: 16),
                    Text(
                      'PDL recalculado: $pdlCalculado',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: salvarEdicao,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Salvar edição'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class ResumoTreinoPage extends StatelessWidget {
  final Character personagemAtual;
  final List<PartidaRegistrada> historico;

  const ResumoTreinoPage({
    super.key,
    required this.personagemAtual,
    required this.historico,
  });

  String gerarSugestaoTreino({
    required String morteMaisComum,
    required String matchupMaisJogado,
    required double winrate,
  }) {
    if (morteMaisComum == 'SD') {
      return 'Foco recomendado: jogar mais calmo e reduzir SDs antes de pensar em jogada bonita.';
    }

    if (morteMaisComum == 'Recovery errado') {
      return 'Foco recomendado: treinar recovery, rotas de volta pro palco e evitar gastar recurso cedo.';
    }

    if (morteMaisComum == 'Panic option') {
      return 'Foco recomendado: segurar mais o controle sob pressão e escolher menos opções automáticas.';
    }

    if (morteMaisComum == 'Punish sofrido') {
      return 'Foco recomendado: atacar menos no escudo e revisar quais golpes ficaram puníveis.';
    }

    if (morteMaisComum == 'Edgeguard sofrido') {
      return 'Foco recomendado: variar recovery e evitar voltar sempre pelo mesmo caminho.';
    }

    if (morteMaisComum == 'Ledgetrap sofrido') {
      return 'Foco recomendado: variar opção da ledge e observar o padrão de cobertura do adversário.';
    }

    if (morteMaisComum == 'Morreu cedo') {
      return 'Foco recomendado: jogar o começo dos stocks com mais segurança e evitar trocas ruins.';
    }

    if (morteMaisComum == 'Read do adversário') {
      return 'Foco recomendado: quebrar hábitos repetidos, principalmente em disadvantage.';
    }

    if (winrate < 50 && matchupMaisJogado != 'Sem dados') {
      return 'Foco recomendado: revisar o matchup contra $matchupMaisJogado, porque ele foi um dos pontos mais difíceis do treino.';
    }

    return 'Foco recomendado: manter o ritmo e revisar as partidas com maior perda de PDL.';
  }

  @override
  Widget build(BuildContext context) {
    final DateTime hoje = DateTime.now();

    final List<PartidaRegistrada> partidasHoje = historico
        .where((partida) => isMesmoDia(partida.data, hoje))
        .toList();

    final List<PartidaRegistrada> partidasHojePersonagem = partidasHoje
        .where((partida) => partida.personagemJogador == personagemAtual.name)
        .toList();

    final int totalPartidas = partidasHojePersonagem.length;
    final int vitorias = partidasHojePersonagem
        .where((partida) => partida.resultado == 'Vitória')
        .length;
    final int derrotas = partidasHojePersonagem
        .where((partida) => partida.resultado == 'Derrota')
        .length;

    final int saldoPdl = partidasHojePersonagem.fold(
      0,
      (soma, partida) => soma + partida.pdlGerado,
    );

    final double winrate =
        totalPartidas == 0 ? 0 : (vitorias / totalPartidas) * 100;

    final String killMaisComum = encontrarMaisFrequente(
      partidasHojePersonagem.map((partida) => partida.formaDeKill).toList(),
    );

    final String morteMaisComum = encontrarMaisFrequente(
      partidasHojePersonagem.map((partida) => partida.formaDeMorte).toList(),
    );

    final String matchupMaisJogado = encontrarMaisFrequente(
      partidasHojePersonagem
          .map((partida) => partida.personagemAdversario)
          .toList(),
    );

    final String playerMaisEnfrentado = encontrarMaisFrequente(
      partidasHojePersonagem.map((partida) => partida.nickAdversario).toList(),
    );

    final List<MatchupResumo> matchupsHoje = gerarRankingMatchups(
      partidasHojePersonagem,
    );

    final List<PartidaRegistrada> partidasComObservacoes = partidasHojePersonagem
        .where((partida) => partida.observacoes.trim().isNotEmpty)
        .take(5)
        .toList();

    final String sinalPdl = saldoPdl >= 0 ? '+' : '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumo do treino'),
        centerTitle: true,
      ),
      body: totalPartidas == 0
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumo de hoje - ${personagemAtual.name}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'Ainda não existem partidas registradas hoje com esse personagem.',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumo de hoje - ${personagemAtual.name}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Baseado nas partidas registradas hoje.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Expanded(
                            child: InfoBox(
                              titulo: 'Partidas',
                              valor: '$totalPartidas',
                            ),
                          ),
                          Expanded(
                            child: InfoBox(
                              titulo: 'Vitórias',
                              valor: '$vitorias',
                            ),
                          ),
                          Expanded(
                            child: InfoBox(
                              titulo: 'Derrotas',
                              valor: '$derrotas',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Desempenho do dia',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          LinhaEstatistica(
                            titulo: 'Winrate',
                            valor: '${winrate.toStringAsFixed(1)}%',
                          ),
                          LinhaEstatistica(
                            titulo: 'Saldo de PDL',
                            valor: '$sinalPdl$saldoPdl',
                          ),
                          LinhaEstatistica(
                            titulo: 'Kill mais comum',
                            valor: killMaisComum,
                          ),
                          LinhaEstatistica(
                            titulo: 'Morte mais comum',
                            valor: morteMaisComum,
                          ),
                          LinhaEstatistica(
                            titulo: 'Matchup mais jogado',
                            valor: matchupMaisJogado,
                          ),
                          LinhaEstatistica(
                            titulo: 'Player mais enfrentado',
                            valor: playerMaisEnfrentado,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Foco sugerido',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            gerarSugestaoTreino(
                              morteMaisComum: morteMaisComum,
                              matchupMaisJogado: matchupMaisJogado,
                              winrate: winrate,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Matchups de hoje',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (matchupsHoje.isEmpty)
                            const Text('Sem dados')
                          else
                            ...matchupsHoje.map((matchup) {
                              final String sinalMatchup =
                                  matchup.saldoPdl >= 0 ? '+' : '';

                              return LinhaEstatistica(
                                titulo:
                                    '${personagemAtual.name} vs ${matchup.personagemAdversario}',
                                valor:
                                    '${matchup.total}x • ${matchup.winrate.toStringAsFixed(1)}% • $sinalMatchup${matchup.saldoPdl} PDL',
                              );
                            }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Observações de hoje',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (partidasComObservacoes.isEmpty)
                            const Text('Nenhuma observação registrada hoje.')
                          else
                            ...partidasComObservacoes.map((partida) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  '${partida.personagemJogador} vs ${partida.personagemAdversario} • ${partida.nickAdversario}: ${partida.observacoes}',
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class EstatisticasPage extends StatelessWidget {
  final Character personagemAtual;
  final List<PartidaRegistrada> historico;

  const EstatisticasPage({
    super.key,
    required this.personagemAtual,
    required this.historico,
  });

  void abrirMatchupStats(
    BuildContext context,
    List<PartidaRegistrada> partidasDoPersonagem,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MatchupStatsPage(
          personagemAtual: personagemAtual,
          partidasDoPersonagem: partidasDoPersonagem,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<PartidaRegistrada> partidasDoPersonagem = historico
        .where((partida) => partida.personagemJogador == personagemAtual.name)
        .toList();

    final int totalPartidas = partidasDoPersonagem.length;
    final int vitorias = partidasDoPersonagem
        .where((partida) => partida.resultado == 'Vitória')
        .length;
    final int derrotas = partidasDoPersonagem
        .where((partida) => partida.resultado == 'Derrota')
        .length;

    final double winrate =
        totalPartidas == 0 ? 0 : (vitorias / totalPartidas) * 100;

    final int pdlGanho = partidasDoPersonagem
        .where((partida) => partida.pdlGerado > 0)
        .fold(0, (soma, partida) => soma + partida.pdlGerado);

    final int pdlPerdido = partidasDoPersonagem
        .where((partida) => partida.pdlGerado < 0)
        .fold(0, (soma, partida) => soma + partida.pdlGerado);

    final int saldoPdl = partidasDoPersonagem.fold(
      0,
      (soma, partida) => soma + partida.pdlGerado,
    );

    final double mediaPdl =
        totalPartidas == 0 ? 0 : saldoPdl / totalPartidas;

    final List<PlayerResumo> rankingPlayers = gerarRankingPlayers(
      partidasDoPersonagem,
    );

    final List<MatchupResumo> rankingMatchups = gerarRankingMatchups(
      partidasDoPersonagem,
    );

    final String nickMaisEnfrentado =
        rankingPlayers.isEmpty ? 'Sem dados' : rankingPlayers.first.nick;

    final String adversarioMaisEnfrentado = encontrarMaisFrequente(
      partidasDoPersonagem
          .map((partida) => partida.personagemAdversario)
          .toList(),
    );

    final String stageMaisJogado = encontrarMaisFrequente(
      partidasDoPersonagem.map((partida) => partida.stage).toList(),
    );

    final String killMaisComum = encontrarMaisFrequente(
      partidasDoPersonagem.map((partida) => partida.formaDeKill).toList(),
    );

    final String morteMaisComum = encontrarMaisFrequente(
      partidasDoPersonagem.map((partida) => partida.formaDeMorte).toList(),
    );

    final MatchupResumo? melhorMatchup = melhorMatchupPorWinrate(
      rankingMatchups,
    );
    final MatchupResumo? piorMatchup = piorMatchupPorWinrate(
      rankingMatchups,
    );
    final MatchupResumo? maiorGanho = maiorGanhoPdlPorMatchup(
      rankingMatchups,
    );
    final MatchupResumo? maiorPerda = maiorPerdaPdlPorMatchup(
      rankingMatchups,
    );

    final String nomePiorMatchup = piorMatchup?.personagemAdversario ?? 'Sem dados';
    final String focoAutomatico = gerarFocoAutomatico(
      morteMaisComum,
      nomePiorMatchup,
    );

    final List<PartidaRegistrada> ultimasPartidas =
        partidasDoPersonagem.take(5).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estatísticas'),
        centerTitle: true,
      ),
      body: totalPartidas == 0
          ? Center(
              child: Text(
                'Ainda não existem partidas registradas com ${personagemAtual.name}.',
                style: const TextStyle(fontSize: 18),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estatísticas de ${personagemAtual.name}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${personagemAtual.rank} • ${personagemAtual.pdl} PDL',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Expanded(
                            child: InfoBox(
                              titulo: 'Partidas',
                              valor: '$totalPartidas',
                            ),
                          ),
                          Expanded(
                            child: InfoBox(
                              titulo: 'Vitórias',
                              valor: '$vitorias',
                            ),
                          ),
                          Expanded(
                            child: InfoBox(
                              titulo: 'Derrotas',
                              valor: '$derrotas',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Desempenho geral',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          LinhaEstatistica(
                            titulo: 'Winrate',
                            valor: '${winrate.toStringAsFixed(1)}%',
                          ),
                          LinhaEstatistica(
                            titulo: 'Saldo de PDL',
                            valor: formatarSaldo(saldoPdl),
                          ),
                          LinhaEstatistica(
                            titulo: 'PDL ganho',
                            valor: '+$pdlGanho',
                          ),
                          LinhaEstatistica(
                            titulo: 'PDL perdido',
                            valor: '$pdlPerdido',
                          ),
                          LinhaEstatistica(
                            titulo: 'Média de PDL por partida',
                            valor: mediaPdl >= 0
                                ? '+${mediaPdl.toStringAsFixed(1)}'
                                : mediaPdl.toStringAsFixed(1),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Leitura automática',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          LinhaEstatistica(
                            titulo: 'Melhor matchup',
                            valor: melhorMatchup == null
                                ? 'Sem dados'
                                : '${melhorMatchup.personagemAdversario} • ${melhorMatchup.winrate.toStringAsFixed(1)}% WR',
                          ),
                          LinhaEstatistica(
                            titulo: 'Matchup problema',
                            valor: piorMatchup == null
                                ? 'Sem dados'
                                : '${piorMatchup.personagemAdversario} • ${piorMatchup.winrate.toStringAsFixed(1)}% WR',
                          ),
                          LinhaEstatistica(
                            titulo: 'Maior ganho de PDL',
                            valor: maiorGanho == null
                                ? 'Sem dados'
                                : '${maiorGanho.personagemAdversario} • ${formatarSaldo(maiorGanho.saldoPdl)}',
                          ),
                          LinhaEstatistica(
                            titulo: 'Maior perda de PDL',
                            valor: maiorPerda == null
                                ? 'Sem dados'
                                : '${maiorPerda.personagemAdversario} • ${formatarSaldo(maiorPerda.saldoPdl)}',
                          ),
                          LinhaEstatistica(
                            titulo: 'Ponto forte',
                            valor: killMaisComum == 'Sem dados'
                                ? 'Sem dados'
                                : 'Você mais mata com $killMaisComum',
                          ),
                          LinhaEstatistica(
                            titulo: 'Ponto fraco',
                            valor: morteMaisComum == 'Sem dados'
                                ? 'Sem dados'
                                : 'Você mais morre por $morteMaisComum',
                          ),
                          const SizedBox(height: 12),
                          Text(
                            focoAutomatico,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        abrirMatchupStats(context, partidasDoPersonagem);
                      },
                      icon: const Icon(Icons.sports_mma),
                      label: const Text('Ver Matchup Stats'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Padrões encontrados',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          LinhaEstatistica(
                            titulo: 'Nick mais enfrentado',
                            valor: nickMaisEnfrentado,
                          ),
                          LinhaEstatistica(
                            titulo: 'Personagem mais enfrentado',
                            valor: adversarioMaisEnfrentado,
                          ),
                          LinhaEstatistica(
                            titulo: 'Stage mais jogado',
                            valor: stageMaisJogado,
                          ),
                          LinhaEstatistica(
                            titulo: 'Kill mais comum',
                            valor: killMaisComum,
                          ),
                          LinhaEstatistica(
                            titulo: 'Morte mais comum',
                            valor: morteMaisComum,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Players enfrentados',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (rankingPlayers.isEmpty)
                            const Text('Sem dados')
                          else
                            ...rankingPlayers.map((player) {
                              return LinhaEstatistica(
                                titulo: player.nick,
                                valor:
                                    '${player.total}x • ${player.vitorias}V / ${player.derrotas}D',
                              );
                            }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Últimas partidas com esse personagem',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...ultimasPartidas.map((partida) {
                            final String sinalPdl =
                                partida.pdlGerado >= 0 ? '+' : '';

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${partida.personagemJogador} vs ${partida.personagemAdversario} • ${partida.nickAdversario} • ${partida.resultado}',
                                    ),
                                  ),
                                  Text(
                                    '$sinalPdl${partida.pdlGerado} PDL',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class MatchupStatsPage extends StatelessWidget {
  final Character personagemAtual;
  final List<PartidaRegistrada> partidasDoPersonagem;

  const MatchupStatsPage({
    super.key,
    required this.personagemAtual,
    required this.partidasDoPersonagem,
  });

  @override
  Widget build(BuildContext context) {
    final List<MatchupResumo> matchups = gerarRankingMatchups(
      partidasDoPersonagem,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Matchup Stats'),
        centerTitle: true,
      ),
      body: matchups.isEmpty
          ? Center(
              child: Text(
                'Ainda não existem matchups registrados com ${personagemAtual.name}.',
                style: const TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: matchups.length,
              itemBuilder: (context, index) {
                final matchup = matchups[index];
                final String sinalPdl = matchup.saldoPdl >= 0 ? '+' : '';

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${personagemAtual.name} vs ${matchup.personagemAdversario}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        LinhaEstatistica(
                          titulo: 'Partidas',
                          valor: '${matchup.total}',
                        ),
                        LinhaEstatistica(
                          titulo: 'Vitórias / Derrotas',
                          valor: '${matchup.vitorias}V / ${matchup.derrotas}D',
                        ),
                        LinhaEstatistica(
                          titulo: 'Winrate',
                          valor: '${matchup.winrate.toStringAsFixed(1)}%',
                        ),
                        LinhaEstatistica(
                          titulo: 'Saldo de PDL',
                          valor: '$sinalPdl${matchup.saldoPdl}',
                        ),
                        LinhaEstatistica(
                          titulo: 'Kill mais comum',
                          valor: matchup.killMaisComum,
                        ),
                        LinhaEstatistica(
                          titulo: 'Morte mais comum',
                          valor: matchup.morteMaisComum,
                        ),
                        LinhaEstatistica(
                          titulo: 'Stage mais jogado',
                          valor: matchup.stageMaisJogado,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}



class PerfilJogadorPage extends StatefulWidget {
  final PlayerProfile perfil;
  final Character personagemAtual;

  const PerfilJogadorPage({
    super.key,
    required this.perfil,
    required this.personagemAtual,
  });

  @override
  State<PerfilJogadorPage> createState() => _PerfilJogadorPageState();
}

class _PerfilJogadorPageState extends State<PerfilJogadorPage> {
  late TextEditingController nickController;
  late TextEditingController regiaoController;

  @override
  void initState() {
    super.initState();
    nickController = TextEditingController(text: widget.perfil.nick);
    regiaoController = TextEditingController(text: widget.perfil.regiao);
  }

  @override
  void dispose() {
    nickController.dispose();
    regiaoController.dispose();
    super.dispose();
  }

  void salvarPerfil() {
    if (nickController.text.trim().isEmpty) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Nick não informado'),
            content: const Text('Digite seu nick antes de salvar o perfil.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Ok'),
              ),
            ],
          );
        },
      );

      return;
    }

    final PlayerProfile perfilEditado = widget.perfil.copyWith(
      nick: nickController.text.trim(),
      regiao: regiaoController.text.trim(),
      tagSecundaria: '',
      jogoPrincipal: '',
      mainPrincipal: '',
      bio: '',
    );

    Navigator.pop(context, perfilEditado);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu perfil'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Meu perfil',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Mantenha só o essencial: seu nick e, se quiser, sua região.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        TextField(
                          controller: nickController,
                          decoration: const InputDecoration(
                            labelText: 'Nick',
                            border: OutlineInputBorder(),
                            hintText: 'Ex: Flawlees',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: regiaoController,
                          decoration: const InputDecoration(
                            labelText: 'Região opcional',
                            border: OutlineInputBorder(),
                            hintText: 'Ex: SC - Brasil',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: salvarPerfil,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Salvar perfil'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ConfiguracoesPage extends StatelessWidget {
  final String pastaBackupPath;
  final Future<String> Function() exportarBackup;
  final Future<String> Function() importarBackupMaisRecente;
  final Future<void> Function() abrirPerfil;

  const ConfiguracoesPage({
    super.key,
    required this.pastaBackupPath,
    required this.exportarBackup,
    required this.importarBackupMaisRecente,
    required this.abrirPerfil,
  });

  Future<void> mostrarMensagem(
    BuildContext context,
    String titulo,
    String mensagem,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(titulo),
          content: SelectableText(mensagem),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Ok'),
            ),
          ],
        );
      },
    );
  }

  Future<void> confirmarImportacao(BuildContext context) async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Importar backup?'),
          content: const Text(
            'Isso vai substituir os dados atuais pelo backup mais recente encontrado na pasta de backups.',
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
              child: const Text('Importar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    try {
      final String caminho = await importarBackupMaisRecente();

      if (!context.mounted) return;

      await mostrarMensagem(
        context,
        'Backup importado',
        'Dados restaurados com sucesso de:\n\n$caminho',
      );
    } catch (erro) {
      if (!context.mounted) return;

      await mostrarMensagem(
        context,
        'Erro ao importar',
        erro.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> executarExportacao(BuildContext context) async {
    try {
      final String caminho = await exportarBackup();

      if (!context.mounted) return;

      await mostrarMensagem(
        context,
        'Backup exportado',
        'Backup salvo com sucesso em:\n\n$caminho',
      );
    } catch (erro) {
      if (!context.mounted) return;

      await mostrarMensagem(
        context,
        'Erro ao exportar',
        erro.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup e configurações'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Backup local',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Exporte seus dados para não perder histórico, PDL, ranks e observações.',
            ),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Meu perfil'),
                subtitle: const Text('Editar nick e região.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: abrirPerfil,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pasta dos backups',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SelectableText(pastaBackupPath),
                    const SizedBox(height: 12),
                    const Text(
                      'Os arquivos são salvos em formato .json. Você pode copiar essa pasta para o Drive, pendrive ou outro PC.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  executarExportacao(context);
                },
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('Exportar backup'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  confirmarImportacao(context);
                },
                icon: const Icon(Icons.download_outlined),
                label: const Text('Importar backup mais recente'),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Como usar',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      '1. Clique em Exportar backup depois de sessões importantes.\n'
                      '2. Guarde o arquivo .json em um lugar seguro.\n'
                      '3. Para restaurar, coloque o arquivo na pasta de backups e clique em Importar backup mais recente.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LinhaEstatistica extends StatelessWidget {
  final String titulo;
  final String valor;

  const LinhaEstatistica({
    super.key,
    required this.titulo,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(titulo),
          ),
          Text(
            valor,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
