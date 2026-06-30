part of '../../main.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseBootstrap.initialize();
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
  // OBS: a CHAVE SECRETA do client NAO entra no app — só o ID abaixo.
  static const String serverClientId =
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
            borderRadius: BorderRadius.circular(AppRadius.card),
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
          style: TextButton.styleFrom(
            foregroundColor: BrandColors.ambarDourado,
          ),
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
                    colors: [
                      BrandColors.laranjaForte,
                      BrandColors.ambarDourado,
                    ],
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
          TextSpan(
            text: 'L',
            style: TextStyle(color: BrandColors.laranjaVivo),
          ),
          TextSpan(
            text: 'T',
            style: TextStyle(color: BrandColors.brancoSuave),
          ),
        ],
      ),
    );

    if (!bordered) {
      return SizedBox(
        height: size,
        child: Center(child: lt),
      );
    }

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
                  TextSpan(
                    text: 'Lab',
                    style: TextStyle(color: BrandColors.laranjaVivo),
                  ),
                  TextSpan(
                    text: 'Tracker',
                    style: TextStyle(color: BrandColors.brancoSuave),
                  ),
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
