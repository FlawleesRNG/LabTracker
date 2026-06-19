part of '../../main.dart';

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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
        builder: (context) =>
            CriarPerfilInicialPage(onPerfilCriado: widget.onPerfilCriado),
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
                    googleSuportado
                        ? 'Entrar sem conta Google'
                        : 'Entrar com um nick',
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

  const CriarPerfilInicialPage({super.key, required this.onPerfilCriado});

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
      appBar: AppBar(title: const LtLogo(scale: 0.85), centerTitle: true),
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

class SelecionarJogoInicialPage extends StatefulWidget {
  const SelecionarJogoInicialPage({super.key});

  @override
  State<SelecionarJogoInicialPage> createState() =>
      _SelecionarJogoInicialPageState();
}

class _SelecionarJogoInicialPageState extends State<SelecionarJogoInicialPage> {
  String busca = '';

  Future<void> abrirSelecaoPersonagem(BuildContext context, String jogo) async {
    if (jogo == jogoInvincibleVs) {
      final TimePrincipalInvincible? time =
          await Navigator.push<TimePrincipalInvincible>(
            context,
            MaterialPageRoute<TimePrincipalInvincible>(
              builder: (context) => const MontarTimeInvinciblePage(),
            ),
          );

      if (time == null || !mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              HomePage(jogoAtual: jogo, timePrincipalInicial: time),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SelecionarPersonagemInicialPage(jogoSelecionado: jogo),
      ),
    );
  }

  String siglaDoJogo(String jogo) {
    switch (jogo) {
      case 'Super Smash Bros. Ultimate':
        return 'SSBU';
      case 'Street Fighter 6':
        return 'SF6';
      case 'Mortal Kombat 1':
        return 'MK1';
      case 'Avatar Legends: The Fighting Game':
        return 'ATLA';
      case 'Guilty Gear -Strive-':
        return 'GGST';
      case 'The King of Fighters XV':
        return 'KOF';
      case 'Dragon Ball FighterZ':
        return 'DBFZ';
      case 'Invincible VS':
        return 'IVS';
      case 'Fatal Fury':
        return 'FF';
      default:
        return jogo.isNotEmpty ? jogo[0].toUpperCase() : '?';
    }
  }

  Color corDoJogo(String jogo) {
    switch (jogo) {
      case 'Super Smash Bros. Ultimate':
        return const Color(0xFFE11D48);
      case 'Street Fighter 6':
        return const Color(0xFF2563EB);
      case 'Mortal Kombat 1':
        return const Color(0xFFF59E0B);
      case 'Avatar Legends: The Fighting Game':
        return const Color(0xFF0EA5E9);
      case 'Guilty Gear -Strive-':
        return const Color(0xFFDC2626);
      case 'The King of Fighters XV':
        return const Color(0xFF7C3AED);
      case 'Dragon Ball FighterZ':
        return const Color(0xFFF97316);
      case 'Invincible VS':
        return const Color(0xFF22C55E);
      case 'Fatal Fury':
        return const Color(0xFFEF4444);
      default:
        return BrandColors.ambarDourado;
    }
  }

  int colunasPorLargura(double largura) {
    if (largura >= 1180) return 5;
    if (largura >= 920) return 4;
    if (largura >= 620) return 3;
    return 2;
  }

  Widget capaDoJogo(String jogo) {
    final String logo = logoDoJogo(jogo);
    final Color cor = corDoJogo(jogo);
    final String sigla = siglaDoJogo(jogo);

    Widget fallback() {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [cor, Color.lerp(cor, Colors.black, 0.45) ?? cor],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -18,
              bottom: -22,
              child: Icon(
                Icons.sports_esports,
                size: 108,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
            Center(
              child: Text(
                sigla,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (logo.isEmpty) return fallback();

    if (logo.startsWith('assets/')) {
      return Container(
        color: BrandColors.pretoCarvao,
        child: Image.asset(
          logo,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback(),
        ),
      );
    }

    return Container(
      color: BrandColors.pretoCarvao,
      padding: const EdgeInsets.all(10),
      child: Image.network(
        logo,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => fallback(),
      ),
    );
  }

  Widget cardJogo(String jogo) {
    final int totalPersonagens = rosterDoJogo(jogo).length;
    final Color cor = corDoJogo(jogo);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          abrirSelecaoPersonagem(context, jogo);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  capaDoJogo(jogo),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.16),
                        ),
                      ),
                      child: Text(
                        siglaDoJogo(jogo),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: BrandColors.grafite),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    jogo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: cor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          '$totalPersonagens personagens',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String termo = busca.trim().toLowerCase();
    final List<String> jogosFiltrados = jogosDisponiveis
        .where((jogo) => jogo.toLowerCase().contains(termo))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const LtLogo(scale: 0.85), centerTitle: true),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool telaLarga = constraints.maxWidth >= 900;
          final int colunas = colunasPorLargura(constraints.maxWidth);

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: telaLarga ? 1180 : double.infinity,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: telaLarga ? 32 : 18,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Biblioteca de jogos',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Escolha um jogo para treinar, registrar partidas e acompanhar evolução.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Pesquisar jogo',
                        hintText: 'Ex: Smash, KOF, Guilty Gear...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (valor) {
                        setState(() {
                          busca = valor;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: jogosFiltrados.isEmpty
                          ? const Center(child: Text('Nenhum jogo encontrado.'))
                          : GridView.builder(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: colunas,
                                    crossAxisSpacing: 14,
                                    mainAxisSpacing: 14,
                                    childAspectRatio: telaLarga ? 0.82 : 0.76,
                                  ),
                              itemCount: jogosFiltrados.length,
                              itemBuilder: (context, index) {
                                return cardJogo(jogosFiltrados[index]);
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
