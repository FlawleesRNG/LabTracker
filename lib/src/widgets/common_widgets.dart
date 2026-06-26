part of '../../main.dart';

class InfoBox extends StatelessWidget {
  final String titulo;
  final String valor;

  const InfoBox({super.key, required this.titulo, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          valor,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(titulo),
      ],
    );
  }
}

void irParaSelecaoDeJogos(BuildContext context) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (context) => const SelecionarJogoInicialPage()),
    (route) => false,
  );
}

class HomeNavigationButton extends StatelessWidget {
  const HomeNavigationButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      padding: const EdgeInsets.all(12),
      visualDensity: VisualDensity.standard,
      onPressed: () {
        irParaSelecaoDeJogos(context);
      },
      tooltip: 'Ir para seleção de jogos',
      icon: const Icon(Icons.home_outlined),
    );
  }
}

class CompactAppBarTitle extends StatelessWidget {
  final String text;

  const CompactAppBarTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
    );
  }
}

class SearchableOptionField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final IconData icon;

  const SearchableOptionField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.icon = Icons.search,
  });

  Future<void> _abrirBusca(BuildContext context) async {
    final String? escolhido = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        String busca = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final String termo = busca.trim().toLowerCase();
            final List<String> filtradas = options
                .where((opcao) => opcao.toLowerCase().contains(termo))
                .toList();

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.78,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Pesquisar',
                        hintText: 'Digite para filtrar...',
                        prefixIcon: Icon(icon),
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (valor) {
                        setModalState(() {
                          busca = valor;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filtradas.isEmpty
                          ? const Center(
                              child: Text('Nenhuma opção encontrada.'),
                            )
                          : ListView.separated(
                              itemCount: filtradas.length,
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final String opcao = filtradas[index];
                                final bool selecionada = opcao == value;
                                return ListTile(
                                  title: Text(opcao),
                                  trailing: selecionada
                                      ? const Icon(Icons.check_circle)
                                      : null,
                                  onTap: () => Navigator.pop(context, opcao),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (escolhido != null) {
      onChanged(escolhido);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String valorExibido = options.contains(value) || options.isEmpty
        ? value
        : options.first;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _abrirBusca(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: Icon(icon),
        ),
        child: Text(valorExibido, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class AppImageWithFallback extends StatefulWidget {
  final List<AppImageSource> imageSources;
  final Widget fallback;
  final BoxFit fit;
  final Alignment alignment;
  final FilterQuality filterQuality;
  final Color? color;
  final double? width;
  final double? height;

  const AppImageWithFallback({
    super.key,
    required this.imageSources,
    required this.fallback,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.filterQuality = FilterQuality.low,
    this.color,
    this.width,
    this.height,
  });

  @override
  State<AppImageWithFallback> createState() => _AppImageWithFallbackState();
}

class _AppImageWithFallbackState extends State<AppImageWithFallback> {
  int sourceIndex = 0;
  bool usingLocalAsset = false;

  @override
  void didUpdateWidget(covariant AppImageWithFallback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageSources != widget.imageSources) {
      sourceIndex = 0;
      usingLocalAsset = false;
    }
  }

  void tryLocalOrNext(AppImageSource source) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final int totalSources = widget.imageSources
          .where((imageSource) => !imageSource.isEmpty)
          .length;
      final bool canTryLocal =
          !usingLocalAsset && source.localAsset.trim().isNotEmpty;
      if (canTryLocal) {
        setState(() => usingLocalAsset = true);
        return;
      }

      if (sourceIndex + 1 < totalSources) {
        setState(() {
          sourceIndex += 1;
          usingLocalAsset = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<AppImageSource> sources = widget.imageSources
        .where((source) => !source.isEmpty)
        .toList();

    if (sources.isEmpty || sourceIndex >= sources.length) {
      return widget.fallback;
    }

    final AppImageSource source = sources[sourceIndex];
    final String remoteUrl = source.remoteUrl.trim();
    final String localAsset = source.localAsset.trim();

    Widget localImageOrFallback() {
      if (localAsset.isEmpty) return widget.fallback;

      return Image.asset(
        localAsset,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        alignment: widget.alignment,
        filterQuality: widget.filterQuality,
        color: widget.color,
        errorBuilder: (_, _, _) {
          tryLocalOrNext(source);
          return widget.fallback;
        },
      );
    }

    if (!usingLocalAsset && remoteUrl.isNotEmpty) {
      return Image.network(
        remoteUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        alignment: widget.alignment,
        filterQuality: widget.filterQuality,
        color: widget.color,
        errorBuilder: (_, _, _) {
          tryLocalOrNext(source);
          return localImageOrFallback();
        },
      );
    }

    if (localAsset.isNotEmpty) {
      return localImageOrFallback();
    }

    tryLocalOrNext(source);
    return widget.fallback;
  }
}

class CharacterAvatar extends StatefulWidget {
  final String personagem;
  final String jogo;
  final double size;
  final String? initialOverride;
  final Map<String, String> smashCoverPreferences;
  final bool usarPreferenciaVisualSmash;

  const CharacterAvatar({
    super.key,
    required this.personagem,
    required this.jogo,
    this.size = 52,
    this.initialOverride,
    this.smashCoverPreferences = const {},
    this.usarPreferenciaVisualSmash = false,
  });

  @override
  State<CharacterAvatar> createState() => _CharacterAvatarState();
}

class _CharacterAvatarState extends State<CharacterAvatar> {
  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<AppImageSource> imageSources = widget.usarPreferenciaVisualSmash
        ? getCharacterImageSourcesWithSmashPreference(
            widget.personagem,
            widget.jogo,
            widget.smashCoverPreferences,
          )
        : getCharacterImageSources(widget.jogo, widget.personagem);
    final String initial =
        widget.initialOverride ??
        (widget.personagem.isNotEmpty
            ? widget.personagem[0].toUpperCase()
            : '?');

    Widget fallback() => Center(
      child: Text(
        initial,
        style: TextStyle(
          fontSize: widget.size * 0.45,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.size / 2),
        child: Container(
          color: scheme.surfaceContainerHighest,
          child: AppImageWithFallback(
            imageSources: imageSources,
            fallback: fallback(),
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
      ),
    );
  }
}

class RankBadge extends StatelessWidget {
  final String rank;

  const RankBadge({super.key, required this.rank});

  List<Color> get rankColors {
    if (rank.contains('New Blood')) {
      return [Colors.green.shade400, Colors.green.shade800];
    }
    if (rank.contains('Rookie')) {
      return [Colors.lightGreen.shade300, Colors.green.shade700];
    }
    if (rank.contains('Bronze')) {
      return [Colors.brown.shade300, Colors.brown.shade700];
    }
    if (rank.contains('Silver')) {
      return [Colors.blueGrey.shade200, Colors.blueGrey.shade600];
    }
    if (rank.contains('Gold')) {
      return [Colors.amber.shade300, Colors.orange.shade700];
    }
    if (rank.contains('Platinum')) {
      return [Colors.cyan.shade200, Colors.teal.shade700];
    }
    if (rank.contains('Diamond')) {
      return [Colors.lightBlueAccent.shade100, Colors.blue.shade700];
    }
    if (rank.contains('Superhero')) {
      return [Colors.redAccent.shade200, Colors.red.shade800];
    }
    if (rank.contains('Guardian of the Globe')) {
      return [Colors.deepPurpleAccent.shade100, Colors.deepPurple.shade800];
    }
    if (rank.contains('Starter')) {
      return [Colors.brown.shade400, Colors.brown.shade700];
    }
    if (rank.contains('For Fun')) {
      return [Colors.grey.shade400, Colors.grey.shade600];
    }
    if (rank.contains('Quick Play')) {
      return [Colors.amber.shade400, Colors.orange.shade700];
    }
    if (rank.contains('Brawl')) {
      return [Colors.teal.shade300, Colors.blueGrey.shade600];
    }
    if (rank.contains('For Glory')) {
      return [Colors.purple.shade400, Colors.deepPurple.shade800];
    }
    if (rank.contains('Melee')) {
      return [Colors.redAccent.shade400, Colors.red.shade900];
    }
    if (rank.contains('Elite')) {
      return [Colors.yellowAccent.shade400, Colors.deepOrange.shade600];
    }
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
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.6),
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
            errorBuilder: (_, _, _) =>
                const Icon(Icons.star, size: 14, color: Colors.white),
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
                Shadow(
                  color: Colors.black54,
                  blurRadius: 2,
                  offset: Offset(1, 1),
                ),
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
  final Map<String, String> smashCoverPreferences;
  final bool usarPreferenciaVisualSmash;

  const MatchupHeader({
    super.key,
    required this.jogo,
    required this.personagem,
    required this.adversario,
    this.avatarSize = 30,
    this.style,
    this.smashCoverPreferences = const {},
    this.usarPreferenciaVisualSmash = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CharacterAvatar(
          personagem: personagem,
          jogo: jogo,
          size: avatarSize,
          smashCoverPreferences: smashCoverPreferences,
          usarPreferenciaVisualSmash: usarPreferenciaVisualSmash,
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
        CharacterAvatar(personagem: adversario, jogo: jogo, size: avatarSize),
      ],
    );
  }
}

class SelecionarPersonagemPage extends StatefulWidget {
  final String titulo;
  final List<Character> personagens;
  final String jogoAtual;
  final Map<String, String> smashCoverPreferences;
  final bool usarPreferenciaVisualSmash;

  const SelecionarPersonagemPage({
    super.key,
    required this.titulo,
    this.personagens = personagensSmash,
    this.jogoAtual = 'Super Smash Bros. Ultimate',
    this.smashCoverPreferences = const {},
    this.usarPreferenciaVisualSmash = false,
  });

  @override
  State<SelecionarPersonagemPage> createState() =>
      _SelecionarPersonagemPageState();
}

class _SelecionarPersonagemPageState extends State<SelecionarPersonagemPage> {
  String termoBusca = '';
  Map<String, String> smashCoverPreferences = {};

  @override
  void initState() {
    super.initState();
    smashCoverPreferences = {...widget.smashCoverPreferences};
    carregarPreferenciasVisuaisSmash();
  }

  @override
  void didUpdateWidget(covariant SelecionarPersonagemPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.smashCoverPreferences != widget.smashCoverPreferences) {
      smashCoverPreferences = {...widget.smashCoverPreferences};
    }
  }

  Future<void> carregarPreferenciasVisuaisSmash() async {
    if (!widget.usarPreferenciaVisualSmash ||
        !jogoEhSmash(widget.jogoAtual) ||
        smashCoverPreferences.isNotEmpty) {
      return;
    }

    final Map<String, String> preferencias =
        await carregarPreferenciasCapaSmashPrefs();

    if (!mounted) return;

    setState(() {
      smashCoverPreferences = preferencias;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Character> personagensFiltrados = widget.personagens.where((
      personagem,
    ) {
      final String termo = termoBusca.trim().toLowerCase();
      if (termo.isEmpty) return true;

      return personagem.name.toLowerCase().contains(termo) ||
          personagem.initial.toLowerCase().contains(termo);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: CompactAppBarTitle(widget.titulo),
        centerTitle: true,
        actions: const [HomeNavigationButton()],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isMobile = constraints.maxWidth < 600;
          final double padding = isMobile ? 20 : 24;
          final double avatarSize = isMobile ? 42 : 52;

          return Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              children: [
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
                const SizedBox(height: 18),
                Expanded(
                  child: GridView.builder(
                    itemCount: personagensFiltrados.length,
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: isMobile ? 180 : 230,
                      mainAxisSpacing: isMobile ? 12 : 16,
                      crossAxisSpacing: isMobile ? 12 : 16,
                      childAspectRatio: isMobile ? 1.30 : 1.55,
                    ),
                    itemBuilder: (context, index) {
                      final personagem = personagensFiltrados[index];

                      return _CharacterSelectionCard(
                        personagem: personagem,
                        jogo: widget.jogoAtual,
                        avatarSize: avatarSize,
                        isMobile: isMobile,
                        favorito: false,
                        stats: const CharacterUsageStats(),
                        mostrarFavorito: false,
                        smashCoverPreferences: smashCoverPreferences,
                        usarPreferenciaVisualSmash:
                            widget.usarPreferenciaVisualSmash &&
                            jogoEhSmash(widget.jogoAtual),
                        onTap: () => Navigator.pop(context, personagem),
                        onToggleFavorite: () {},
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

class DatePickerField extends StatelessWidget {
  final String label;
  final DateTime data;
  final ValueChanged<DateTime> onChanged;

  const DatePickerField({
    super.key,
    required this.label,
    required this.data,
    required this.onChanged,
  });

  Future<void> escolherData(BuildContext context) async {
    final DateTime? dataEscolhida = await showDatePicker(
      context: context,
      initialDate: data,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (dataEscolhida == null) return;

    onChanged(
      DateTime(
        dataEscolhida.year,
        dataEscolhida.month,
        dataEscolhida.day,
        data.hour,
        data.minute,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.event_outlined),
            title: Text(formatarDataCurta(data)),
            trailing: OutlinedButton(
              onPressed: () => escolherData(context),
              child: const Text('Alterar'),
            ),
          ),
        ),
      ],
    );
  }
}
