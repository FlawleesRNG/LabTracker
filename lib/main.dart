
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const LabTrackerApp());
}

/// Wrapper do login com Google (API v7 do google_sign_in).
///
/// Em mobile (Android/iOS) usa o fluxo nativo. Em plataformas sem suporte
/// (ex.: Windows desktop) `suportado` é false e a tela cai no login manual.
///
/// Configuração necessária (feita FORA do código, no Google Cloud):
///  - Android: criar um OAuth Client ID com o package name + SHA-1, ou
///    informar o `serverClientId` abaixo.
///  - iOS: adicionar o REVERSED_CLIENT_ID no Info.plist.
class GoogleAuthService {
  // Web client ID do Google Cloud (tipo "Aplicativo da Web"). A API nova do
  // google_sign_in usa isso no Android (Credential Manager).
  // OBS: a CHAVE SECRETA do client NÃO entra no app — só o ID abaixo.
  static const String? serverClientId =
      '518268419553-r8gl48j54hul587tl4nuh1mvbaaa70qf.apps.googleusercontent.com';

  static bool _inicializado = false;

  static Future<void> _garantirInit() async {
    if (_inicializado) return;
    await GoogleSignIn.instance.initialize(serverClientId: serverClientId);
    _inicializado = true;
  }

  /// true em plataformas onde o fluxo interativo nativo existe (mobile).
  /// No Windows/Linux/desktop não há implementação do plugin, então
  /// `supportsAuthenticate()` lança UnimplementedError — tratamos como false.
  static bool get suportado {
    try {
      return GoogleSignIn.instance.supportsAuthenticate();
    } catch (_) {
      return false;
    }
  }

  /// Abre o fluxo de login. Retorna a conta ou null se cancelado/indisponível.
  static Future<GoogleSignInAccount?> entrar() async {
    try {
      await _garantirInit();
      if (!GoogleSignIn.instance.supportsAuthenticate()) return null;
      return await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException {
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> sair() async {
    try {
      await _garantirInit();
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
  }
}

const String _dataFileName = 'labtracker_data.json';

Future<File> _obterArquivoDados() async {
  final Directory dir = await getApplicationDocumentsDirectory();
  return File('${dir.path}${Platform.pathSeparator}$_dataFileName');
}

Future<Map<String, dynamic>?> _lerDadosArquivo() async {
  try {
    final File arquivo = await _obterArquivoDados();
    if (!await arquivo.exists()) {
      return null;
    }

    final String conteudo = await arquivo.readAsString();
    final dynamic dados = jsonDecode(conteudo);

    if (dados is Map<String, dynamic>) {
      return dados;
    }
  } catch (_) {
    return null;
  }

  return null;
}

Future<void> _salvarDadosArquivo(Map<String, dynamic> dados) async {
  try {
    final File arquivo = await _obterArquivoDados();
    const JsonEncoder encoder = JsonEncoder.withIndent('  ');
    await arquivo.writeAsString(encoder.convert(dados), flush: true);
  } catch (_) {}
}

Future<void> _removerDadosArquivo() async {
  try {
    final File arquivo = await _obterArquivoDados();
    if (await arquivo.exists()) {
      await arquivo.delete();
    }
  } catch (_) {}
}

/// Paleta da marca — Conceito 3 "LT Progress Mark".
class BrandColors {
  static const Color ambarEscuro = Color(0xFF5A2E00);
  static const Color laranjaForte = Color(0xFFCC6200);
  static const Color laranjaVivo = Color(0xFFFFA000);
  static const Color ambarDourado = Color(0xFFFFC84D);
  static const Color ambarClaro = Color(0xFFFFE9A6);
  static const Color brancoSuave = Color(0xFFE6E6E6);
  static const Color grafite = Color(0xFF1A1C1E);
  static const Color pretoCarvao = Color(0xFF0D0F11);

  static const Color sucesso = Color(0xFF3FB950);
  static const Color alerta = Color(0xFFE5484D);
}

class LabTrackerApp extends StatelessWidget {
  const LabTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    const ColorScheme scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: BrandColors.laranjaVivo,
      onPrimary: BrandColors.pretoCarvao,
      primaryContainer: BrandColors.ambarEscuro,
      onPrimaryContainer: BrandColors.ambarClaro,
      secondary: BrandColors.ambarDourado,
      onSecondary: BrandColors.pretoCarvao,
      tertiary: BrandColors.laranjaForte,
      onTertiary: BrandColors.brancoSuave,
      error: BrandColors.alerta,
      onError: BrandColors.brancoSuave,
      surface: BrandColors.grafite,
      onSurface: BrandColors.brancoSuave,
      surfaceContainerHighest: Color(0xFF26292C),
      outline: Color(0xFF3A3D40),
    );

    final ThemeData base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: BrandColors.pretoCarvao,
      canvasColor: BrandColors.pretoCarvao,
    );

    return MaterialApp(
      title: 'LabTracker',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        appBarTheme: const AppBarTheme(
          backgroundColor: BrandColors.pretoCarvao,
          foregroundColor: BrandColors.brancoSuave,
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: BrandColors.grafite,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF2C2F33)),
          ),
        ),
        dividerColor: const Color(0xFF2C2F33),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: BrandColors.laranjaVivo,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: BrandColors.laranjaVivo,
            foregroundColor: BrandColors.pretoCarvao,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: BrandColors.ambarDourado,
            side: const BorderSide(color: BrandColors.laranjaForte),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: BrandColors.ambarDourado),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: BrandColors.laranjaVivo,
          foregroundColor: BrandColors.pretoCarvao,
        ),
      ),
      home: const RootPage(),
    );
  }
}

/// Bloquinhos de progresso da marca (estilo "segmented").
class ProgressBlocks extends StatelessWidget {
  final int total;
  final int filled;
  final double blockWidth;
  final double blockHeight;
  final double spacing;

  const ProgressBlocks({
    super.key,
    this.total = 10,
    this.filled = 7,
    this.blockWidth = 12,
    this.blockHeight = 7,
    this.spacing = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        final bool on = i < filled;
        return Container(
          width: blockWidth,
          height: blockHeight,
          margin: EdgeInsets.only(right: i == total - 1 ? 0 : spacing),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(1.5),
            gradient: on
                ? const LinearGradient(
                    colors: [BrandColors.laranjaForte, BrandColors.ambarDourado],
                  )
                : null,
            color: on ? null : const Color(0xFF34373B),
          ),
        );
      }),
    );
  }
}

/// Marca quadrada "LT" (ícone / leading).
class LtMark extends StatelessWidget {
  final double size;
  final bool bordered;

  const LtMark({super.key, this.size = 40, this.bordered = false});

  @override
  Widget build(BuildContext context) {
    final double fontSize = size * 0.62;
    final Widget lt = RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          letterSpacing: -1,
          height: 1,
        ),
        children: const [
          TextSpan(text: 'L', style: TextStyle(color: BrandColors.laranjaVivo)),
          TextSpan(text: 'T', style: TextStyle(color: BrandColors.brancoSuave)),
        ],
      ),
    );

    if (!bordered) return SizedBox(height: size, child: Center(child: lt));

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.14),
      decoration: BoxDecoration(
        border: Border.all(color: BrandColors.laranjaVivo, width: 2),
        borderRadius: BorderRadius.circular(size * 0.18),
      ),
      child: Center(child: lt),
    );
  }
}

/// Logo horizontal completo: LT + "LabTracker" + barra de progresso.
class LtLogo extends StatelessWidget {
  final double scale;
  final bool showProgress;

  const LtLogo({super.key, this.scale = 1, this.showProgress = true});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LtMark(size: 38 * scale),
        SizedBox(width: 12 * scale),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 22 * scale,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  height: 1,
                ),
                children: const [
                  TextSpan(text: 'Lab', style: TextStyle(color: BrandColors.laranjaVivo)),
                  TextSpan(text: 'Tracker', style: TextStyle(color: BrandColors.brancoSuave)),
                ],
              ),
            ),
            if (showProgress) ...[
              SizedBox(height: 5 * scale),
              ProgressBlocks(
                total: 10,
                filled: 7,
                blockWidth: 11 * scale,
                blockHeight: 6 * scale,
                spacing: 3 * scale,
              ),
            ],
          ],
        ),
      ],
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

const List<Character> personagensDBFZ = [
  Character(name: 'Android 16', initial: 'A16', rank: 'Starter V', pdl: 0),
  Character(name: 'Android 17', initial: 'A17', rank: 'Starter V', pdl: 0),
  Character(name: 'Android 18', initial: 'A18', rank: 'Starter V', pdl: 0),
  Character(name: 'Android 21', initial: 'A21', rank: 'Starter V', pdl: 0),
  Character(name: 'Android 21 (Lab Coat)', initial: 'A21', rank: 'Starter V', pdl: 0),
  Character(name: 'Bardock', initial: 'BA', rank: 'Starter V', pdl: 0),
  Character(name: 'Beerus', initial: 'BE', rank: 'Starter V', pdl: 0),
  Character(name: 'Broly', initial: 'BR', rank: 'Starter V', pdl: 0),
  Character(name: 'Broly (DBS)', initial: 'BR', rank: 'Starter V', pdl: 0),
  Character(name: 'Captain Ginyu', initial: 'CG', rank: 'Starter V', pdl: 0),
  Character(name: 'Cell', initial: 'CE', rank: 'Starter V', pdl: 0),
  Character(name: 'Cooler', initial: 'CO', rank: 'Starter V', pdl: 0),
  Character(name: 'Frieza', initial: 'FR', rank: 'Starter V', pdl: 0),
  Character(name: 'Gogeta (SS4)', initial: 'GO', rank: 'Starter V', pdl: 0),
  Character(name: 'Gogeta (SSGSS)', initial: 'GO', rank: 'Starter V', pdl: 0),
  Character(name: 'Gohan (Adult)', initial: 'GH', rank: 'Starter V', pdl: 0),
  Character(name: 'Gohan (Teen)', initial: 'GH', rank: 'Starter V', pdl: 0),
  Character(name: 'Goku', initial: 'GK', rank: 'Starter V', pdl: 0),
  Character(name: 'Goku (GT)', initial: 'GK', rank: 'Starter V', pdl: 0),
  Character(name: 'Goku (SSGSS)', initial: 'GK', rank: 'Starter V', pdl: 0),
  Character(name: 'Goku (Super Saiyan)', initial: 'GK', rank: 'Starter V', pdl: 0),
  Character(name: 'Goku (Ultra Instinct)', initial: 'GK', rank: 'Starter V', pdl: 0),
  Character(name: 'Goku Black', initial: 'GB', rank: 'Starter V', pdl: 0),
  Character(name: 'Gotenks', initial: 'GT', rank: 'Starter V', pdl: 0),
  Character(name: 'Hit', initial: 'HI', rank: 'Starter V', pdl: 0),
  Character(name: 'Janemba', initial: 'JA', rank: 'Starter V', pdl: 0),
  Character(name: 'Jiren', initial: 'JI', rank: 'Starter V', pdl: 0),
  Character(name: 'Kefla', initial: 'KE', rank: 'Starter V', pdl: 0),
  Character(name: 'Kid Buu', initial: 'KB', rank: 'Starter V', pdl: 0),
  Character(name: 'Krillin', initial: 'KR', rank: 'Starter V', pdl: 0),
  Character(name: 'Majin Buu', initial: 'MB', rank: 'Starter V', pdl: 0),
  Character(name: 'Master Roshi', initial: 'MR', rank: 'Starter V', pdl: 0),
  Character(name: 'Nappa', initial: 'NA', rank: 'Starter V', pdl: 0),
  Character(name: 'Piccolo', initial: 'PI', rank: 'Starter V', pdl: 0),
  Character(name: 'Super Baby 2', initial: 'SB', rank: 'Starter V', pdl: 0),
  Character(name: 'Tien', initial: 'TI', rank: 'Starter V', pdl: 0),
  Character(name: 'Trunks', initial: 'TR', rank: 'Starter V', pdl: 0),
  Character(name: 'Vegeta', initial: 'VE', rank: 'Starter V', pdl: 0),
  Character(name: 'Vegeta (SSGSS)', initial: 'VE', rank: 'Starter V', pdl: 0),
  Character(name: 'Vegeta (Super Saiyan)', initial: 'VE', rank: 'Starter V', pdl: 0),
  Character(name: 'Vegito (SSGSS)', initial: 'VG', rank: 'Starter V', pdl: 0),
  Character(name: 'Videl', initial: 'VI', rank: 'Starter V', pdl: 0),
  Character(name: 'Yamcha', initial: 'YA', rank: 'Starter V', pdl: 0),
  Character(name: 'Zamasu (Fused)', initial: 'ZA', rank: 'Starter V', pdl: 0),
];

const List<Character> personagensFatalFury = [
  Character(name: 'Terry Bogard', initial: 'TB', rank: 'Starter V', pdl: 0),
  Character(name: 'Rock Howard', initial: 'RH', rank: 'Starter V', pdl: 0),
  Character(name: 'B. Jenet', initial: 'BJ', rank: 'Starter V', pdl: 0),
  Character(name: 'Mai Shiranui', initial: 'MS', rank: 'Starter V', pdl: 0),
  Character(name: 'Hotaru Futaba', initial: 'HF', rank: 'Starter V', pdl: 0),
  Character(name: 'Hokutomaru', initial: 'HO', rank: 'Starter V', pdl: 0),
  Character(name: 'Kim Dong Hwan', initial: 'KD', rank: 'Starter V', pdl: 0),
  Character(name: 'Gato', initial: 'GA', rank: 'Starter V', pdl: 0),
  Character(name: 'Tizoc', initial: 'TI', rank: 'Starter V', pdl: 0),
  Character(name: 'Preecha', initial: 'PR', rank: 'Starter V', pdl: 0),
  Character(name: 'Kevin Rian', initial: 'KV', rank: 'Starter V', pdl: 0),
  Character(name: 'Marco Rodriguez', initial: 'MA', rank: 'Starter V', pdl: 0),
  Character(name: 'Vox Reaper', initial: 'VR', rank: 'Starter V', pdl: 0),
  Character(name: 'Kain R. Heinlein', initial: 'KA', rank: 'Starter V', pdl: 0),
  Character(name: 'Salvatore Ganacci', initial: 'SG', rank: 'Starter V', pdl: 0),
  Character(name: 'Cristiano Ronaldo', initial: 'CR', rank: 'Starter V', pdl: 0),
  Character(name: 'Andy Bogard', initial: 'AB', rank: 'Starter V', pdl: 0),
  Character(name: 'Ken Masters', initial: 'KM', rank: 'Starter V', pdl: 0),
  Character(name: 'Joe Higashi', initial: 'JH', rank: 'Starter V', pdl: 0),
  Character(name: 'Chun-Li', initial: 'CL', rank: 'Starter V', pdl: 0),
  Character(name: 'Mr. Big', initial: 'MB', rank: 'Starter V', pdl: 0),
];

const List<Character> personagensInvincible = [
  Character(name: 'Invincible', initial: 'IN', rank: 'Starter V', pdl: 0),
  Character(name: 'Atom Eve', initial: 'AE', rank: 'Starter V', pdl: 0),
  Character(name: 'Bulletproof', initial: 'BU', rank: 'Starter V', pdl: 0),
  Character(name: 'Thula', initial: 'TH', rank: 'Starter V', pdl: 0),
  Character(name: 'Rex Splode', initial: 'RS', rank: 'Starter V', pdl: 0),
  Character(name: 'Battle Beast', initial: 'BB', rank: 'Starter V', pdl: 0),
  Character(name: 'Omni-Man', initial: 'OM', rank: 'Starter V', pdl: 0),
  Character(name: 'Cecil Stedman', initial: 'CS', rank: 'Starter V', pdl: 0),
  Character(name: 'Monster Girl', initial: 'MG', rank: 'Starter V', pdl: 0),
  Character(name: 'Robot', initial: 'RO', rank: 'Starter V', pdl: 0),
  Character(name: 'Ella Mental', initial: 'EM', rank: 'Starter V', pdl: 0),
  Character(name: 'Anissa', initial: 'AN', rank: 'Starter V', pdl: 0),
  Character(name: 'Lucan', initial: 'LU', rank: 'Starter V', pdl: 0),
  Character(name: 'Powerplex', initial: 'PW', rank: 'Starter V', pdl: 0),
  Character(name: 'Dupli-Kate', initial: 'DK', rank: 'Starter V', pdl: 0),
  Character(name: 'Allen the Alien', initial: 'AA', rank: 'Starter V', pdl: 0),
  Character(name: 'Titan', initial: 'TT', rank: 'Starter V', pdl: 0),
  Character(name: 'Conquest', initial: 'CQ', rank: 'Starter V', pdl: 0),
  Character(name: 'Universa', initial: 'UN', rank: 'Starter V', pdl: 0),
  Character(name: 'The Immortal', initial: 'IM', rank: 'Starter V', pdl: 0),
];

// Mapas nome -> URL da imagem (puxadas da internet, CDN do Fandom).
const Map<String, String> imagensSmash = {
  'Mario': 'https://static.wikia.nocookie.net/ssb/images/4/44/Mario_SSBU.png/revision/latest?cb=20180612204958',
  'Donkey Kong': 'https://static.wikia.nocookie.net/ssb/images/5/5f/Donkey_Kong_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20180612204654',
  'Link': 'https://static.wikia.nocookie.net/ssb/images/1/19/Link_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20190612145102',
  'Samus': 'https://static.wikia.nocookie.net/ssb/images/4/4d/Samus_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20180612205333',
  'Dark Samus': 'https://static.wikia.nocookie.net/ssb/images/7/7e/Dark_Samus_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20180808153139',
  'Yoshi': 'https://static.wikia.nocookie.net/ssb/images/0/06/Yoshi_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20180612205516',
  'Kirby': 'https://static.wikia.nocookie.net/ssb/images/9/92/Kirby_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20190715072044',
  'Fox': 'https://static.wikia.nocookie.net/ssb/images/0/04/Fox_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20180612204657',
  'Pikachu': 'https://static.wikia.nocookie.net/ssb/images/2/26/Pikachu_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20180906080903',
  'Luigi': 'https://static.wikia.nocookie.net/ssb/images/c/cb/Luigi_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20180612204957',
  'Ness': 'https://static.wikia.nocookie.net/ssb/images/e/e3/Ness_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20260403192056',
  'Captain Falcon': 'https://static.wikia.nocookie.net/ssb/images/4/4a/Captain_Falcon_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20180612204650',
  'Jigglypuff': 'https://static.wikia.nocookie.net/ssb/images/e/ee/Jigglypuff_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20180612204700',
  'Peach': 'https://static.wikia.nocookie.net/ssb/images/0/07/Peach_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20180612205005',
  'Daisy': 'https://static.wikia.nocookie.net/ssb/images/2/21/Daisy_SSBU.png/revision/latest?cb=20190619061339',
  'Bowser': 'https://static.wikia.nocookie.net/ssb/images/1/19/Bowser_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20190715072153',
  'Ice Climbers': 'https://static.wikia.nocookie.net/ssb/images/1/12/Ice_Climbers_SSBU.png/revision/latest?cb=20180612204658',
  'Sheik': 'https://static.wikia.nocookie.net/ssb/images/c/c8/Sheik_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20180612205334',
  'Zelda': 'https://static.wikia.nocookie.net/ssb/images/9/92/Zelda_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20180612205517',
  'Dr. Mario': 'https://static.wikia.nocookie.net/ssb/images/1/16/Dr._Mario_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20180612204654',
  'Pichu': 'https://static.wikia.nocookie.net/ssb/images/1/15/Pichu_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20180612205327',
  'Falco': 'https://static.wikia.nocookie.net/ssb/images/8/80/Falco_SSBU.png/revision/latest?cb=20200718105804',
  'Marth': 'https://static.wikia.nocookie.net/ssb/images/f/ff/Marth_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20180612204959',
  'Lucina': 'https://static.wikia.nocookie.net/ssb/images/e/eb/Lucina_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20180612204957',
  'Young Link': 'https://static.wikia.nocookie.net/ssb/images/4/41/Young_Link_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20180612205516',
  'Ganondorf': 'https://static.wikia.nocookie.net/ssb/images/8/88/Ganondorf_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20180612204657',
  'Mewtwo': 'https://static.wikia.nocookie.net/ssb/images/8/89/Mewtwo_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20180612205001',
  'Roy': 'https://static.wikia.nocookie.net/ssb/images/2/2c/Roy_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20180914115555',
  'Chrom': 'https://static.wikia.nocookie.net/ssb/images/a/a9/Chrom_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20180808153028',
  'Mr. Game & Watch': 'https://static.wikia.nocookie.net/ssb/images/8/8c/Mr._Game_%26_Watch_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20180612205002',
  'Meta Knight': 'https://static.wikia.nocookie.net/ssb/images/8/8f/Meta_Knight_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20180612205000',
  'Pit': 'https://static.wikia.nocookie.net/ssb/images/d/db/Pit_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20190715072257',
  'Dark Pit': 'https://static.wikia.nocookie.net/ssb/images/b/b7/Dark_Pit_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20180612204653',
  'Zero Suit Samus': 'https://static.wikia.nocookie.net/ssb/images/1/17/Zero_Suit_Samus_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20180612205518',
  'Wario': 'https://static.wikia.nocookie.net/ssb/images/3/32/Wario_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20180612205337',
  'Snake': 'https://static.wikia.nocookie.net/ssb/images/c/c3/Snake_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20180612205335',
  'Ike': 'https://static.wikia.nocookie.net/ssb/images/9/9c/Ike_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20180612204659',
  'Pokémon Trainer': 'https://static.wikia.nocookie.net/ssb/images/0/0f/Pok%C3%A9mon_Trainer_SSBU.png/revision/latest?cb=20180614220143',
  'Diddy Kong': 'https://static.wikia.nocookie.net/ssb/images/d/d8/Diddy_Kong_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20180612204653',
  'Lucas': 'https://static.wikia.nocookie.net/ssb/images/c/ce/Lucas_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20250331230833',
  'Sonic': 'https://static.wikia.nocookie.net/ssb/images/e/eb/Sonic_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20230304175700',
  'King Dedede': 'https://static.wikia.nocookie.net/ssb/images/b/b4/King_Dedede_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20180909152046',
  'Olimar': 'https://static.wikia.nocookie.net/ssb/images/0/05/Olimar_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20180612205003',
  'Lucario': 'https://static.wikia.nocookie.net/ssb/images/a/a9/Lucario_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20180612204956',
  'R.O.B.': 'https://static.wikia.nocookie.net/ssb/images/0/02/R.O.B._-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20210726195004',
  'Toon Link': 'https://static.wikia.nocookie.net/ssb/images/3/3d/Toon_Link_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20180612205336',
  'Wolf': 'https://static.wikia.nocookie.net/ssb/images/e/e3/Wolf_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20181028020708',
  'Villager': 'https://static.wikia.nocookie.net/ssb/images/2/2d/Villager_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20180612205337',
  'Mega Man': 'https://static.wikia.nocookie.net/ssb/images/3/3f/Mega_Man_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20190715072405',
  'Wii Fit Trainer': 'https://static.wikia.nocookie.net/ssb/images/0/0c/Wii_Fit_Trainer_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20260504040051',
  'Rosalina & Luma': 'https://static.wikia.nocookie.net/ssb/images/a/ac/Rosalina_%26_Luma_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20180612205331',
  'Little Mac': 'https://static.wikia.nocookie.net/ssb/images/e/e8/Little_Mac_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20180612204955',
  'Greninja': 'https://static.wikia.nocookie.net/ssb/images/f/f4/Greninja_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20180612204658',
  'Mii Brawler': 'https://static.wikia.nocookie.net/ssb/images/b/b4/Mii_Brawler_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20180705150043',
  'Mii Swordfighter': 'https://static.wikia.nocookie.net/ssb/images/2/25/Mii_Swordfighter_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20180705145938',
  'Mii Gunner': 'https://static.wikia.nocookie.net/ssb/images/e/ea/Mii_Gunner_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20240401031836',
  'Palutena': 'https://static.wikia.nocookie.net/ssb/images/c/c5/Palutena_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20220219175924',
  'Pac-Man': 'https://static.wikia.nocookie.net/ssb/images/5/5a/Pac-Man_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20180612205003',
  'Robin': 'https://static.wikia.nocookie.net/ssb/images/a/a9/Robin_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20180612205330',
  'Shulk': 'https://static.wikia.nocookie.net/ssb/images/2/20/Shulk_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20181202120522',
  'Bowser Jr.': 'https://static.wikia.nocookie.net/ssb/images/1/1b/Bowser_Jr._-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20180612204649',
  'Duck Hunt': 'https://static.wikia.nocookie.net/ssb/images/0/0b/Duck_Hunt_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20180612204655',
  'Ryu': 'https://static.wikia.nocookie.net/ssb/images/2/2b/Ryu_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20190715072923',
  'Ken': 'https://static.wikia.nocookie.net/ssb/images/2/2a/Ken_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20220219174348',
  'Cloud': 'https://static.wikia.nocookie.net/ssb/images/d/d6/Cloud_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20180930104214',
  'Corrin': 'https://static.wikia.nocookie.net/ssb/images/8/8c/Corrin_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20180612204651',
  'Bayonetta': 'https://static.wikia.nocookie.net/ssb/images/d/da/Bayonetta_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20180612204648',
  'Inkling': 'https://static.wikia.nocookie.net/ssb/images/8/81/Inkling_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20180612204700',
  'Ridley': 'https://static.wikia.nocookie.net/ssb/images/5/5c/Ridley_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20180914125125',
  'Simon': 'https://static.wikia.nocookie.net/ssb/images/8/89/Simon_Belmont_SSBU.png/revision/latest?cb=20180808153242',
  'Richter': 'https://static.wikia.nocookie.net/ssb/images/b/b4/Richter_Belmont_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20220219174812',
  'King K. Rool': 'https://static.wikia.nocookie.net/ssb/images/f/fd/King_K._Rool_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20180808152915',
  'Isabelle': 'https://static.wikia.nocookie.net/ssb/images/f/fb/Isabelle_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20180914091810',
  'Incineroar': 'https://static.wikia.nocookie.net/ssb/images/9/9a/Incineroar_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20220219173808',
  'Piranha Plant': 'https://static.wikia.nocookie.net/ssb/images/d/d7/Piranha_Plant_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20181101165757',
  'Joker': 'https://static.wikia.nocookie.net/ssb/images/5/56/Joker_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20201107233616',
  'Hero': 'https://static.wikia.nocookie.net/ssb/images/0/07/Hero_SSBU.png/revision/latest?cb=20260403185733',
  'Banjo & Kazooie': 'https://static.wikia.nocookie.net/ssb/images/c/cc/Banjo_and_Kazooie.png/revision/latest/scale-to-width-down/303?cb=20250414172712',
  'Terry': 'https://static.wikia.nocookie.net/ssb/images/f/f5/Terry_SSBU.png/revision/latest?cb=20200626010159',
  'Byleth': 'https://static.wikia.nocookie.net/ssb/images/3/3d/Byleth_SSBU.png/revision/latest?cb=20200116163825',
  'Min Min': 'https://static.wikia.nocookie.net/ssb/images/3/35/Min_Min_SSBU.png/revision/latest?cb=20200622171658',
  'Steve': 'https://static.wikia.nocookie.net/ssb/images/3/3a/Steve_SSBU.png/revision/latest?cb=20201001151548',
  'Sephiroth': 'https://static.wikia.nocookie.net/ssb/images/1/19/Sephiroth_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20260403175500',
  'Pyra/Mythra': 'https://static.wikia.nocookie.net/ssb/images/7/76/Pyra_%26_Mythra_SSBU.png/revision/latest?cb=20210217231332',
  'Kazuya': 'https://static.wikia.nocookie.net/ssb/images/7/79/Kazuya_Mishima.png/revision/latest/scale-to-width-down/189?cb=20250414213628',
  'Sora': 'https://static.wikia.nocookie.net/ssb/images/4/42/Sora_KH3.png/revision/latest/scale-to-width-down/274?cb=20211005174002',
};

const Map<String, String> imagensDBFZ = {
  'Android 16': 'https://static.wikia.nocookie.net/dragonballfighterz/images/1/1b/Android_16_Artwork.png/revision/latest/scale-to-width-down/208?cb=20180902173209',
  'Android 17': 'https://static.wikia.nocookie.net/dragonballfighterz/images/a/a8/Android_17_Artwork.png/revision/latest/scale-to-width-down/156?cb=20180921112244',
  'Android 18': 'https://static.wikia.nocookie.net/dragonballfighterz/images/c/c1/Android_18_Artwork.png/revision/latest/scale-to-width-down/142?cb=20180902173221',
  'Android 21': 'https://static.wikia.nocookie.net/dragonballfighterz/images/8/8d/Majin_Android_21_.webp/revision/latest/scale-to-width-down/266?cb=20240209145744',
  'Android 21 (Lab Coat)': 'https://static.wikia.nocookie.net/dragonballfighterz/images/2/23/Android_21_.webp/revision/latest/scale-to-width-down/217?cb=20240209145915',
  'Bardock': 'https://static.wikia.nocookie.net/dragonballfighterz/images/9/97/Bardock_Artwork.png/revision/latest/scale-to-width-down/267?cb=20180902173253',
  'Beerus': 'https://static.wikia.nocookie.net/dragonballfighterz/images/1/17/Beerus_Artwork.png/revision/latest/scale-to-width-down/177?cb=20180902173306',
  'Broly': 'https://static.wikia.nocookie.net/dragonballfighterz/images/b/b2/Broly_Artwork.png/revision/latest/scale-to-width-down/252?cb=20180902173319',
  'Broly (DBS)': 'https://static.wikia.nocookie.net/dragonballfighterz/images/f/f1/Broly_%28DBS%29_Artwork.png/revision/latest/scale-to-width-down/235?cb=20191205173206',
  'Captain Ginyu': 'https://static.wikia.nocookie.net/dragonballfighterz/images/1/12/Captain_Ginyu_Artwork.png/revision/latest/scale-to-width-down/366?cb=20180914190847',
  'Cell': 'https://static.wikia.nocookie.net/dragonballfighterz/images/b/b4/Cell_Artwork.png/revision/latest/scale-to-width-down/202?cb=20180914190920',
  'Cooler': 'https://static.wikia.nocookie.net/dragonballfighterz/images/f/f2/Cooler_Artwork.png/revision/latest/scale-to-width-down/290?cb=20180914191343',
  'Frieza': 'https://static.wikia.nocookie.net/dragonballfighterz/images/5/59/Frieza_Artwork.png/revision/latest/scale-to-width-down/299?cb=20180902173332',
  'Gogeta (SS4)': 'https://static.wikia.nocookie.net/dragonballfighterz/images/f/fa/Gogeta_%28SS4%29_Artwork.png/revision/latest/scale-to-width-down/225?cb=20210312072617',
  'Gogeta (SSGSS)': 'https://static.wikia.nocookie.net/dragonballfighterz/images/1/1a/Gogeta_%28SSGSS%29_Artwork.png/revision/latest/scale-to-width-down/197?cb=20190924154249',
  'Gohan (Adult)': 'https://static.wikia.nocookie.net/dragonballfighterz/images/b/ba/Gohan_%28Adult%29_Artwork.png/revision/latest/scale-to-width-down/188?cb=20180902173350',
  'Gohan (Teen)': 'https://static.wikia.nocookie.net/dragonballfighterz/images/c/c6/Gohan_%28Teen%29_Artwork.png/revision/latest/scale-to-width-down/168?cb=20180914190755',
  'Goku': 'https://static.wikia.nocookie.net/dragonballfighterz/images/e/ea/Goku_Artwork.png/revision/latest/scale-to-width-down/171?cb=20180902173423',
  'Goku (GT)': 'https://static.wikia.nocookie.net/dragonballfighterz/images/3/37/Goku_%28GT%29_Artwork.png/revision/latest/scale-to-width-down/261?cb=20190322172910',
  'Goku (SSGSS)': 'https://static.wikia.nocookie.net/dragonballfighterz/images/2/2b/Goku_%28SSGSS%29_Artwork.png/revision/latest/scale-to-width-down/130?cb=20180902173408',
  'Goku (Super Saiyan)': 'https://static.wikia.nocookie.net/dragonballfighterz/images/b/b1/Goku_%28Super_Saiyan%29_Artwork.png/revision/latest/scale-to-width-down/198?cb=20180914190656',
  'Goku (Ultra Instinct)': 'https://static.wikia.nocookie.net/dragonballfighterz/images/5/58/Goku_%28Ultra_Instinct%29_Artwork.png/revision/latest/scale-to-width-down/147?cb=20200508233232',
  'Goku Black': 'https://static.wikia.nocookie.net/dragonballfighterz/images/d/d7/Goku_Black_Artwork.png/revision/latest/scale-to-width-down/151?cb=20211006002424',
  'Gotenks': 'https://static.wikia.nocookie.net/dragonballfighterz/images/b/b4/Gotenks_Artwork.png/revision/latest/scale-to-width-down/212?cb=20180902173502',
  'Hit': 'https://static.wikia.nocookie.net/dragonballfighterz/images/b/b2/Hit_Artwork.png/revision/latest/scale-to-width-down/215?cb=20180902173526',
  'Janemba': 'https://static.wikia.nocookie.net/dragonballfighterz/images/3/33/Janemba_Artwork.png/revision/latest/scale-to-width-down/311?cb=20190805175120',
  'Jiren': 'https://static.wikia.nocookie.net/dragonballfighterz/images/1/1e/Jiren_Artwork.png/revision/latest/scale-to-width-down/179?cb=20190131101001',
  'Kefla': 'https://static.wikia.nocookie.net/dragonballfighterz/images/5/52/Kefla.webp/revision/latest/scale-to-width-down/152?cb=20240209150058',
  'Kid Buu': 'https://static.wikia.nocookie.net/dragonballfighterz/images/f/f7/Kid_Buu_Artwork.png/revision/latest/scale-to-width-down/218?cb=20180902173540',
  'Krillin': 'https://static.wikia.nocookie.net/dragonballfighterz/images/5/51/Krillin_Artwork.png/revision/latest/scale-to-width-down/250?cb=20180902173557',
  'Majin Buu': 'https://static.wikia.nocookie.net/dragonballfighterz/images/6/62/Majin_Buu_Artwork.png/revision/latest/scale-to-width-down/400?cb=20180902173633',
  'Master Roshi': 'https://static.wikia.nocookie.net/dragonballfighterz/images/0/09/Master_Roshi_Artwork.png/revision/latest/scale-to-width-down/153?cb=20200919034409',
  'Nappa': 'https://static.wikia.nocookie.net/dragonballfighterz/images/7/77/Nappa_Artwork.png/revision/latest/scale-to-width-down/297?cb=20180914191045',
  'Piccolo': 'https://static.wikia.nocookie.net/dragonballfighterz/images/e/ec/Piccolo_Artwork.png/revision/latest/scale-to-width-down/154?cb=20180914190738',
  'Super Baby 2': 'https://static.wikia.nocookie.net/dragonballfighterz/images/c/c3/Super_Baby_2_Artwork.png/revision/latest/scale-to-width-down/187?cb=20211006002359',
  'Tien': 'https://static.wikia.nocookie.net/dragonballfighterz/images/c/c8/Tien_Artwork.png/revision/latest/scale-to-width-down/291?cb=20180902173650',
  'Trunks': 'https://static.wikia.nocookie.net/dragonballfighterz/images/7/76/Trunks_Artwork.png/revision/latest/scale-to-width-down/181?cb=20180902173709',
  'Vegeta': 'https://static.wikia.nocookie.net/dragonballfighterz/images/4/4f/Vegeta_Artwork.png/revision/latest/scale-to-width-down/219?cb=20180902173806',
  'Vegeta (SSGSS)': 'https://static.wikia.nocookie.net/dragonballfighterz/images/9/90/Vegeta_%28SSGSS%29_Artwork.png/revision/latest/scale-to-width-down/144?cb=20180902173750',
  'Vegeta (Super Saiyan)': 'https://static.wikia.nocookie.net/dragonballfighterz/images/1/14/Vegeta_%28Super_Saiyan%29_Artwork.png/revision/latest/scale-to-width-down/223?cb=20180902173731',
  'Vegito (SSGSS)': 'https://static.wikia.nocookie.net/dragonballfighterz/images/7/72/Vegito_%28SSGSS%29_Artwork.png/revision/latest/scale-to-width-down/158?cb=20180902173822',
  'Videl': 'https://static.wikia.nocookie.net/dragonballfighterz/images/1/19/Videl_.webp/revision/latest/scale-to-width-down/175?cb=20240209150001',
  'Yamcha': 'https://static.wikia.nocookie.net/dragonballfighterz/images/b/b6/Yamcha_Artwork.png/revision/latest/scale-to-width-down/244?cb=20180914191111',
  'Zamasu (Fused)': 'https://static.wikia.nocookie.net/dragonballfighterz/images/0/03/Zamasu_%28Fused%29_Artwork.png/revision/latest/scale-to-width-down/255?cb=20180902173842',
};

const Map<String, String> imagensFatalFury = {
  'Terry Bogard': 'https://static.wikia.nocookie.net/snk/images/7/79/Ffcotwterryrender.png/revision/latest/scale-to-width-down/262?cb=20240607225413',
  'Rock Howard': 'https://static.wikia.nocookie.net/snk/images/6/60/Ffcotwrockrender.png/revision/latest/scale-to-width-down/370?cb=20240607225013',
  'B. Jenet': 'https://static.wikia.nocookie.net/snk/images/f/fe/Ffcotwjenetrender.png/revision/latest/scale-to-width-down/345?cb=20240607225646',
  'Mai Shiranui': 'https://static.wikia.nocookie.net/snk/images/a/a1/Ffcotwmairender.png/revision/latest/scale-to-width-down/345?cb=20240820192527',
  'Hotaru Futaba': 'https://static.wikia.nocookie.net/snk/images/9/9a/Ffcotwhotarurender.png/revision/latest/scale-to-width-down/202?cb=20240607230433',
  'Hokutomaru': 'https://static.wikia.nocookie.net/snk/images/2/29/FF-COTW-Hokutomaru.png/revision/latest/scale-to-width-down/345?cb=20250409212133',
  'Kim Dong Hwan': 'https://static.wikia.nocookie.net/snk/images/3/3a/Ffcotwdonghwanrender.png/revision/latest/scale-to-width-down/400?cb=20241027112209',
  'Gato': 'https://static.wikia.nocookie.net/snk/images/e/e7/Ffcotwgatorender.png/revision/latest/scale-to-width-down/345?cb=20241221143549',
  'Tizoc': 'https://static.wikia.nocookie.net/snk/images/b/b1/Ffcotwtizocgriffonrender.png/revision/latest/scale-to-width-down/345?cb=20240607230944',
  'Preecha': 'https://static.wikia.nocookie.net/snk/images/d/db/Ffcotwpreecharender.png/revision/latest/scale-to-width-down/370?cb=20240607230204',
  'Kevin Rian': 'https://static.wikia.nocookie.net/snk/images/f/fa/Ffcotwkevinrender.png/revision/latest/scale-to-width-down/345?cb=20240720200259',
  'Marco Rodriguez': 'https://static.wikia.nocookie.net/snk/images/6/67/Ffcotwmarcorodriguesrender.png/revision/latest/scale-to-width-down/345?cb=20240607225915',
  'Vox Reaper': 'https://static.wikia.nocookie.net/snk/images/5/57/FFCOTW_Vox_Reaper_Render.png/revision/latest/scale-to-width-down/297?cb=20240607225752',
  'Kain R. Heinlein': 'https://static.wikia.nocookie.net/snk/images/b/bb/Ffcotwkainrender.png/revision/latest/scale-to-width-down/262?cb=20250216080824',
  'Salvatore Ganacci': 'https://static.wikia.nocookie.net/snk/images/1/18/FF-COTW-SalvatoreGanacci.png/revision/latest/scale-to-width-down/278?cb=20250403175038',
  'Cristiano Ronaldo': 'https://static.wikia.nocookie.net/snk/images/3/3e/FFCOTW_Cristiano_Ronaldo_Render.png/revision/latest/scale-to-width-down/278?cb=20250326174416',
  'Andy Bogard': 'https://static.wikia.nocookie.net/snk/images/3/34/Ffcotwandyrender.png/revision/latest/scale-to-width-down/278?cb=20250616010616',
  'Ken Masters': 'https://static.wikia.nocookie.net/snk/images/4/4a/FF-COTW-KenMasters.png/revision/latest/scale-to-width-down/345?cb=20250712214507',
  'Joe Higashi': 'https://static.wikia.nocookie.net/snk/images/d/d1/Ffcotwjoerender.png/revision/latest/scale-to-width-down/345?cb=20250922131209',
  'Chun-Li': 'https://static.wikia.nocookie.net/snk/images/4/41/Ffcotwchunlirender.png/revision/latest/scale-to-width-down/345?cb=20251031221246',
  'Mr. Big': 'https://static.wikia.nocookie.net/snk/images/0/09/Ffcotwmrbigrender.webp/revision/latest/scale-to-width-down/345?cb=20251125143729',
};

const Map<String, String> imagensInvincible = {
  'Invincible': 'https://static.wikia.nocookie.net/amazon-invincible/images/a/a3/Invincible_%28Mark_Grayson%29.png/revision/latest/scale-to-width-down/127?cb=20250717141424',
  'Atom Eve': 'https://static.wikia.nocookie.net/amazon-invincible/images/7/74/Atom-EveProfile.png/revision/latest/scale-to-width-down/212?cb=20250520153227',
  'Bulletproof': 'https://static.wikia.nocookie.net/amazon-invincible/images/c/c8/Bulletproof.png/revision/latest/scale-to-width-down/132?cb=20250506145700',
  'Thula': 'https://static.wikia.nocookie.net/amazon-invincible/images/6/61/Viltrumite_Thula.png/revision/latest/scale-to-width-down/161?cb=20251225115314',
  'Rex Splode': 'https://static.wikia.nocookie.net/amazon-invincible/images/8/87/Rex-SplodeProfile.png/revision/latest/scale-to-width-down/133?cb=20260319022803',
  'Battle Beast': 'https://static.wikia.nocookie.net/amazon-invincible/images/0/02/Battle_Beast.png/revision/latest/scale-to-width-down/197?cb=20260505004520',
  'Omni-Man': 'https://static.wikia.nocookie.net/amazon-invincible/images/8/8d/Nolan_coalition_fullbod.png/revision/latest/scale-to-width-down/137?cb=20260510211004',
  'Cecil Stedman': 'https://static.wikia.nocookie.net/amazon-invincible/images/f/f1/CecilProfile.png/revision/latest/scale-to-width-down/154?cb=20250812171717',
  'Monster Girl': 'https://static.wikia.nocookie.net/amazon-invincible/images/2/29/Amanda.png/revision/latest/scale-to-width-down/170?cb=20240605084122',
  'Robot': 'https://static.wikia.nocookie.net/amazon-invincible/images/e/ed/RobotProfile.png/revision/latest/scale-to-width-down/134?cb=20260319125812',
  'Ella Mental': 'https://static.wikia.nocookie.net/amazon-invincible/images/d/db/Ella_Mental_Invincible_VS.png/revision/latest/scale-to-width-down/274?cb=20251214204827',
  'Anissa': 'https://static.wikia.nocookie.net/amazon-invincible/images/0/01/Viltrumite_Anissa.png/revision/latest/scale-to-width-down/155?cb=20260316093546',
  'Lucan': 'https://static.wikia.nocookie.net/amazon-invincible/images/3/34/Viltrumite_Lucan.png/revision/latest/scale-to-width-down/159?cb=20240617102516',
  'Powerplex': 'https://static.wikia.nocookie.net/amazon-invincible/images/5/59/Powerplex-render.png/revision/latest/scale-to-width-down/139?cb=20250715150949',
  'Dupli-Kate': 'https://static.wikia.nocookie.net/amazon-invincible/images/8/80/Dupli-KateProfile.png/revision/latest/scale-to-width-down/98?cb=20250927153747',
  'Allen the Alien': 'https://static.wikia.nocookie.net/amazon-invincible/images/f/fe/Screenshot_2026-04-16_162632.png/revision/latest/scale-to-width-down/326?cb=20260416232734',
  'Titan': 'https://static.wikia.nocookie.net/amazon-invincible/images/3/3b/TitanS3-render.png/revision/latest/scale-to-width-down/153?cb=20250506150803',
  'Conquest': 'https://static.wikia.nocookie.net/amazon-invincible/images/a/af/Viltrumite_Conquest.png/revision/latest/scale-to-width-down/186?cb=20260318003442',
  'Universa': 'https://static.wikia.nocookie.net/amazon-invincible/images/c/c4/Universa.png/revision/latest/scale-to-width-down/400?cb=20260122201315',
  'The Immortal': 'https://static.wikia.nocookie.net/amazon-invincible/images/e/e8/Immortal-render.png/revision/latest/scale-to-width-down/134?cb=20250401155811',
};

const Map<String, String> logosJogos = {
  'Super Smash Bros. Ultimate': 'https://static.wikia.nocookie.net/ssb/images/2/23/Super_Smash_Bros._Ultimate.png/revision/latest/scale-to-width-down/308?cb=20180823005835',
  'Dragon Ball FighterZ': 'https://static.wikia.nocookie.net/dragonballfighterz/images/9/92/Dragon_Ball_FighterZ_Cover.jpg/revision/latest/scale-to-width-down/455?cb=20180902175307',
  'Fatal Fury': 'https://static.wikia.nocookie.net/snk/images/c/c9/Garou-city-of-the-wolves-18ymi.jpg/revision/latest/scale-to-width-down/375?cb=20260122142200',
  'Invincible VS': 'https://static.wikia.nocookie.net/amazon-invincible/images/9/9e/Invincible_VS_Logo.png/revision/latest/scale-to-width-down/500?cb=20260107143744',
};

/// Roster de personagens conforme o jogo selecionado.
List<Character> rosterDoJogo(String jogo) {
  switch (jogo) {
    case 'Dragon Ball FighterZ':
      return personagensDBFZ;
    case 'Fatal Fury':
      return personagensFatalFury;
    case 'Invincible VS':
      return personagensInvincible;
    case 'Super Smash Bros. Ultimate':
    default:
      return personagensSmash;
  }
}

/// Logo/capa do jogo (URL da internet). Vazio se não houver.
String logoDoJogo(String jogo) => logosJogos[jogo] ?? '';

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

String urlImagemPersonagem(String nome, [String jogo = 'Super Smash Bros. Ultimate']) {
  // Jogos cujas imagens vêm de mapas diretos (nome -> URL).
  switch (jogo) {
    case 'Dragon Ball FighterZ':
      return imagensDBFZ[nome.trim()] ?? '';
    case 'Fatal Fury':
      return imagensFatalFury[nome.trim()] ?? '';
    case 'Invincible VS':
      return imagensInvincible[nome.trim()] ?? '';
  }

  // Super Smash Bros. Ultimate (padrão): imagem do CDN do Fandom.
  // (O site oficial smashbros.com bloqueia hotlink, então as imagens não
  // carregavam; usamos o mesmo CDN confiável dos demais jogos.)
  return imagensSmash[normalizarNomePersonagem(nome)] ?? '';
}

Character personagemPorNome(String nome) {
  final String nomeNormalizado = normalizarNomePersonagem(nome);

  for (final personagem in [
    ...personagensSmash,
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
    bool existe = false;

    final Map<String, dynamic>? dadosArquivo = await _lerDadosArquivo();
    if (dadosArquivo != null) {
      final dynamic perfilRaw = dadosArquivo['perfilJogador'];
      if (perfilRaw is Map<String, dynamic>) {
        try {
          final perfil = PlayerProfile.fromJson(perfilRaw);
          existe = perfil.nick.trim().isNotEmpty;
        } catch (_) {
          existe = false;
        }
      }
    }

    if (!existe) {
      final prefs = await SharedPreferences.getInstance();
      final String? perfilSalvo = prefs.getString('perfilJogador');

      if (perfilSalvo != null) {
        try {
          final dynamic decoded = jsonDecode(perfilSalvo);
          if (decoded is Map<String, dynamic>) {
            final perfil = PlayerProfile.fromJson(decoded);
            existe = perfil.nick.trim().isNotEmpty;
          }
        } catch (_) {
          existe = false;
        }
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
    await _salvarDadosArquivo({
      'perfilJogador': perfil.toJson(),
      'personagemAtualNome': 'Hero',
      'personagens': [],
      'historico': [],
    });

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
      return LoginPage(onPerfilCriado: concluirPerfil);
    }

    return const SelecionarJogoInicialPage();
  }
}

/// Tela de entrada: boas-vindas + login com Google (com fallback manual).
class LoginPage extends StatefulWidget {
  final Future<void> Function(PlayerProfile perfil) onPerfilCriado;

  const LoginPage({super.key, required this.onPerfilCriado});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool entrando = false;
  String? erro;

  Future<void> entrarComGoogle() async {
    setState(() {
      entrando = true;
      erro = null;
    });

    final GoogleSignInAccount? conta = await GoogleAuthService.entrar();

    if (!mounted) return;

    if (conta == null) {
      setState(() {
        entrando = false;
        erro = 'Não foi possível entrar com o Google. Tente novamente.';
      });
      return;
    }

    final String nick = (conta.displayName ?? '').trim().isNotEmpty
        ? conta.displayName!.trim()
        : conta.email.split('@').first;

    final PlayerProfile perfil = PlayerProfile(
      nick: nick,
      tagSecundaria: '',
      regiao: '',
      jogoPrincipal: '',
      mainPrincipal: '',
      bio: '',
      email: conta.email,
      fotoUrl: conta.photoUrl ?? '',
    );

    await widget.onPerfilCriado(perfil);
  }

  void entrarSemConta() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CriarPerfilInicialPage(
          onPerfilCriado: widget.onPerfilCriado,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool googleSuportado = GoogleAuthService.suportado;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                const Center(child: LtMark(size: 96, bordered: true)),
                const SizedBox(height: 28),
                const Center(child: LtLogo(scale: 1.4)),
                const SizedBox(height: 18),
                Text(
                  'Seu laboratório de treino competitivo.\nAcompanhe evolução, performance e ranking.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: BrandColors.brancoSuave.withValues(alpha: 0.7),
                      ),
                ),
                const SizedBox(height: 36),
                if (erro != null) ...[
                  Text(
                    erro!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: BrandColors.alerta),
                  ),
                  const SizedBox(height: 12),
                ],
                if (googleSuportado)
                  FilledButton.icon(
                    onPressed: entrando ? null : entrarComGoogle,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: BrandColors.brancoSuave,
                      foregroundColor: BrandColors.pretoCarvao,
                    ),
                    icon: entrando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.account_circle),
                    label: Text(entrando ? 'Entrando...' : 'Entrar com Google'),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: BrandColors.grafite,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF2C2F33)),
                    ),
                    child: const Text(
                      'O login com Google está disponível no app mobile '
                      '(Android/iOS). Nesta plataforma, entre com um nick.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: BrandColors.ambarDourado),
                    ),
                  ),
                const SizedBox(height: 14),
                OutlinedButton(
                  onPressed: entrando ? null : entrarSemConta,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    googleSuportado ? 'Entrar sem conta Google' : 'Entrar com um nick',
                  ),
                ),
                const SizedBox(height: 24),
                Center(child: ProgressBlocks(filled: 7)),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'LT PROGRESS MARK',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 3,
                      color: BrandColors.brancoSuave.withValues(alpha: 0.4),
                    ),
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

    // Quando esta tela foi aberta a partir do login, fecha para revelar
    // a seleção de jogo já montada pela RootPage.
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const LtLogo(scale: 0.85),
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
                const Center(child: LtLogo(scale: 1.6)),
                const SizedBox(height: 28),
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
        title: const LtLogo(scale: 0.85),
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
              'Cada jogo tem seu próprio elenco e imagens. Escolha por onde começar.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: jogosDisponiveis.length,
                itemBuilder: (context, index) {
                  final jogo = jogosDisponiveis[index];
                  final String logo = logoDoJogo(jogo);
                  final int totalPersonagens = rosterDoJogo(jogo).length;

                  return Card(
                    child: ListTile(
                      leading: SizedBox(
                        width: 48,
                        height: 48,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: logo.isEmpty
                              ? CircleAvatar(child: Text(jogo[0]))
                              : Image.network(
                                  logo,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) =>
                                      CircleAvatar(child: Text(jogo[0])),
                                ),
                        ),
                      ),
                      title: Text(jogo),
                      subtitle: Text('$totalPersonagens personagens'),
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
                itemCount: rosterDoJogo(jogoSelecionado).length,
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 230,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.55,
                ),
                itemBuilder: (context, index) {
                  final personagem = rosterDoJogo(jogoSelecionado)[index];

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
                            CharacterAvatar(
                              personagem: personagem.name,
                              jogo: jogoSelecionado,
                              size: 52,
                              initialOverride: personagem.initial,
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
                                  RankBadge(rank: personagem.rank),
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

  late Map<String, Character> personagens;

  late String personagemAtualNome;

  List<PartidaRegistrada> historico = [];

  bool carregando = true;

  /// Nome do personagem padrão (primeiro do roster do jogo atual).
  String get personagemPadraoDoJogo {
    final roster = rosterDoJogo(widget.jogoAtual);
    return roster.isNotEmpty ? roster.first.name : '';
  }

  @override
  void initState() {
    super.initState();
    personagens = {
      for (final personagem in rosterDoJogo(widget.jogoAtual)) personagem.name: personagem,
    };
    personagemAtualNome = widget.personagemInicialNome ?? personagemPadraoDoJogo;
    carregarDados();
  }

  Character get personagemAtual {
    return personagens[personagemAtualNome]!;
  }

  Map<String, dynamic> gerarDadosPersistidos() {
    return {
      'perfilJogador': perfil.toJson(),
      'jogoAtual': widget.jogoAtual,
      'personagemAtualNome': personagemAtualNome,
      'personagens': personagens.values.map((personagem) => personagem.toJson()).toList(),
      'historico': historico.map((partida) => partida.toJson()).toList(),
    };
  }

  void _aplicarDadosMap(Map<String, dynamic> dados) {
    final dynamic personagensRaw = dados['personagens'];
    final dynamic historicoRaw = dados['historico'];
    final dynamic personagemAtualRaw = dados['personagemAtualNome'];
    final dynamic perfilRaw = dados['perfilJogador'];

    personagens = {
      for (final personagem in rosterDoJogo(widget.jogoAtual)) personagem.name: personagem,
    };

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
    if (historicoRaw is List) {
      final List<PartidaRegistrada> importadas = [];
      for (final item in historicoRaw) {
        if (item is Map<String, dynamic>) {
          try {
            importadas.add(PartidaRegistrada.fromJson(item));
          } catch (_) {}
        }
      }
      historico = importadas;
    }

    if (personagemAtualRaw is String && personagens.containsKey(personagemAtualRaw)) {
      personagemAtualNome = personagemAtualRaw;
    }

    if (perfilRaw is Map<String, dynamic>) {
      try {
        perfil = PlayerProfile.fromJson(perfilRaw);
      } catch (_) {}
    }
  }

  Future<void> carregarDados() async {
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
      final String? personagemAtualSalvo = prefs.getString('personagemAtualNome');
      final String? perfilSalvo = prefs.getString('perfilJogador');

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

      if (perfilSalvo != null) {
        try {
          final dynamic decoded = jsonDecode(perfilSalvo);
          if (decoded is Map<String, dynamic>) {
            perfil = PlayerProfile.fromJson(decoded);
          }
        } catch (_) {}
      }
    }

    if (widget.personagemInicialNome != null &&
        personagens.containsKey(widget.personagemInicialNome)) {
      personagemAtualNome = widget.personagemInicialNome!;
    }

    recalcularPersonagensPeloHistorico();

    setState(() {
      carregando = false;
    });
  }

  Future<void> salvarDados() async {
    final prefs = await SharedPreferences.getInstance();

    await _salvarDadosArquivo(gerarDadosPersistidos());

    await prefs.setString('personagemAtualNome', personagemAtualNome);
    await prefs.setString('perfilJogador', jsonEncode(perfil.toJson()));
    await prefs.remove('personagens');
    await prefs.remove('historico');
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

  void recalcularPersonagensPeloHistorico() {
    final Map<String, Character> novosPersonagens = {
      for (final personagem in rosterDoJogo(widget.jogoAtual)) personagem.name: personagem,
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

    await _removerDadosArquivo();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('personagens');
    await prefs.remove('historico');
    await prefs.remove('personagemAtualNome');
    await prefs.remove('perfilJogador');

    setState(() {
      personagens = {
        for (final personagem in rosterDoJogo(widget.jogoAtual)) personagem.name: personagem,
      };
      historico = [];
      personagemAtualNome = personagemPadraoDoJogo;
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
          jogoAtual: widget.jogoAtual,
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
          jogo: widget.jogoAtual,
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
          jogo: widget.jogoAtual,
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
          jogoAtual: widget.jogoAtual,
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
          jogoAtual: widget.jogoAtual,
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
        title: const LtLogo(scale: 0.8, showProgress: false),
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
                    CharacterAvatar(
                      personagem: personagem.name,
                      jogo: widget.jogoAtual,
                      size: 68,
                      initialOverride: personagem.initial,
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
                          Row(
                            children: [
                              const Text('Rank: '),
                              RankBadge(rank: personagem.rank),
                            ],
                          ),
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

class CharacterAvatar extends StatelessWidget {
  final String personagem;
  final String jogo;
  final double size;
  final String? initialOverride;

  const CharacterAvatar({
    super.key,
    required this.personagem,
    required this.jogo,
    this.size = 52,
    this.initialOverride,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String imageUrl = urlImagemPersonagem(personagem, jogo);
    final String initial = initialOverride ??
        (personagem.isNotEmpty ? personagem[0].toUpperCase() : '?');

    Widget fallback() => Center(
          child: Text(
            initial,
            style: TextStyle(
              fontSize: size * 0.45,
              fontWeight: FontWeight.bold,
            ),
          ),
        );

    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Container(
          color: scheme.surfaceContainerHighest,
          child: imageUrl.isEmpty
              ? fallback()
              : Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (_, __, ___) => fallback(),
                ),
        ),
      ),
    );
  }
}

class RankBadge extends StatelessWidget {
  final String rank;

  const RankBadge({
    super.key,
    required this.rank,
  });

  List<Color> get rankColors {
    if (rank.contains('Starter')) return [Colors.brown.shade400, Colors.brown.shade700];
    if (rank.contains('For Fun')) return [Colors.grey.shade400, Colors.grey.shade600];
    if (rank.contains('Quick Play')) return [Colors.amber.shade400, Colors.orange.shade700];
    if (rank.contains('Brawl')) return [Colors.teal.shade300, Colors.blueGrey.shade600];
    if (rank.contains('For Glory')) return [Colors.purple.shade400, Colors.deepPurple.shade800];
    if (rank.contains('Melee')) return [Colors.redAccent.shade400, Colors.red.shade900];
    if (rank.contains('Elite')) return [Colors.yellowAccent.shade400, Colors.deepOrange.shade600];
    return [Colors.blue, Colors.blue.shade800];
  }

  @override
  Widget build(BuildContext context) {
    final colors = rankColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: colors.last.withOpacity(0.6),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.network(
            'https://upload.wikimedia.org/wikipedia/commons/thumb/7/73/Super_Smash_Bros._Cross.svg/120px-Super_Smash_Bros._Cross.svg.png',
            width: 14,
            height: 14,
            color: Colors.white,
            errorBuilder: (_, __, ___) => const Icon(Icons.star, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 6),
          Text(
            rank.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              fontSize: 11,
              shadows: [
                Shadow(color: Colors.black54, blurRadius: 2, offset: Offset(1, 1)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MatchupHeader extends StatelessWidget {
  final String jogo;
  final String personagem;
  final String adversario;
  final double avatarSize;
  final TextStyle? style;

  const MatchupHeader({
    super.key,
    required this.jogo,
    required this.personagem,
    required this.adversario,
    this.avatarSize = 30,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CharacterAvatar(
          personagem: personagem,
          jogo: jogo,
          size: avatarSize,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$personagem vs $adversario',
            style: style,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        CharacterAvatar(
          personagem: adversario,
          jogo: jogo,
          size: avatarSize,
        ),
      ],
    );
  }
}

class SelecionarPersonagemPage extends StatelessWidget {
  final String titulo;
  final List<Character> personagens;
  final String jogoAtual;

  const SelecionarPersonagemPage({
    super.key,
    required this.titulo,
    this.personagens = personagensSmash,
    this.jogoAtual = 'Super Smash Bros. Ultimate',
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
                      CharacterAvatar(
                        personagem: personagem.name,
                        jogo: jogoAtual,
                        size: 52,
                        initialOverride: personagem.initial,
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
                            RankBadge(rank: personagem.rank),
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
  final String jogo;

  const RegistrarPartidaPage({
    super.key,
    required this.personagemAtual,
    this.jogo = 'Super Smash Bros. Ultimate',
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
        builder: (context) => SelecionarPersonagemPage(
          titulo: 'Escolher personagem adversário',
          personagens: rosterDoJogo(widget.jogo),
          jogoAtual: widget.jogo,
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
                    personagemAdversario == null
                        ? CircleAvatar(
                            radius: 28,
                            child: Text(
                              inicialAdversario,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : CharacterAvatar(
                            personagem: personagemAdversario!.name,
                            jogo: widget.jogo,
                            size: 56,
                            initialOverride: personagemAdversario!.initial,
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
  final String jogo;

  const HistoricoPage({
    super.key,
    required this.historico,
    required this.personagemAtual,
    this.jogo = 'Super Smash Bros. Ultimate',
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
          jogo: widget.jogo,
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
  final String jogo;

  const DetalhesPartidaPage({
    super.key,
    required this.partida,
    this.jogo = 'Super Smash Bros. Ultimate',
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
          jogo: jogo,
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
  final String jogo;

  const EditarPartidaPage({
    super.key,
    required this.partida,
    this.jogo = 'Super Smash Bros. Ultimate',
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
        builder: (context) => SelecionarPersonagemPage(
          titulo: 'Editar seu personagem',
          personagens: rosterDoJogo(widget.jogo),
          jogoAtual: widget.jogo,
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
        builder: (context) => SelecionarPersonagemPage(
          titulo: 'Editar personagem adversário',
          personagens: rosterDoJogo(widget.jogo),
          jogoAtual: widget.jogo,
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
                    CharacterAvatar(
                      personagem: personagemJogador.name,
                      jogo: widget.jogo,
                      size: 56,
                      initialOverride: personagemJogador.initial,
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
                    personagemAdversario == null
                        ? CircleAvatar(
                            radius: 28,
                            child: Text(
                              inicialAdversario,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : CharacterAvatar(
                            personagem: personagemAdversario!.name,
                            jogo: widget.jogo,
                            size: 56,
                            initialOverride: personagemAdversario!.initial,
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
  final String jogoAtual;

  const ResumoTreinoPage({
    super.key,
    required this.personagemAtual,
    required this.historico,
    required this.jogoAtual,
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

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: MatchupHeader(
                                        jogo: jogoAtual,
                                        personagem: personagemAtual.name,
                                        adversario: matchup.personagemAdversario,
                                        avatarSize: 26,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '${matchup.total}x • ${matchup.winrate.toStringAsFixed(1)}% • $sinalMatchup${matchup.saldoPdl} PDL',
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
  final String jogoAtual;

  const EstatisticasPage({
    super.key,
    required this.personagemAtual,
    required this.historico,
    required this.jogoAtual,
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
          jogoAtual: jogoAtual,
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
                  Row(
                    children: [
                      RankBadge(rank: personagemAtual.rank),
                      const SizedBox(width: 10),
                      Text(
                        '${personagemAtual.pdl} PDL',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  MatchupHeader(
                                    jogo: jogoAtual,
                                    personagem: partida.personagemJogador,
                                    adversario: partida.personagemAdversario,
                                    avatarSize: 26,
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${partida.nickAdversario} • ${partida.resultado}',
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
  final String jogoAtual;

  const MatchupStatsPage({
    super.key,
    required this.personagemAtual,
    required this.partidasDoPersonagem,
    required this.jogoAtual,
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
                        MatchupHeader(
                          jogo: jogoAtual,
                          personagem: personagemAtual.name,
                          adversario: matchup.personagemAdversario,
                          avatarSize: 34,
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
