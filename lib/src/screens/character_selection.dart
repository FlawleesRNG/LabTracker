part of '../../main.dart';

class _CharacterSelectionCard extends StatelessWidget {
  final Character personagem;
  final String jogo;
  final double avatarSize;
  final bool isMobile;
  final VoidCallback onTap;

  const _CharacterSelectionCard({
    required this.personagem,
    required this.jogo,
    required this.avatarSize,
    required this.isMobile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String pontosLabel = labelPontosRank(jogo);

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
              ),
              SizedBox(width: isMobile ? 10 : 14),
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
                    SizedBox(height: isMobile ? 3 : 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isMobile ? 74 : 110,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: RankBadge(rank: personagem.rank),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${personagem.pdl} $pontosLabel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: isMobile ? 12 : 14),
                    ),
                  ],
                ),
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

  void entrarNoTracker(BuildContext context, Character personagem) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomePage(
          jogoAtual: widget.jogoSelecionado,
          personagemInicialNome: personagem.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Character> personagensFiltrados =
        rosterDoJogo(widget.jogoSelecionado).where((personagem) {
          final String termo = termoBusca.trim().toLowerCase();
          if (termo.isEmpty) return true;

          return personagem.name.toLowerCase().contains(termo) ||
              personagem.initial.toLowerCase().contains(termo);
        }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Escolher personagem'),
        centerTitle: true,
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
                  'Escolha o personagem que você vai usar nesta sessão.',
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
                        jogo: widget.jogoSelecionado,
                        avatarSize: avatarSize,
                        isMobile: isMobile,
                        onTap: () => entrarNoTracker(context, personagem),
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
