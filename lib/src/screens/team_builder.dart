part of '../../main.dart';

class MontarTimeInvinciblePage extends StatefulWidget {
  final TimePrincipalInvincible timeInicial;

  const MontarTimeInvinciblePage({
    super.key,
    this.timeInicial = timePrincipalInvincibleVazio,
  });

  @override
  State<MontarTimeInvinciblePage> createState() =>
      _MontarTimeInvinciblePageState();
}

class _MontarTimeInvinciblePageState extends State<MontarTimeInvinciblePage> {
  final TextEditingController buscaController = TextEditingController();

  Character? slot1;
  Character? slot2;
  Character? slot3;
  int slotAtivo = 0;
  String termoBusca = '';

  @override
  void initState() {
    super.initState();
    slot1 = encontrarPersonagem(widget.timeInicial.slot1);
    slot2 = encontrarPersonagem(widget.timeInicial.slot2);
    slot3 = encontrarPersonagem(widget.timeInicial.slot3);
    slotAtivo = proximoSlotVazio() ?? 0;
  }

  @override
  void dispose() {
    buscaController.dispose();
    super.dispose();
  }

  List<Character> get roster {
    return rosterDoJogo(jogoInvincibleVs);
  }

  List<Character?> get slots {
    return [slot1, slot2, slot3];
  }

  TimePrincipalInvincible get timeAtual {
    return TimePrincipalInvincible(
      slot1: slot1?.name ?? '',
      slot2: slot2?.name ?? '',
      slot3: slot3?.name ?? '',
    );
  }

  Character? encontrarPersonagem(String nome) {
    if (nome.trim().isEmpty) return null;

    final String nomeNormalizado = normalizarNomePersonagem(nome);
    for (final personagem in roster) {
      if (personagem.name == nomeNormalizado) {
        return personagem;
      }
    }

    return null;
  }

  int? proximoSlotVazio() {
    for (int index = 0; index < slots.length; index++) {
      if (slots[index] == null) return index;
    }

    return null;
  }

  int proximoSlotDepois(int indexAtual) {
    for (int passo = 1; passo <= slots.length; passo++) {
      final int index = (indexAtual + passo) % slots.length;
      if (slots[index] == null) return index;
    }

    return (indexAtual + 1) % slots.length;
  }

  void definirSlot(int index, Character? personagem) {
    switch (index) {
      case 0:
        slot1 = personagem;
        break;
      case 1:
        slot2 = personagem;
        break;
      case 2:
        slot3 = personagem;
        break;
    }
  }

  void selecionarPersonagem(Character personagem) {
    setState(() {
      final int indexExistente = slots.indexWhere(
        (selecionado) => selecionado?.name == personagem.name,
      );

      if (indexExistente >= 0 && indexExistente != slotAtivo) {
        definirSlot(indexExistente, null);
      }

      definirSlot(slotAtivo, personagem);
      slotAtivo = proximoSlotDepois(slotAtivo);
    });
  }

  void removerSlot(int index) {
    setState(() {
      definirSlot(index, null);
      slotAtivo = index;
    });
  }

  void salvarTime() {
    final TimePrincipalInvincible time = timeAtual;

    if (!time.completo) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Time incompleto'),
            content: const Text(
              'Escolha os 3 personagens do Time Principal antes de salvar.',
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

    Navigator.pop(context, time);
  }

  @override
  Widget build(BuildContext context) {
    final String termo = termoBusca.trim().toLowerCase();
    final List<Character> personagensFiltrados = roster.where((personagem) {
      if (termo.isEmpty) return true;

      return personagem.name.toLowerCase().contains(termo) ||
          personagem.initial.toLowerCase().contains(termo);
    }).toList();

    final TimePrincipalInvincible time = timeAtual;

    return Scaffold(
      appBar: AppBar(title: const Text('Montar Time'), centerTitle: true),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isMobile = constraints.maxWidth < 680;
          final int colunas = constraints.maxWidth >= 980
              ? 4
              : constraints.maxWidth >= 680
              ? 3
              : 2;
          final double horizontalPadding = isMobile ? 18 : 24;
          final double maxContentWidth = constraints.maxWidth > 1120
              ? 1120
              : constraints.maxWidth;
          final double contentWidth = maxContentWidth - (horizontalPadding * 2);
          final double slotWidth = isMobile
              ? contentWidth
              : (contentWidth - 24) / 3;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  24,
                  horizontalPadding,
                  16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Meu Time Principal',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      time.completo ? time.texto : 'Nenhum time definido',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (int index = 0; index < slots.length; index++)
                          SizedBox(
                            width: slotWidth,
                            child: _InvincibleTeamSlotCard(
                              label: 'Slot ${index + 1}',
                              personagem: slots[index],
                              jogo: jogoInvincibleVs,
                              ativo: slotAtivo == index,
                              onTap: () {
                                setState(() {
                                  slotAtivo = index;
                                });
                              },
                              onRemove: slots[index] == null
                                  ? null
                                  : () => removerSlot(index),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: buscaController,
                      decoration: const InputDecoration(
                        labelText: 'Pesquisar personagem',
                        hintText: 'Ex: Invincible, Atom Eve, Omni-Man...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (valor) {
                        setState(() {
                          termoBusca = valor;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: personagensFiltrados.isEmpty
                          ? const Center(
                              child: Text('Nenhum personagem encontrado.'),
                            )
                          : GridView.builder(
                              itemCount: personagensFiltrados.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: colunas,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: isMobile ? 1.55 : 1.8,
                                  ),
                              itemBuilder: (context, index) {
                                final Character personagem =
                                    personagensFiltrados[index];
                                final bool selecionado = slots.any(
                                  (slot) => slot?.name == personagem.name,
                                );

                                return _InvincibleTeamCharacterCard(
                                  personagem: personagem,
                                  selecionado: selecionado,
                                  onTap: () => selecionarPersonagem(personagem),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: salvarTime,
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Salvar Time'),
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

class _InvincibleTeamSlotCard extends StatelessWidget {
  final String label;
  final Character? personagem;
  final String jogo;
  final bool ativo;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const _InvincibleTeamSlotCard({
    required this.label,
    required this.personagem,
    required this.jogo,
    required this.ativo,
    required this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Character? selecionado = personagem;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 138),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ativo
              ? BrandColors.ambarDourado.withValues(alpha: 0.10)
              : scheme.surfaceContainerHighest.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: ativo
                ? BrandColors.ambarDourado
                : scheme.outline.withValues(alpha: 0.35),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                if (ativo)
                  const Icon(Icons.radio_button_checked, size: 18)
                else
                  const Icon(Icons.radio_button_unchecked, size: 18),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (selecionado == null)
                  CircleAvatar(
                    radius: 26,
                    child: Text(label.replaceAll('Slot ', '')),
                  )
                else
                  CharacterAvatar(
                    personagem: selecionado.name,
                    jogo: jogo,
                    size: 52,
                    initialOverride: selecionado.initial,
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selecionado?.name ?? 'Selecionar Personagem',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                OutlinedButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.swap_horiz, size: 18),
                  label: Text(selecionado == null ? 'Selecionar' : 'Trocar'),
                ),
                if (selecionado != null)
                  TextButton.icon(
                    onPressed: onRemove,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Remover'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InvincibleTeamCharacterCard extends StatelessWidget {
  final Character personagem;
  final bool selecionado;
  final VoidCallback onTap;

  const _InvincibleTeamCharacterCard({
    required this.personagem,
    required this.selecionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CharacterAvatar(
                personagem: personagem.name,
                jogo: jogoInvincibleVs,
                size: 52,
                initialOverride: personagem.initial,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  personagem.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selecionado ? Icons.check_circle : Icons.add_circle_outline,
                color: selecionado ? BrandColors.ambarDourado : scheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
