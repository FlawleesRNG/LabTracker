part of '../../main.dart';

class _CharacterSelectionCard extends StatelessWidget {
  final Character personagem;
  final String jogo;
  final double avatarSize;
  final bool isMobile;
  final bool favorito;
  final CharacterUsageStats stats;
  final bool mostrarFavorito;
  final Map<String, String> smashCoverPreferences;
  final bool usarPreferenciaVisualSmash;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  const _CharacterSelectionCard({
    required this.personagem,
    required this.jogo,
    required this.avatarSize,
    required this.isMobile,
    required this.favorito,
    required this.stats,
    this.mostrarFavorito = true,
    this.smashCoverPreferences = const {},
    this.usarPreferenciaVisualSmash = false,
    required this.onTap,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final String pontosLabel = labelPontosRank(jogo);
    final int pontos = stats.pdl < 0 ? 0 : stats.pdl;
    final String rank = calcularRankDoJogo(jogo, pontos);
    final String resumoPartidas = stats.temPartidas
        ? '${stats.partidas} partidas - ${stats.winrate.toStringAsFixed(0)}% WR'
        : 'Sem partidas registradas';

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 10 : 12),
          child: Row(
            children: [
              CharacterAvatar(
                personagem: personagem.name,
                jogo: jogo,
                size: avatarSize,
                initialOverride: personagem.initial,
                smashCoverPreferences: smashCoverPreferences,
                usarPreferenciaVisualSmash: usarPreferenciaVisualSmash,
              ),
              SizedBox(width: isMobile ? 10 : 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        personagem.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 17,
                          fontWeight: FontWeight.bold,
                          height: 1.05,
                        ),
                      ),
                    ),
                    SizedBox(height: isMobile ? 4 : 5),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isMobile ? 96 : 120,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: RankBadge(rank: rank),
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$pontos $pontosLabel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: isMobile ? 12 : 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      resumoPartidas,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: BrandColors.brancoSuave.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (mostrarFavorito)
                IconButton(
                  tooltip: favorito
                      ? 'Remover dos favoritos'
                      : 'Adicionar aos favoritos',
                  icon: Icon(
                    favorito ? Icons.star : Icons.star_border,
                    color: favorito ? BrandColors.ambarDourado : null,
                  ),
                  onPressed: onToggleFavorite,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class SelecionarPersonagemInicialPage extends StatefulWidget {
  final String jogoSelecionado;

  const SelecionarPersonagemInicialPage({
    super.key,
    required this.jogoSelecionado,
  });

  @override
  State<SelecionarPersonagemInicialPage> createState() =>
      _SelecionarPersonagemInicialPageState();
}

class _SelecionarPersonagemInicialPageState
    extends State<SelecionarPersonagemInicialPage> {
  String termoBusca = '';
  Map<String, List<String>> personagensFavoritosPorJogo = {};
  Map<String, List<String>> personagensRecentesPorJogo = {};
  List<PartidaRegistrada> historicoPersistido = [];
  Map<String, String> smashCoverPreferences = {};
  String filtroPersonagens = 'Todos';
  String ordenacaoPersonagens = 'Favoritos primeiro';

  static const List<String> filtrosPersonagens = [
    'Todos',
    'Favoritos',
    'Recentes',
    'Com partidas',
    'Sem partidas',
  ];
  static const List<String> ordenacoesPersonagens = [
    'Favoritos primeiro',
    'Maior rank',
    'Menor rank',
    'Maior PDL',
    'Menor PDL',
    'Mais jogados',
    'Menos jogados',
    'Maior winrate',
    'Menor winrate',
    'Mais recente',
    'A-Z',
  ];

  @override
  void initState() {
    super.initState();
    carregarPersonalizacaoPersonagens();
  }

  Future<void> carregarPersonalizacaoPersonagens() async {
    final Map<String, List<String>> favoritos =
        await carregarPersonagensFavoritosPorJogo();
    final Map<String, List<String>> recentes =
        await carregarPersonagensRecentesPorJogo();
    final List<PartidaRegistrada> historico =
        await carregarHistoricoPersistido();
    final Map<String, String> preferenciasCapaSmash =
        jogoEhSmash(widget.jogoSelecionado)
        ? await carregarPreferenciasCapaSmashPrefs()
        : {};

    if (!mounted) return;

    setState(() {
      personagensFavoritosPorJogo = favoritos;
      personagensRecentesPorJogo = recentes;
      historicoPersistido = historico;
      smashCoverPreferences = preferenciasCapaSmash;
    });
  }

  Set<String> get favoritosDoJogo {
    return (personagensFavoritosPorJogo[widget.jogoSelecionado] ?? const [])
        .toSet();
  }

  List<String> get recentesDoJogo {
    return personagensRecentesPorJogo[widget.jogoSelecionado] ?? const [];
  }

  Future<void> alternarFavoritoPersonagem(String personagem) async {
    final Map<String, List<String>> favoritos = {
      for (final entry in personagensFavoritosPorJogo.entries)
        entry.key: [...entry.value],
    };
    final List<String> lista = [
      ...(favoritos[widget.jogoSelecionado] ?? const []),
    ];

    if (lista.contains(personagem)) {
      lista.remove(personagem);
    } else {
      lista.add(personagem);
      lista.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    }

    if (lista.isEmpty) {
      favoritos.remove(widget.jogoSelecionado);
    } else {
      favoritos[widget.jogoSelecionado] = lista;
    }

    setState(() {
      personagensFavoritosPorJogo = favoritos;
    });

    await salvarPersonagensFavoritosPorJogo(favoritos);
  }

  String get textoOrientacaoSelecao {
    if (widget.jogoSelecionado == jogo2Xko) {
      return 'Escolha seu Point/Main.';
    }

    return 'Escolha o personagem que você vai usar nesta sessão.';
  }

  Future<void> entrarNoTracker(
    BuildContext context,
    Character personagem,
  ) async {
    if (widget.jogoSelecionado == jogoKofXV) {
      final TimePrincipalKofXV? time = await Navigator.push<TimePrincipalKofXV>(
        context,
        MaterialPageRoute<TimePrincipalKofXV>(
          builder: (context) => MontarTimeKofXVPage(
            timeInicial: TimePrincipalKofXV(
              point: personagem.name,
              mid: '',
              anchor: '',
            ),
          ),
        ),
      );

      if (time == null || !context.mounted) return;

      for (final nome in time.personagens) {
        await marcarPersonagemRecente(widget.jogoSelecionado, nome);
      }
      await marcarJogoRecente(widget.jogoSelecionado);

      if (!context.mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              HomePage(jogoAtual: widget.jogoSelecionado, timeKofInicial: time),
        ),
      );
      return;
    }

    if (widget.jogoSelecionado == jogo2Xko) {
      final TimePrincipal2XKO? dupla = await Navigator.push<TimePrincipal2XKO>(
        context,
        MaterialPageRoute<TimePrincipal2XKO>(
          builder: (context) => MontarTime2XKOPage(
            timeInicial: TimePrincipal2XKO(point: personagem.name, assist: ''),
          ),
        ),
      );

      if (dupla == null || !context.mounted) return;

      for (final nome in dupla.personagens) {
        await marcarPersonagemRecente(widget.jogoSelecionado, nome);
      }
      await marcarJogoRecente(widget.jogoSelecionado);

      if (!context.mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(
            jogoAtual: widget.jogoSelecionado,
            time2XKOInicial: dupla,
          ),
        ),
      );
      return;
    }

    await marcarPersonagemRecente(widget.jogoSelecionado, personagem.name);
    await marcarJogoRecente(widget.jogoSelecionado);

    if (!context.mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HomePage(
          jogoAtual: widget.jogoSelecionado,
          personagemInicialNome: personagem.name,
        ),
      ),
    );

    if (!mounted || !jogoEhSmash(widget.jogoSelecionado)) return;

    final Map<String, String> preferenciasAtualizadas =
        await carregarPreferenciasCapaSmashPrefs();

    if (!mounted) return;

    setState(() {
      smashCoverPreferences = preferenciasAtualizadas;
    });
  }

  int compararPorNome(Character a, Character b) {
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }

  int indiceRecentePersonagem(String personagem) {
    final int indice = recentesDoJogo.indexOf(personagem);
    return indice == -1 ? 9999 : indice;
  }

  int pontosOrdenacao(Character personagem, CharacterUsageStats stats) {
    if (personagem.pdl != 0) return personagem.pdl;
    return stats.pdl < 0 ? 0 : stats.pdl;
  }

  List<Character> personagensVisiveis() {
    final String termo = termoBusca.trim().toLowerCase();
    final Set<String> favoritos = favoritosDoJogo;
    final List<String> recentes = recentesDoJogo;
    final Map<String, CharacterUsageStats> statsPorPersonagem =
        calcularUsoPersonagensPorJogo(
          historicoPersistido,
          widget.jogoSelecionado,
        );

    final List<Character> personagens = rosterDoJogo(widget.jogoSelecionado)
        .where((personagem) {
          if (termo.isNotEmpty &&
              !personagem.name.toLowerCase().contains(termo) &&
              !personagem.initial.toLowerCase().contains(termo)) {
            return false;
          }

          final CharacterUsageStats stats =
              statsPorPersonagem[personagem.name] ??
              const CharacterUsageStats();

          switch (filtroPersonagens) {
            case 'Favoritos':
              return favoritos.contains(personagem.name);
            case 'Recentes':
              return recentes.contains(personagem.name);
            case 'Com partidas':
              return stats.temPartidas;
            case 'Sem partidas':
              return !stats.temPartidas;
            case 'Todos':
            default:
              return true;
          }
        })
        .toList();

    personagens.sort((a, b) {
      final CharacterUsageStats statsA =
          statsPorPersonagem[a.name] ?? const CharacterUsageStats();
      final CharacterUsageStats statsB =
          statsPorPersonagem[b.name] ?? const CharacterUsageStats();
      final int pontosA = pontosOrdenacao(a, statsA);
      final int pontosB = pontosOrdenacao(b, statsB);

      switch (ordenacaoPersonagens) {
        case 'Maior rank':
        case 'Maior PDL':
          final int comparacao = pontosB.compareTo(pontosA);
          return comparacao != 0 ? comparacao : compararPorNome(a, b);
        case 'Menor rank':
        case 'Menor PDL':
          final int comparacao = pontosA.compareTo(pontosB);
          return comparacao != 0 ? comparacao : compararPorNome(a, b);
        case 'Mais jogados':
          final int comparacao = statsB.partidas.compareTo(statsA.partidas);
          return comparacao != 0 ? comparacao : compararPorNome(a, b);
        case 'Menos jogados':
          final int comparacao = statsA.partidas.compareTo(statsB.partidas);
          return comparacao != 0 ? comparacao : compararPorNome(a, b);
        case 'Maior winrate':
          final int comparacao = statsB.winrate.compareTo(statsA.winrate);
          return comparacao != 0 ? comparacao : compararPorNome(a, b);
        case 'Menor winrate':
          final int comparacao = statsA.winrate.compareTo(statsB.winrate);
          return comparacao != 0 ? comparacao : compararPorNome(a, b);
        case 'Mais recente':
          final int indiceA = indiceRecentePersonagem(a.name);
          final int indiceB = indiceRecentePersonagem(b.name);
          if (indiceA != indiceB) return indiceA.compareTo(indiceB);

          final DateTime? dataA = statsA.ultimaPartida;
          final DateTime? dataB = statsB.ultimaPartida;
          if (dataA != null && dataB != null) {
            final int comparacao = dataB.compareTo(dataA);
            return comparacao != 0 ? comparacao : compararPorNome(a, b);
          }
          if (dataA != null) return -1;
          if (dataB != null) return 1;
          return compararPorNome(a, b);
        case 'A-Z':
          return compararPorNome(a, b);
        case 'Favoritos primeiro':
        default:
          final bool favoritoA = favoritos.contains(a.name);
          final bool favoritoB = favoritos.contains(b.name);
          if (favoritoA != favoritoB) return favoritoA ? -1 : 1;

          final int indiceA = indiceRecentePersonagem(a.name);
          final int indiceB = indiceRecentePersonagem(b.name);
          if (indiceA != indiceB) return indiceA.compareTo(indiceB);

          return compararPorNome(a, b);
      }
    });

    return personagens;
  }

  Widget botaoOrdenacaoPersonagens() {
    return PopupMenuButton<String>(
      initialValue: ordenacaoPersonagens,
      onSelected: (valor) {
        setState(() {
          ordenacaoPersonagens = valor;
        });
      },
      itemBuilder: (context) {
        return [
          for (final ordenacao in ordenacoesPersonagens)
            PopupMenuItem(value: ordenacao, child: Text(ordenacao)),
        ];
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sort, size: 18),
            const SizedBox(width: 8),
            Text(ordenacaoPersonagens),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 20),
          ],
        ),
      ),
    );
  }

  Widget controlesPersonagens() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final filtro in filtrosPersonagens)
          ChoiceChip(
            label: Text(filtro),
            selected: filtroPersonagens == filtro,
            onSelected: (_) {
              setState(() {
                filtroPersonagens = filtro;
              });
            },
          ),
        botaoOrdenacaoPersonagens(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Character> personagensFiltrados = personagensVisiveis();
    final Map<String, CharacterUsageStats> statsPorPersonagem =
        calcularUsoPersonagensPorJogo(
          historicoPersistido,
          widget.jogoSelecionado,
        );

    return Scaffold(
      appBar: AppBar(
        title: const CompactAppBarTitle('Escolher personagem'),
        centerTitle: true,
        actions: const [HomeNavigationButton()],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isMobile = constraints.maxWidth < 600;
          final double horizontalPadding = isMobile ? 20 : 24;
          final double avatarSize = isMobile ? 42 : 52;

          return Padding(
            padding: EdgeInsets.all(horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.jogoSelecionado,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  textoOrientacaoSelecao,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Pesquisar personagem',
                    hintText: 'Ex: Hero, Cloud, Terry...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (valor) {
                    setState(() {
                      termoBusca = valor;
                    });
                  },
                ),
                const SizedBox(height: 12),
                controlesPersonagens(),
                const SizedBox(height: 18),
                Expanded(
                  child: personagensFiltrados.isEmpty
                      ? const Center(
                          child: Text('Nenhum personagem encontrado.'),
                        )
                      : GridView.builder(
                          itemCount: personagensFiltrados.length,
                          gridDelegate:
                              SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: isMobile ? 360 : 320,
                                mainAxisSpacing: isMobile ? 12 : 16,
                                crossAxisSpacing: isMobile ? 12 : 16,
                                childAspectRatio: isMobile ? 2.05 : 2.18,
                              ),
                          itemBuilder: (context, index) {
                            final personagem = personagensFiltrados[index];

                            return _CharacterSelectionCard(
                              personagem: personagem,
                              jogo: widget.jogoSelecionado,
                              avatarSize: avatarSize,
                              isMobile: isMobile,
                              favorito: favoritosDoJogo.contains(
                                personagem.name,
                              ),
                              stats:
                                  statsPorPersonagem[personagem.name] ??
                                  const CharacterUsageStats(),
                              smashCoverPreferences: smashCoverPreferences,
                              usarPreferenciaVisualSmash: jogoEhSmash(
                                widget.jogoSelecionado,
                              ),
                              onTap: () => entrarNoTracker(context, personagem),
                              onToggleFavorite: () {
                                alternarFavoritoPersonagem(personagem.name);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
