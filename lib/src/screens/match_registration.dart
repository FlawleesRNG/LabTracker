part of '../../main.dart';

class RegistrarPartidaPage extends StatefulWidget {
  final Character personagemAtual;
  final String jogo;
  final List<String> sugestoesPlayers;
  final List<String> sugestoesStages;
  final List<String> sugestoesKills;
  final List<String> sugestoesMortes;
  final PartidaRegistrada? partidaInicial;

  const RegistrarPartidaPage({
    super.key,
    required this.personagemAtual,
    this.jogo = 'Super Smash Bros. Ultimate',
    this.sugestoesPlayers = const [],
    this.sugestoesStages = const [],
    this.sugestoesKills = const [],
    this.sugestoesMortes = const [],
    this.partidaInicial,
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
  String detalheOutroKill = '';
  String detalheOutroMorte = '';
  String observacoes = '';
  DateTime dataPartida = DateTime.now();
  int pdlCalculado = 0;

  @override
  void initState() {
    super.initState();

    final PartidaRegistrada? partida = widget.partidaInicial;
    if (partida != null) {
      nickAdversario = partida.nickAdversario == 'Sem nick'
          ? ''
          : partida.nickAdversario;
      personagemAdversario = encontrarPersonagem(partida.personagemAdversario);

      if (partida.stage.trim().isNotEmpty) {
        stageSelecionado = partida.stage;
      }
    }

    pdlCalculado = gerarPdl();
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

  String get killInformada {
    if (naoMatou) return 'Não matou';
    if (formaDeKill == 'Outro') {
      final String detalhe = detalheOutroKill.trim();
      return detalhe.isEmpty ? 'Outro' : detalhe;
    }

    return formaDeKill;
  }

  String get morteInformada {
    if (naoMorreu) return 'Não morreu';
    if (formaDeMorte == 'Outro') {
      final String detalhe = detalheOutroMorte.trim();
      return detalhe.isEmpty ? 'Outro' : detalhe;
    }

    return formaDeMorte;
  }

  List<String> opcoesComSugestoes(
    List<String> opcoesBase,
    List<String> sugestoes,
  ) {
    final List<String> ordenadas = [];

    for (final sugestao in sugestoes) {
      if (opcoesBase.contains(sugestao) && !ordenadas.contains(sugestao)) {
        ordenadas.add(sugestao);
      }
    }

    for (final opcao in opcoesBase) {
      if (!ordenadas.contains(opcao)) {
        ordenadas.add(opcao);
      }
    }

    return ordenadas;
  }

  Character? encontrarPersonagem(String nome) {
    if (nome.trim().isEmpty) return null;

    final String nomeNormalizado = normalizarNomePersonagem(nome);
    for (final personagem in rosterDoJogo(widget.jogo)) {
      if (personagem.name == nomeNormalizado) {
        return personagem;
      }
    }

    return null;
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
    return calcularPdlDaPartida(
      resultado: resultado,
      stocks: stocks,
      porcentagem: porcentagem,
      formaDeKill: killInformada,
      formaDeMorte: morteInformada,
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
    final String killFinal = killInformada;
    final String morteFinal = morteInformada;

    setState(() {
      pdlCalculado = pdlFinal;
    });

    final PartidaRegistrada partida = PartidaRegistrada(
      jogo: widget.jogo,
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
      data: dataPartida,
    );

    showDialog(
      context: context,
      builder: (context) {
        final String textoObservacoes = partida.observacoes.isEmpty
            ? 'Sem observações'
            : partida.observacoes;

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
              child: const Text('Salvar e voltar'),
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
        title: const CompactAppBarTitle('Registrar partida'),
        centerTitle: true,
        actions: const [HomeNavigationButton()],
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
                ButtonSegment(value: 'Vitória', label: Text('Vitória')),
                ButtonSegment(value: 'Derrota', label: Text('Derrota')),
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
            Autocomplete<String>(
              initialValue: TextEditingValue(text: nickAdversario),
              optionsBuilder: (textEditingValue) {
                final String busca = textEditingValue.text.trim().toLowerCase();
                final List<String> sugestoes = widget.sugestoesPlayers;

                if (busca.isEmpty) {
                  return sugestoes.take(6);
                }

                return sugestoes.where(
                  (nick) => nick.toLowerCase().contains(busca),
                );
              },
              onSelected: (valor) {
                setState(() {
                  nickAdversario = valor;
                });
              },
              fieldViewBuilder:
                  (
                    context,
                    textEditingController,
                    focusNode,
                    onFieldSubmitted,
                  ) {
                    return TextField(
                      controller: textEditingController,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        labelText: 'Nick do player',
                        border: OutlineInputBorder(),
                        hintText: 'Digite ou escolha um player já enfrentado',
                        prefixIcon: Icon(Icons.person_search_outlined),
                      ),
                      onChanged: (valor) {
                        setState(() {
                          nickAdversario = valor;
                        });
                      },
                    );
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
            DatePickerField(
              label: 'Data da partida',
              data: dataPartida,
              onChanged: (valor) {
                setState(() {
                  dataPartida = valor;
                });
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Stage / Mapa',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SearchableOptionField(
              label: 'Pesquisar mapa',
              value: stageSelecionado,
              options: opcoesComSugestoes(stagesSmash, widget.sugestoesStages),
              icon: Icons.map_outlined,
              onChanged: (valor) {
                setState(() {
                  stageSelecionado = valor;
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
              initialValue: stocks,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 1, child: Text('1 stock')),
                DropdownMenuItem(value: 2, child: Text('2 stocks')),
                DropdownMenuItem(value: 3, child: Text('3 stocks')),
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
              SearchableOptionField(
                label: 'Pesquisar forma de kill',
                value: formaDeKill,
                options: opcoesComSugestoes(
                  formasDeKill,
                  widget.sugestoesKills,
                ),
                icon: Icons.sports_mma_outlined,
                onChanged: (valor) {
                  setState(() {
                    formaDeKill = valor;
                    pdlCalculado = gerarPdl();
                  });
                },
              ),
              if (formaDeKill == 'Outro') ...[
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Descreva como matou (opcional)',
                    hintText: 'Ex: F-tilt na ledge, dash attack, Kaboom...',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (valor) {
                    setState(() {
                      detalheOutroKill = valor;
                      pdlCalculado = gerarPdl();
                    });
                  },
                ),
              ],
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
              SearchableOptionField(
                label: 'Pesquisar forma de morte',
                value: formaDeMorte,
                options: opcoesComSugestoes(
                  formasDeMorte,
                  widget.sugestoesMortes,
                ),
                icon: Icons.warning_amber_outlined,
                onChanged: (valor) {
                  setState(() {
                    formaDeMorte = valor;
                    pdlCalculado = gerarPdl();
                  });
                },
              ),
              if (formaDeMorte == 'Outro') ...[
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Descreva como morreu (opcional)',
                    hintText: 'Ex: F-smash na ledge, miss input, tech chase...',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (valor) {
                    setState(() {
                      detalheOutroMorte = valor;
                      pdlCalculado = gerarPdl();
                    });
                  },
                ),
              ],
            ] else ...[
              Card(
                child: ListTile(
                  leading: const Icon(Icons.shield_outlined),
                  title: const Text('Como você morreu?'),
                  subtitle: const Text('Não morreu — vitória com 3 stocks.'),
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

class RegistrarPartidaRivalsPage extends StatefulWidget {
  final Character personagemAtual;
  final String jogo;
  final List<String> sugestoesPlayers;
  final List<String> sugestoesStages;
  final PartidaRegistrada? partidaInicial;
  final bool repetirUltima;

  const RegistrarPartidaRivalsPage({
    super.key,
    required this.personagemAtual,
    this.jogo = jogoRivalsOfAether2,
    this.sugestoesPlayers = const [],
    this.sugestoesStages = const [],
    this.partidaInicial,
    this.repetirUltima = false,
  });

  @override
  State<RegistrarPartidaRivalsPage> createState() =>
      _RegistrarPartidaRivalsPageState();
}

class _RegistrarPartidaRivalsPageState
    extends State<RegistrarPartidaRivalsPage> {
  Character? personagemAdversario;
  String resultado = 'Vitória';
  String nickAdversario = '';
  String stage = '';
  int stocks = 1;
  int porcentagem = 0;
  String comoVenceu = opcoesComoVenceuRivalsOfAether2[0];
  String comoPerdeu = opcoesComoPerdeuRivalsOfAether2[0];
  String observacoes = '';
  DateTime dataPartida = DateTime.now();
  int pdlCalculado = 0;

  late TextEditingController porcentagemController;
  late TextEditingController observacoesController;

  bool get editando {
    return widget.partidaInicial != null && !widget.repetirUltima;
  }

  bool get venceu {
    return resultadoEhVitoria(resultado);
  }

  String get labelStocks {
    return venceu ? 'Suas stocks restantes' : 'Stocks restantes do adversário';
  }

  String get labelDano {
    return venceu ? 'Seu dano final' : 'Dano final do adversário';
  }

  String get analiseSelecionada {
    return venceu ? comoVenceu : comoPerdeu;
  }

  @override
  void initState() {
    super.initState();

    final PartidaRegistrada? partida = widget.partidaInicial;
    if (partida != null) {
      personagemAdversario = encontrarPersonagem(partida.personagemAdversario);
      resultado = partida.resultado.trim().isEmpty
          ? resultado
          : partida.resultado;
      nickAdversario = partida.nickAdversario == 'Sem nick'
          ? ''
          : partida.nickAdversario;
      stage = partida.stage;
      stocks = partida.stocks.clamp(0, 3).toInt();
      porcentagem = partida.porcentagem < 0 ? 0 : partida.porcentagem;

      final String vitoriaSalva = partida.condicaoVitoria.trim().isNotEmpty
          ? partida.condicaoVitoria
          : partida.formaDeKill;
      if (opcoesComoVenceuRivalsOfAether2.contains(vitoriaSalva)) {
        comoVenceu = vitoriaSalva;
      }

      final String derrotaSalva = partida.motivoDerrota.trim().isNotEmpty
          ? partida.motivoDerrota
          : partida.formaDeMorte;
      if (opcoesComoPerdeuRivalsOfAether2.contains(derrotaSalva)) {
        comoPerdeu = derrotaSalva;
      }

      if (!widget.repetirUltima) {
        observacoes = partida.observacoes;
        dataPartida = partida.data;
      }
    }

    pdlCalculado = gerarPdl();
    porcentagemController = TextEditingController(
      text: porcentagem == 0 ? '' : porcentagem.toString(),
    );
    observacoesController = TextEditingController(text: observacoes);
  }

  @override
  void dispose() {
    porcentagemController.dispose();
    observacoesController.dispose();
    super.dispose();
  }

  Character? encontrarPersonagem(String nome) {
    if (nome.trim().isEmpty) return null;

    final String nomeNormalizado = normalizarNomePersonagem(nome);
    for (final personagem in rosterDoJogo(widget.jogo)) {
      if (personagem.name == nomeNormalizado) {
        return personagem;
      }
    }

    return null;
  }

  Future<void> escolherAdversario() async {
    final Character? adversarioEscolhido = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelecionarPersonagemPage(
          titulo: 'Personagem adversário',
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
    return calcularPdlRivals(
      resultado: resultado,
      stocks: stocks,
      porcentagem: porcentagem,
      comoVenceu: comoVenceu,
      comoPerdeu: comoPerdeu,
    );
  }

  void recalcularPdl() {
    setState(() {
      pdlCalculado = gerarPdl();
    });
  }

  void mostrarAviso(String titulo, String mensagem) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(titulo),
          content: Text(mensagem),
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

  void salvarPartida() {
    if (personagemAdversario == null) {
      mostrarAviso(
        'Personagem adversário não escolhido',
        'Escolha o personagem adversário antes de salvar a partida.',
      );
      return;
    }

    final int pdlFinal = gerarPdl();
    final String nickFinal = nickAdversario.trim().isEmpty
        ? 'Desconhecido'
        : nickAdversario.trim();
    final String stageFinal = stage.trim();
    final String observacoesFinais = observacoesController.text.trim();

    setState(() {
      pdlCalculado = pdlFinal;
    });

    final PartidaRegistrada partida = PartidaRegistrada(
      jogo: widget.jogo,
      personagemJogador: widget.personagemAtual.name,
      nickAdversario: nickFinal,
      personagemAdversario: personagemAdversario!.name,
      stage: stageFinal,
      resultado: resultado,
      stocks: stocks,
      porcentagem: porcentagem,
      formaDeKill: venceu ? comoVenceu : 'Não aplicável',
      formaDeMorte: venceu ? 'Não aplicável' : comoPerdeu,
      observacoes: observacoesFinais,
      pdlGerado: pdlFinal,
      data: dataPartida,
      condicaoVitoria: venceu ? comoVenceu : '',
      motivoDerrota: venceu ? '' : comoPerdeu,
    );

    showDialog(
      context: context,
      builder: (context) {
        final String sinal = partida.pdlGerado >= 0 ? '+' : '';
        final String textoStage = partida.stage.trim().isEmpty
            ? 'Não informado'
            : partida.stage;
        final String textoObservacoes = partida.observacoes.isEmpty
            ? 'Sem observações'
            : partida.observacoes;
        final String analiseLabel = venceu ? 'Como venceu' : 'Como perdeu';

        return AlertDialog(
          title: Text(editando ? 'Partida atualizada' : 'Partida registrada'),
          content: Text(
            'Meu personagem: ${partida.personagemJogador}\n'
            'Personagem adversário: ${partida.personagemAdversario}\n'
            'Jogador adversário: ${partida.nickAdversario}\n'
            'Stage: $textoStage\n'
            'Resultado: ${partida.resultado}\n'
            '$labelStocks: ${partida.stocks}\n'
            '$labelDano: ${partida.porcentagem}%\n'
            '$analiseLabel: ${partida.analiseResultado}\n'
            'Observações: $textoObservacoes\n'
            'PDL gerado: $sinal${partida.pdlGerado}',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, partida);
              },
              child: Text(editando ? 'Concluir edição' : 'Salvar e voltar'),
            ),
          ],
        );
      },
    );
  }

  Widget construirAutocompletePlayer() {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: nickAdversario),
      optionsBuilder: (textEditingValue) {
        final String busca = textEditingValue.text.trim().toLowerCase();
        final List<String> sugestoes = [
          'Desconhecido',
          ...widget.sugestoesPlayers,
        ].where((nick) => nick.trim().isNotEmpty).toSet().toList();

        if (busca.isEmpty) {
          return sugestoes.take(8);
        }

        return sugestoes.where((nick) => nick.toLowerCase().contains(busca));
      },
      onSelected: (valor) {
        setState(() {
          nickAdversario = valor;
        });
      },
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) {
            return TextField(
              controller: textEditingController,
              focusNode: focusNode,
              decoration: const InputDecoration(
                labelText: 'Jogador adversário',
                border: OutlineInputBorder(),
                hintText: 'Digite ou escolha um player já enfrentado',
                prefixIcon: Icon(Icons.person_search_outlined),
              ),
              onChanged: (valor) {
                nickAdversario = valor;
              },
            );
          },
    );
  }

  Widget construirAutocompleteStage() {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: stage),
      optionsBuilder: (textEditingValue) {
        final String busca = textEditingValue.text.trim().toLowerCase();
        final List<String> sugestoes = widget.sugestoesStages
            .where((item) => item.trim().isNotEmpty)
            .toSet()
            .toList();

        if (busca.isEmpty) {
          return sugestoes.take(8);
        }

        return sugestoes.where((item) => item.toLowerCase().contains(busca));
      },
      onSelected: (valor) {
        setState(() {
          stage = valor;
        });
      },
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) {
            return TextField(
              controller: textEditingController,
              focusNode: focusNode,
              decoration: const InputDecoration(
                labelText: 'Stage opcional',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.map_outlined),
              ),
              onChanged: (valor) {
                stage = valor;
              },
            );
          },
    );
  }

  Widget construirSeletorStocks() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [0, 1, 2, 3].map((valor) {
        return ChoiceChip(
          label: Text('$valor'),
          selected: stocks == valor,
          onSelected: (_) {
            setState(() {
              stocks = valor;
              pdlCalculado = gerarPdl();
            });
          },
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String nomeAdversario =
        personagemAdversario?.name ?? 'Nenhum personagem definido';
    final String sinalPdl = pdlCalculado >= 0 ? '+' : '';
    final String analiseLabel = venceu ? 'Como venceu' : 'Como perdeu';

    return Scaffold(
      appBar: AppBar(
        title: CompactAppBarTitle(
          editando ? 'Editar partida' : 'Registrar partida',
        ),
        centerTitle: true,
        actions: const [HomeNavigationButton()],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.personagemAtual.name} vs $nomeAdversario',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rivals of Aether II • Platform Fighter',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CharacterAvatar(
                            personagem: widget.personagemAtual.name,
                            jogo: widget.jogo,
                            size: 56,
                            initialOverride: widget.personagemAtual.initial,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Meu personagem'),
                                Text(
                                  widget.personagemAtual.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Personagem adversário',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final Widget avatar = personagemAdversario == null
                              ? const CircleAvatar(
                                  radius: 28,
                                  child: Icon(Icons.person_search_outlined),
                                )
                              : CharacterAvatar(
                                  personagem: personagemAdversario!.name,
                                  jogo: widget.jogo,
                                  size: 56,
                                  initialOverride:
                                      personagemAdversario!.initial,
                                );
                          final Widget texto = Text(
                            nomeAdversario,
                            style: const TextStyle(fontSize: 18),
                          );
                          final Widget botao = OutlinedButton(
                            onPressed: escolherAdversario,
                            child: const Text('Selecionar'),
                          );

                          if (constraints.maxWidth < 420) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    avatar,
                                    const SizedBox(width: 16),
                                    Expanded(child: texto),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SizedBox(width: double.infinity, child: botao),
                              ],
                            );
                          }

                          return Row(
                            children: [
                              avatar,
                              const SizedBox(width: 16),
                              Expanded(child: texto),
                              botao,
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Jogador adversário',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  construirAutocompletePlayer(),
                  const SizedBox(height: 24),
                  DatePickerField(
                    label: 'Data da partida',
                    data: dataPartida,
                    onChanged: (valor) {
                      setState(() {
                        dataPartida = valor;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  construirAutocompleteStage(),
                  const SizedBox(height: 24),
                  const Text(
                    'Resultado',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'Vitória', label: Text('Vitória')),
                      ButtonSegment(value: 'Derrota', label: Text('Derrota')),
                    ],
                    selected: {resultado},
                    onSelectionChanged: (valor) {
                      setState(() {
                        resultado = valor.first;
                        pdlCalculado = gerarPdl();
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    labelStocks,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  construirSeletorStocks(),
                  const SizedBox(height: 24),
                  Text(
                    labelDano,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: porcentagemController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: labelDano,
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
                  Text(
                    analiseLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SearchableOptionField(
                    label: venceu ? 'Como venceu' : 'Como perdeu',
                    value: analiseSelecionada,
                    options: venceu
                        ? opcoesComoVenceuRivalsOfAether2
                        : opcoesComoPerdeuRivalsOfAether2,
                    icon: venceu
                        ? Icons.trending_up_outlined
                        : Icons.warning_amber_outlined,
                    onChanged: (valor) {
                      setState(() {
                        if (venceu) {
                          comoVenceu = valor;
                        } else {
                          comoPerdeu = valor;
                        }
                        pdlCalculado = gerarPdl();
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                  Card(
                    child: ListTile(
                      leading: Icon(
                        venceu ? Icons.arrow_upward : Icons.arrow_downward,
                      ),
                      title: const Text('Resumo da partida'),
                      subtitle: Text(
                        '$resultado • $labelStocks: $stocks • $analiseSelecionada',
                      ),
                      trailing: Text(
                        '$sinalPdl$pdlCalculado PDL',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
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
                      labelText: 'Observações',
                      border: OutlineInputBorder(),
                      hintText:
                          'Ex: recovery previsível, bom edgeguard, parry punido...',
                    ),
                    onChanged: (valor) {
                      observacoes = valor;
                    },
                  ),
                  const SizedBox(height: 28),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final Widget calcular = OutlinedButton(
                        onPressed: recalcularPdl,
                        child: const Text('Calcular PDL'),
                      );
                      final Widget salvar = ElevatedButton(
                        onPressed: salvarPartida,
                        child: Text(
                          editando ? 'Salvar edição' : 'Salvar partida',
                        ),
                      );

                      if (constraints.maxWidth < 520) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            calcular,
                            const SizedBox(height: 12),
                            salvar,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: calcular),
                          const SizedBox(width: 16),
                          Expanded(child: salvar),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RegistrarPartidaTekken8Page extends StatefulWidget {
  final Character personagemAtual;
  final String jogo;
  final List<String> sugestoesPlayers;
  final List<String> sugestoesStages;
  final PartidaRegistrada? partidaInicial;
  final bool repetirUltima;

  const RegistrarPartidaTekken8Page({
    super.key,
    required this.personagemAtual,
    this.jogo = jogoTekken8,
    this.sugestoesPlayers = const [],
    this.sugestoesStages = const [],
    this.partidaInicial,
    this.repetirUltima = false,
  });

  @override
  State<RegistrarPartidaTekken8Page> createState() =>
      _RegistrarPartidaTekken8PageState();
}

class _RegistrarPartidaTekken8PageState
    extends State<RegistrarPartidaTekken8Page> {
  Character? personagemAdversario;
  String resultado = 'Vitória';
  String nickAdversario = '';
  String stage = '';
  String placar = placaresVitoriaTekken8[0];
  String comoVenceu = opcoesComoVenceuTekken8[0];
  String comoPerdeu = opcoesComoPerdeuTekken8[0];
  String situacaoPrincipal = situacoesPrincipaisTekken8[0];
  String observacoes = '';
  DateTime dataPartida = DateTime.now();
  int pdlCalculado = 0;

  late TextEditingController observacoesController;

  bool get editando {
    return widget.partidaInicial != null && !widget.repetirUltima;
  }

  bool get venceu {
    return resultadoEhVitoria(resultado);
  }

  List<String> get placaresDisponiveis {
    return venceu ? placaresVitoriaTekken8 : placaresDerrotaTekken8;
  }

  String get analiseSelecionada {
    return venceu ? comoVenceu : comoPerdeu;
  }

  @override
  void initState() {
    super.initState();

    final PartidaRegistrada? partida = widget.partidaInicial;
    if (partida != null) {
      personagemAdversario = encontrarPersonagem(partida.personagemAdversario);
      resultado = partida.resultado.trim().isEmpty
          ? resultado
          : partida.resultado;
      nickAdversario = partida.nickAdversario == 'Sem nick'
          ? ''
          : partida.nickAdversario;
      stage = partida.stage;

      final String placarSalvo = partida.placarRounds.trim().isNotEmpty
          ? partida.placarRounds
          : partida.placarStreetFighter;
      if (placaresTekken8.contains(placarSalvo)) {
        placar = placarSalvo;
      }

      if (opcoesComoVenceuTekken8.contains(partida.condicaoVitoria)) {
        comoVenceu = partida.condicaoVitoria;
      }

      if (opcoesComoPerdeuTekken8.contains(partida.motivoDerrota)) {
        comoPerdeu = partida.motivoDerrota;
      }

      if (situacoesPrincipaisTekken8.contains(
        partida.personagemInimigoProblema,
      )) {
        situacaoPrincipal = partida.personagemInimigoProblema;
      }

      if (!widget.repetirUltima) {
        observacoes = partida.observacoes;
        dataPartida = partida.data;
      } else {
        resultado = 'Vitória';
        placar = placaresVitoriaTekken8[0];
        comoVenceu = opcoesComoVenceuTekken8[0];
        comoPerdeu = opcoesComoPerdeuTekken8[0];
        observacoes = '';
        dataPartida = DateTime.now();
      }
    }

    ajustarPlacarAoResultado();
    pdlCalculado = gerarPdl();
    observacoesController = TextEditingController(text: observacoes);
  }

  @override
  void dispose() {
    observacoesController.dispose();
    super.dispose();
  }

  Character? encontrarPersonagem(String nome) {
    if (nome.trim().isEmpty) return null;

    final String nomeNormalizado = normalizarNomePersonagem(nome);
    for (final personagem in rosterDoJogo(widget.jogo)) {
      if (personagem.name == nomeNormalizado) {
        return personagem;
      }
    }

    return null;
  }

  void ajustarPlacarAoResultado() {
    if (!placaresDisponiveis.contains(placar)) {
      placar = placaresDisponiveis.first;
    }
  }

  void atualizarResultado(String valor) {
    setState(() {
      resultado = valor;
      ajustarPlacarAoResultado();
      pdlCalculado = gerarPdl();
    });
  }

  void atualizarPlacar(String valor) {
    setState(() {
      placar = valor;
      pdlCalculado = gerarPdl();
    });
  }

  Future<void> escolherAdversario() async {
    final Character? adversarioEscolhido = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelecionarPersonagemPage(
          titulo: 'Personagem adversario',
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
    return calcularPdlTekken8(
      resultado: resultado,
      placar: placar,
      condicaoVitoria: comoVenceu,
      motivoDerrota: comoPerdeu,
      situacaoPrincipal: situacaoPrincipal,
    );
  }

  void recalcularPdl() {
    setState(() {
      pdlCalculado = gerarPdl();
    });
  }

  void mostrarAviso(String titulo, String mensagem) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(titulo),
          content: Text(mensagem),
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

  int roundsJogador() {
    return int.tryParse(placar.split('-').first) ?? 0;
  }

  int roundsAdversario() {
    final List<String> partes = placar.split('-');
    if (partes.length < 2) return 0;
    return int.tryParse(partes.last) ?? 0;
  }

  void salvarPartida() {
    if (personagemAdversario == null) {
      mostrarAviso(
        'Personagem adversario nao escolhido',
        'Escolha o personagem adversario antes de salvar a partida.',
      );
      return;
    }

    final int pdlFinal = gerarPdl();
    final String nickFinal = nickAdversario.trim().isEmpty
        ? 'Desconhecido'
        : nickAdversario.trim();
    final String stageFinal = stage.trim();

    setState(() {
      pdlCalculado = pdlFinal;
    });

    final PartidaRegistrada partida = PartidaRegistrada(
      jogo: widget.jogo,
      personagemJogador: widget.personagemAtual.name,
      nickAdversario: nickFinal,
      personagemAdversario: personagemAdversario!.name,
      stage: stageFinal,
      resultado: resultado,
      stocks: roundsJogador(),
      porcentagem: roundsAdversario(),
      formaDeKill: venceu ? comoVenceu : 'Não aplicável',
      formaDeMorte: venceu ? 'Não aplicável' : comoPerdeu,
      observacoes: observacoesController.text.trim(),
      pdlGerado: pdlFinal,
      data: dataPartida,
      personagemInimigoProblema: situacaoPrincipal,
      condicaoVitoria: venceu ? comoVenceu : '',
      motivoDerrota: venceu ? '' : comoPerdeu,
      placarRounds: placar,
    );

    showDialog(
      context: context,
      builder: (context) {
        final String sinal = partida.pdlGerado >= 0 ? '+' : '';
        final String textoStage = partida.stage.trim().isEmpty
            ? 'Nao informado'
            : partida.stage;
        final String textoObservacoes = partida.observacoes.isEmpty
            ? 'Sem observacoes'
            : partida.observacoes;
        final String analiseLabel = venceu ? 'Como venceu' : 'Como perdeu';

        return AlertDialog(
          title: Text(editando ? 'Partida atualizada' : 'Partida registrada'),
          content: Text(
            'Meu personagem: ${partida.personagemJogador}\n'
            'Personagem adversario: ${partida.personagemAdversario}\n'
            'Jogador adversario: ${partida.nickAdversario}\n'
            'Stage: $textoStage\n'
            'Resultado: ${partida.resultado} ${partida.placarStreetFighter}\n'
            '$analiseLabel: ${partida.analiseResultado}\n'
            'Situacao principal: ${partida.personagemInimigoProblema}\n'
            'Observacoes: $textoObservacoes\n'
            'PDL gerado: $sinal${partida.pdlGerado}',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, partida);
              },
              child: Text(editando ? 'Concluir edicao' : 'Salvar e voltar'),
            ),
          ],
        );
      },
    );
  }

  Widget construirAutocompletePlayer() {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: nickAdversario),
      optionsBuilder: (textEditingValue) {
        final String busca = textEditingValue.text.trim().toLowerCase();
        final List<String> sugestoes = [
          'Desconhecido',
          ...widget.sugestoesPlayers,
        ].where((nick) => nick.trim().isNotEmpty).toSet().toList();

        if (busca.isEmpty) {
          return sugestoes.take(8);
        }

        return sugestoes.where((nick) => nick.toLowerCase().contains(busca));
      },
      onSelected: (valor) {
        setState(() {
          nickAdversario = valor;
        });
      },
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) {
            return TextField(
              controller: textEditingController,
              focusNode: focusNode,
              decoration: const InputDecoration(
                labelText: 'Jogador adversario',
                border: OutlineInputBorder(),
                hintText: 'Digite ou escolha um player ja enfrentado',
                prefixIcon: Icon(Icons.person_search_outlined),
              ),
              onChanged: (valor) {
                nickAdversario = valor;
              },
            );
          },
    );
  }

  Widget construirStageField() {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: stage),
      optionsBuilder: (textEditingValue) {
        final String busca = textEditingValue.text.trim().toLowerCase();
        final List<String> sugestoes = widget.sugestoesStages
            .where((stage) => stage.trim().isNotEmpty)
            .toSet()
            .toList();

        if (busca.isEmpty) return sugestoes.take(8);
        return sugestoes.where((stage) => stage.toLowerCase().contains(busca));
      },
      onSelected: (valor) {
        setState(() {
          stage = valor;
        });
      },
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) {
            return TextField(
              controller: textEditingController,
              focusNode: focusNode,
              decoration: const InputDecoration(
                labelText: 'Stage opcional',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.map_outlined),
              ),
              onChanged: (valor) {
                stage = valor;
              },
            );
          },
    );
  }

  Widget construirChips({
    required String label,
    required List<String> opcoes,
    required String valor,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: opcoes.map((opcao) {
            return ChoiceChip(
              label: Text(opcao),
              selected: valor == opcao,
              onSelected: (_) {
                onChanged(opcao);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final String nomeAdversario =
        personagemAdversario?.name ?? 'Nenhum personagem definido';
    final String sinalPdl = pdlCalculado >= 0 ? '+' : '';
    final String analiseLabel = venceu ? 'Como venceu' : 'Como perdeu';

    return Scaffold(
      appBar: AppBar(
        title: CompactAppBarTitle(
          editando ? 'Editar partida Tekken 8' : 'Registrar Tekken 8',
        ),
        centerTitle: true,
        actions: const [HomeNavigationButton()],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.personagemAtual.name} vs $nomeAdversario',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tekken 8 - 3D Fighter',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CharacterAvatar(
                            personagem: widget.personagemAtual.name,
                            jogo: widget.jogo,
                            size: 56,
                            initialOverride: widget.personagemAtual.initial,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Meu personagem'),
                                Text(
                                  widget.personagemAtual.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Personagem adversario',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final Widget avatar = personagemAdversario == null
                              ? const CircleAvatar(
                                  radius: 28,
                                  child: Icon(Icons.person_search_outlined),
                                )
                              : CharacterAvatar(
                                  personagem: personagemAdversario!.name,
                                  jogo: widget.jogo,
                                  size: 56,
                                  initialOverride:
                                      personagemAdversario!.initial,
                                );
                          final Widget texto = Text(
                            nomeAdversario,
                            style: const TextStyle(fontSize: 18),
                          );
                          final Widget botao = OutlinedButton(
                            onPressed: escolherAdversario,
                            child: const Text('Selecionar'),
                          );

                          if (constraints.maxWidth < 420) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    avatar,
                                    const SizedBox(width: 16),
                                    Expanded(child: texto),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SizedBox(width: double.infinity, child: botao),
                              ],
                            );
                          }

                          return Row(
                            children: [
                              avatar,
                              const SizedBox(width: 16),
                              Expanded(child: texto),
                              botao,
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  construirAutocompletePlayer(),
                  const SizedBox(height: 16),
                  construirStageField(),
                  const SizedBox(height: 16),
                  DatePickerField(
                    label: 'Data da partida',
                    data: dataPartida,
                    onChanged: (valor) {
                      setState(() {
                        dataPartida = valor;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  construirChips(
                    label: 'Resultado',
                    opcoes: const ['Vitória', 'Derrota'],
                    valor: resultado,
                    onChanged: atualizarResultado,
                  ),
                  const SizedBox(height: 24),
                  construirChips(
                    label: 'Placar de rounds',
                    opcoes: placaresDisponiveis,
                    valor: placar,
                    onChanged: atualizarPlacar,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    analiseLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SearchableOptionField(
                    label: analiseLabel,
                    value: analiseSelecionada,
                    options: venceu
                        ? opcoesComoVenceuTekken8
                        : opcoesComoPerdeuTekken8,
                    icon: venceu
                        ? Icons.trending_up_outlined
                        : Icons.warning_amber_outlined,
                    onChanged: (valor) {
                      setState(() {
                        if (venceu) {
                          comoVenceu = valor;
                        } else {
                          comoPerdeu = valor;
                        }
                        pdlCalculado = gerarPdl();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  SearchableOptionField(
                    label: 'Situacao principal',
                    value: situacaoPrincipal,
                    options: situacoesPrincipaisTekken8,
                    icon: Icons.sports_mma,
                    onChanged: (valor) {
                      setState(() {
                        situacaoPrincipal = valor;
                        pdlCalculado = gerarPdl();
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                  Card(
                    child: ListTile(
                      leading: Icon(
                        venceu ? Icons.arrow_upward : Icons.arrow_downward,
                      ),
                      title: const Text('Resumo'),
                      subtitle: Text(
                        '$resultado $placar - $analiseSelecionada',
                      ),
                      trailing: Text(
                        '$sinalPdl$pdlCalculado PDL',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Observacoes',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: observacoesController,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'Observacoes',
                      border: OutlineInputBorder(),
                      hintText:
                          'Ex: sofri na parede, bom whiff punish, Heat bem usado...',
                    ),
                    onChanged: (valor) {
                      observacoes = valor;
                    },
                  ),
                  const SizedBox(height: 28),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final Widget calcular = OutlinedButton(
                        onPressed: recalcularPdl,
                        child: const Text('Calcular PDL'),
                      );
                      final Widget salvar = ElevatedButton(
                        onPressed: salvarPartida,
                        child: Text(
                          editando ? 'Salvar edicao' : 'Salvar partida',
                        ),
                      );

                      if (constraints.maxWidth < 520) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            calcular,
                            const SizedBox(height: 12),
                            salvar,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: calcular),
                          const SizedBox(width: 16),
                          Expanded(child: salvar),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RegistrarPartidaFatalFuryPage extends StatefulWidget {
  final Character personagemAtual;
  final String jogo;
  final List<String> sugestoesPlayers;
  final List<String> sugestoesStages;
  final PartidaRegistrada? partidaInicial;
  final bool repetirUltima;

  const RegistrarPartidaFatalFuryPage({
    super.key,
    required this.personagemAtual,
    this.jogo = jogoFatalFury,
    this.sugestoesPlayers = const [],
    this.sugestoesStages = const [],
    this.partidaInicial,
    this.repetirUltima = false,
  });

  @override
  State<RegistrarPartidaFatalFuryPage> createState() =>
      _RegistrarPartidaFatalFuryPageState();
}

class _RegistrarPartidaFatalFuryPageState
    extends State<RegistrarPartidaFatalFuryPage> {
  Character? personagemAdversario;
  String resultado = 'Vitória';
  String nickAdversario = '';
  String stage = '';
  String placar = placaresVitoriaFatalFury[0];
  String comoVenceu = opcoesComoVenceuFatalFury[0];
  String comoPerdeu = opcoesComoPerdeuFatalFury[0];
  String situacaoPrincipal = situacoesPrincipaisFatalFury[0];
  String observacoes = '';
  DateTime dataPartida = DateTime.now();
  int pdlCalculado = 0;

  late TextEditingController observacoesController;

  bool get editando {
    return widget.partidaInicial != null && !widget.repetirUltima;
  }

  bool get venceu {
    return resultadoEhVitoria(resultado);
  }

  List<String> get placaresDisponiveis {
    return venceu ? placaresVitoriaFatalFury : placaresDerrotaFatalFury;
  }

  String get analiseSelecionada {
    return venceu ? comoVenceu : comoPerdeu;
  }

  @override
  void initState() {
    super.initState();

    final PartidaRegistrada? partida = widget.partidaInicial;
    if (partida != null) {
      personagemAdversario = encontrarPersonagem(partida.personagemAdversario);
      resultado = partida.resultado.trim().isEmpty
          ? resultado
          : partida.resultado;
      nickAdversario = partida.nickAdversario == 'Sem nick'
          ? ''
          : partida.nickAdversario;
      stage = partida.stage;

      final String placarSalvo = partida.placarRounds.trim().isNotEmpty
          ? partida.placarRounds
          : partida.placarStreetFighter;
      if (placaresFatalFury.contains(placarSalvo)) {
        placar = placarSalvo;
      }

      if (opcoesComoVenceuFatalFury.contains(partida.condicaoVitoria)) {
        comoVenceu = partida.condicaoVitoria;
      }

      if (opcoesComoPerdeuFatalFury.contains(partida.motivoDerrota)) {
        comoPerdeu = partida.motivoDerrota;
      }

      if (situacoesPrincipaisFatalFury.contains(
        partida.personagemInimigoProblema,
      )) {
        situacaoPrincipal = partida.personagemInimigoProblema;
      }

      if (!widget.repetirUltima) {
        observacoes = partida.observacoes;
        dataPartida = partida.data;
      } else {
        resultado = 'Vitória';
        placar = placaresVitoriaFatalFury[0];
        comoVenceu = opcoesComoVenceuFatalFury[0];
        comoPerdeu = opcoesComoPerdeuFatalFury[0];
        observacoes = '';
        dataPartida = DateTime.now();
      }
    }

    ajustarPlacarAoResultado();
    pdlCalculado = gerarPdl();
    observacoesController = TextEditingController(text: observacoes);
  }

  @override
  void dispose() {
    observacoesController.dispose();
    super.dispose();
  }

  Character? encontrarPersonagem(String nome) {
    if (nome.trim().isEmpty) return null;

    final String nomeNormalizado = normalizarNomePersonagem(nome);
    for (final personagem in rosterDoJogo(widget.jogo)) {
      if (personagem.name == nomeNormalizado) {
        return personagem;
      }
    }

    return null;
  }

  void ajustarPlacarAoResultado() {
    if (!placaresDisponiveis.contains(placar)) {
      placar = placaresDisponiveis.first;
    }
  }

  void atualizarResultado(String valor) {
    setState(() {
      resultado = valor;
      ajustarPlacarAoResultado();
      pdlCalculado = gerarPdl();
    });
  }

  void atualizarPlacar(String valor) {
    setState(() {
      placar = valor;
      pdlCalculado = gerarPdl();
    });
  }

  Future<void> escolherAdversario() async {
    final Character? adversarioEscolhido = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelecionarPersonagemPage(
          titulo: 'Personagem adversario',
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
    return calcularPdlFatalFury(
      resultado: resultado,
      placar: placar,
      condicaoVitoria: comoVenceu,
      motivoDerrota: comoPerdeu,
      situacaoPrincipal: situacaoPrincipal,
    );
  }

  void recalcularPdl() {
    setState(() {
      pdlCalculado = gerarPdl();
    });
  }

  void mostrarAviso(String titulo, String mensagem) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(titulo),
          content: Text(mensagem),
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

  int roundsJogador() {
    return int.tryParse(placar.split('-').first) ?? 0;
  }

  int roundsAdversario() {
    final List<String> partes = placar.split('-');
    if (partes.length < 2) return 0;
    return int.tryParse(partes.last) ?? 0;
  }

  void salvarPartida() {
    if (personagemAdversario == null) {
      mostrarAviso(
        'Personagem adversario nao escolhido',
        'Escolha o personagem adversario antes de salvar a partida.',
      );
      return;
    }

    final int pdlFinal = gerarPdl();
    final String nickFinal = nickAdversario.trim().isEmpty
        ? 'Desconhecido'
        : nickAdversario.trim();
    final String stageFinal = stage.trim();

    setState(() {
      pdlCalculado = pdlFinal;
    });

    final PartidaRegistrada partida = PartidaRegistrada(
      jogo: widget.jogo,
      personagemJogador: widget.personagemAtual.name,
      nickAdversario: nickFinal,
      personagemAdversario: personagemAdversario!.name,
      stage: stageFinal,
      resultado: resultado,
      stocks: roundsJogador(),
      porcentagem: roundsAdversario(),
      formaDeKill: venceu ? comoVenceu : 'Não aplicável',
      formaDeMorte: venceu ? 'Não aplicável' : comoPerdeu,
      observacoes: observacoesController.text.trim(),
      pdlGerado: pdlFinal,
      data: dataPartida,
      personagemInimigoProblema: situacaoPrincipal,
      condicaoVitoria: venceu ? comoVenceu : '',
      motivoDerrota: venceu ? '' : comoPerdeu,
      placarRounds: placar,
    );

    showDialog(
      context: context,
      builder: (context) {
        final String sinal = partida.pdlGerado >= 0 ? '+' : '';
        final String textoStage = partida.stage.trim().isEmpty
            ? 'Nao informado'
            : partida.stage;
        final String textoObservacoes = partida.observacoes.isEmpty
            ? 'Sem observacoes'
            : partida.observacoes;
        final String analiseLabel = venceu ? 'Como venceu' : 'Como perdeu';

        return AlertDialog(
          title: Text(editando ? 'Partida atualizada' : 'Partida registrada'),
          content: Text(
            'Meu personagem: ${partida.personagemJogador}\n'
            'Personagem adversario: ${partida.personagemAdversario}\n'
            'Jogador adversario: ${partida.nickAdversario}\n'
            'Stage: $textoStage\n'
            'Resultado: ${partida.resultado} ${partida.placarStreetFighter}\n'
            '$analiseLabel: ${partida.analiseResultado}\n'
            'Situacao principal: ${partida.personagemInimigoProblema}\n'
            'Observacoes: $textoObservacoes\n'
            'PDL gerado: $sinal${partida.pdlGerado}',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, partida);
              },
              child: Text(editando ? 'Concluir edicao' : 'Salvar e voltar'),
            ),
          ],
        );
      },
    );
  }

  Widget construirAutocompletePlayer() {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: nickAdversario),
      optionsBuilder: (textEditingValue) {
        final String busca = textEditingValue.text.trim().toLowerCase();
        final List<String> sugestoes = [
          'Desconhecido',
          ...widget.sugestoesPlayers,
        ].where((nick) => nick.trim().isNotEmpty).toSet().toList();

        if (busca.isEmpty) {
          return sugestoes.take(8);
        }

        return sugestoes.where((nick) => nick.toLowerCase().contains(busca));
      },
      onSelected: (valor) {
        setState(() {
          nickAdversario = valor;
        });
      },
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) {
            return TextField(
              controller: textEditingController,
              focusNode: focusNode,
              decoration: const InputDecoration(
                labelText: 'Jogador adversario',
                border: OutlineInputBorder(),
                hintText: 'Digite ou escolha um player ja enfrentado',
                prefixIcon: Icon(Icons.person_search_outlined),
              ),
              onChanged: (valor) {
                nickAdversario = valor;
              },
            );
          },
    );
  }

  Widget construirStageField() {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: stage),
      optionsBuilder: (textEditingValue) {
        final String busca = textEditingValue.text.trim().toLowerCase();
        final List<String> sugestoes = widget.sugestoesStages
            .where((stage) => stage.trim().isNotEmpty)
            .toSet()
            .toList();

        if (busca.isEmpty) return sugestoes.take(8);
        return sugestoes.where((stage) => stage.toLowerCase().contains(busca));
      },
      onSelected: (valor) {
        setState(() {
          stage = valor;
        });
      },
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) {
            return TextField(
              controller: textEditingController,
              focusNode: focusNode,
              decoration: const InputDecoration(
                labelText: 'Stage opcional',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.map_outlined),
              ),
              onChanged: (valor) {
                stage = valor;
              },
            );
          },
    );
  }

  Widget construirChips({
    required String label,
    required List<String> opcoes,
    required String valor,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: opcoes.map((opcao) {
            return ChoiceChip(
              label: Text(opcao),
              selected: valor == opcao,
              onSelected: (_) {
                onChanged(opcao);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final String nomeAdversario =
        personagemAdversario?.name ?? 'Nenhum personagem definido';
    final String sinalPdl = pdlCalculado >= 0 ? '+' : '';
    final String analiseLabel = venceu ? 'Como venceu' : 'Como perdeu';

    return Scaffold(
      appBar: AppBar(
        title: CompactAppBarTitle(
          editando ? 'Editar Fatal Fury' : 'Registrar Fatal Fury',
        ),
        centerTitle: true,
        actions: const [HomeNavigationButton()],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.personagemAtual.name} vs $nomeAdversario',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fatal Fury - 2D Fighter / SNK Fighter',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CharacterAvatar(
                            personagem: widget.personagemAtual.name,
                            jogo: widget.jogo,
                            size: 56,
                            initialOverride: widget.personagemAtual.initial,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Meu personagem'),
                                Text(
                                  widget.personagemAtual.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Personagem adversario',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final Widget avatar = personagemAdversario == null
                              ? const CircleAvatar(
                                  radius: 28,
                                  child: Icon(Icons.person_search_outlined),
                                )
                              : CharacterAvatar(
                                  personagem: personagemAdversario!.name,
                                  jogo: widget.jogo,
                                  size: 56,
                                  initialOverride:
                                      personagemAdversario!.initial,
                                );
                          final Widget texto = Text(
                            nomeAdversario,
                            style: const TextStyle(fontSize: 18),
                          );
                          final Widget botao = OutlinedButton(
                            onPressed: escolherAdversario,
                            child: const Text('Selecionar'),
                          );

                          if (constraints.maxWidth < 420) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    avatar,
                                    const SizedBox(width: 16),
                                    Expanded(child: texto),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SizedBox(width: double.infinity, child: botao),
                              ],
                            );
                          }

                          return Row(
                            children: [
                              avatar,
                              const SizedBox(width: 16),
                              Expanded(child: texto),
                              botao,
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  construirAutocompletePlayer(),
                  const SizedBox(height: 16),
                  construirStageField(),
                  const SizedBox(height: 16),
                  DatePickerField(
                    label: 'Data da partida',
                    data: dataPartida,
                    onChanged: (valor) {
                      setState(() {
                        dataPartida = valor;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  construirChips(
                    label: 'Resultado',
                    opcoes: const ['Vitória', 'Derrota'],
                    valor: resultado,
                    onChanged: atualizarResultado,
                  ),
                  const SizedBox(height: 24),
                  construirChips(
                    label: 'Placar',
                    opcoes: placaresDisponiveis,
                    valor: placar,
                    onChanged: atualizarPlacar,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    analiseLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SearchableOptionField(
                    label: analiseLabel,
                    value: analiseSelecionada,
                    options: venceu
                        ? opcoesComoVenceuFatalFury
                        : opcoesComoPerdeuFatalFury,
                    icon: venceu
                        ? Icons.trending_up_outlined
                        : Icons.warning_amber_outlined,
                    onChanged: (valor) {
                      setState(() {
                        if (venceu) {
                          comoVenceu = valor;
                        } else {
                          comoPerdeu = valor;
                        }
                        pdlCalculado = gerarPdl();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  SearchableOptionField(
                    label: 'Situacao principal',
                    value: situacaoPrincipal,
                    options: situacoesPrincipaisFatalFury,
                    icon: Icons.sports_mma,
                    onChanged: (valor) {
                      setState(() {
                        situacaoPrincipal = valor;
                        pdlCalculado = gerarPdl();
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                  Card(
                    child: ListTile(
                      leading: Icon(
                        venceu ? Icons.arrow_upward : Icons.arrow_downward,
                      ),
                      title: const Text('Resumo'),
                      subtitle: Text(
                        '$resultado $placar - $analiseSelecionada',
                      ),
                      trailing: Text(
                        '$sinalPdl$pdlCalculado PDL',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Observacoes',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: observacoesController,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'Observacoes',
                      border: OutlineInputBorder(),
                      hintText:
                          'Ex: SPG decidiu, sofri REV pressure, bom whiff punish...',
                    ),
                    onChanged: (valor) {
                      observacoes = valor;
                    },
                  ),
                  const SizedBox(height: 28),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final Widget calcular = OutlinedButton(
                        onPressed: recalcularPdl,
                        child: const Text('Calcular PDL'),
                      );
                      final Widget salvar = ElevatedButton(
                        onPressed: salvarPartida,
                        child: Text(
                          editando ? 'Salvar edicao' : 'Salvar partida',
                        ),
                      );

                      if (constraints.maxWidth < 520) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            calcular,
                            const SizedBox(height: 12),
                            salvar,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: calcular),
                          const SizedBox(width: 16),
                          Expanded(child: salvar),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RegistrarPartidaMortalKombat1Page extends StatefulWidget {
  final Character personagemAtual;
  final String jogo;
  final List<String> sugestoesPlayers;
  final List<String> sugestoesStages;
  final PartidaRegistrada? partidaInicial;
  final bool repetirUltima;

  const RegistrarPartidaMortalKombat1Page({
    super.key,
    required this.personagemAtual,
    this.jogo = jogoMortalKombat1,
    this.sugestoesPlayers = const [],
    this.sugestoesStages = const [],
    this.partidaInicial,
    this.repetirUltima = false,
  });

  @override
  State<RegistrarPartidaMortalKombat1Page> createState() =>
      _RegistrarPartidaMortalKombat1PageState();
}

class _RegistrarPartidaMortalKombat1PageState
    extends State<RegistrarPartidaMortalKombat1Page> {
  Character? personagemAdversario;
  String kameoAdversario = kameosMortalKombat1.first;
  String resultado = 'Vitória';
  String nickAdversario = '';
  String stage = '';
  String placar = placaresVitoriaMortalKombat1[0];
  String condicaoVitoria = opcoesComoVenceuMortalKombat1[0];
  String motivoDerrota = opcoesComoPerdeuMortalKombat1[0];
  String observacoes = '';
  DateTime dataPartida = DateTime.now();
  int pdlCalculado = 0;

  late TextEditingController observacoesController;

  bool get editando {
    return widget.partidaInicial != null && !widget.repetirUltima;
  }

  bool get venceu {
    return resultadoEhVitoria(resultado);
  }

  List<String> get placaresDisponiveis {
    return venceu ? placaresVitoriaMortalKombat1 : placaresDerrotaMortalKombat1;
  }

  @override
  void initState() {
    super.initState();

    final PartidaRegistrada? partida = widget.partidaInicial;
    if (partida != null) {
      personagemAdversario = encontrarPersonagem(partida.personagemAdversario);
      resultado = partida.resultado.isEmpty ? 'Vitória' : partida.resultado;
      nickAdversario = partida.nickAdversario == 'Sem nick'
          ? ''
          : partida.nickAdversario;
      stage = partida.stage == 'MK1' ? '' : partida.stage;
      if (placaresMortalKombat1.contains(partida.placarStreetFighter)) {
        placar = partida.placarStreetFighter;
      }
      if (kameosMortalKombat1.contains(partida.personagemInimigoProblema)) {
        kameoAdversario = partida.personagemInimigoProblema;
      }
      if (opcoesComoVenceuMortalKombat1.contains(partida.condicaoVitoria)) {
        condicaoVitoria = partida.condicaoVitoria;
      }
      if (opcoesComoPerdeuMortalKombat1.contains(partida.motivoDerrota)) {
        motivoDerrota = partida.motivoDerrota;
      }
      observacoes = partida.observacoes;
      dataPartida = partida.data;

      if (widget.repetirUltima) {
        resultado = 'Vitória';
        placar = placaresVitoriaMortalKombat1[0];
        condicaoVitoria = opcoesComoVenceuMortalKombat1[0];
        motivoDerrota = opcoesComoPerdeuMortalKombat1[0];
        observacoes = '';
        dataPartida = DateTime.now();
      }
    }

    ajustarPlacarAoResultado();
    pdlCalculado = gerarPdl();
    observacoesController = TextEditingController(text: observacoes);
  }

  @override
  void dispose() {
    observacoesController.dispose();
    super.dispose();
  }

  Character? encontrarPersonagem(String nome) {
    if (nome.trim().isEmpty) return null;

    final String nomeNormalizado = normalizarNomePersonagem(nome);
    for (final personagem in rosterDoJogo(widget.jogo)) {
      if (personagem.name == nomeNormalizado) {
        return personagem;
      }
    }

    return null;
  }

  void ajustarPlacarAoResultado() {
    if (!placaresDisponiveis.contains(placar)) {
      placar = placaresDisponiveis.first;
    }
  }

  int gerarPdl() {
    return calcularPdlMortalKombat1(
      resultado: resultado,
      placar: placar,
      condicaoVitoria: condicaoVitoria,
      motivoDerrota: motivoDerrota,
    );
  }

  Future<void> escolherAdversario() async {
    final Character? adversarioEscolhido = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelecionarPersonagemPage(
          titulo: 'Personagem adversario',
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

  void mostrarAviso(String titulo, String mensagem) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(titulo),
          content: Text(mensagem),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ok'),
            ),
          ],
        );
      },
    );
  }

  void salvarPartida() {
    if (personagemAdversario == null) {
      mostrarAviso(
        'Personagem adversario nao escolhido',
        'Escolha o personagem adversario antes de salvar.',
      );
      return;
    }

    final int pdlFinal = gerarPdl();
    final String nickFinal = nickAdversario.trim().isEmpty
        ? 'Desconhecido'
        : nickAdversario.trim();
    final String stageFinal = stage.trim().isEmpty ? 'MK1' : stage.trim();

    setState(() {
      pdlCalculado = pdlFinal;
    });

    final PartidaRegistrada partida = PartidaRegistrada(
      jogo: widget.jogo,
      personagemJogador: widget.personagemAtual.name,
      nickAdversario: nickFinal,
      personagemAdversario: personagemAdversario!.name,
      stage: stageFinal,
      resultado: resultado,
      stocks: 0,
      porcentagem: 0,
      formaDeKill: venceu ? condicaoVitoria : 'Não aplicável',
      formaDeMorte: venceu ? 'Não aplicável' : motivoDerrota,
      observacoes: observacoesController.text.trim(),
      pdlGerado: pdlFinal,
      data: dataPartida,
      personagemInimigoProblema: kameoAdversario,
      condicaoVitoria: venceu ? condicaoVitoria : '',
      motivoDerrota: venceu ? '' : motivoDerrota,
      placarRounds: placar,
    );

    showDialog(
      context: context,
      builder: (context) {
        final String sinal = partida.pdlGerado >= 0 ? '+' : '';
        final String textoObservacoes = partida.observacoes.isEmpty
            ? 'Sem observacoes'
            : partida.observacoes;
        final String analiseLabel = venceu ? 'Como venceu' : 'Como perdeu';

        return AlertDialog(
          title: Text(editando ? 'Partida atualizada' : 'Partida registrada'),
          content: Text(
            'Meu personagem: ${partida.personagemJogador}\n'
            'Personagem adversario: ${partida.personagemAdversario}\n'
            'Kameo adversario: ${partida.personagemInimigoProblema}\n'
            'Adversario: ${partida.nickAdversario}\n'
            'Resultado: ${partida.resultado} ${partida.placarStreetFighter}\n'
            '$analiseLabel: ${partida.analiseResultado}\n'
            'Stage: ${partida.stage}\n'
            'Observacoes: $textoObservacoes\n'
            'PDL gerado: $sinal${partida.pdlGerado}',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, partida);
              },
              child: Text(editando ? 'Concluir edicao' : 'Salvar e voltar'),
            ),
          ],
        );
      },
    );
  }

  Widget construirAutocompletePlayer() {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: nickAdversario),
      optionsBuilder: (textEditingValue) {
        final String busca = textEditingValue.text.trim().toLowerCase();
        final List<String> sugestoes = [
          'Desconhecido',
          ...widget.sugestoesPlayers,
        ].where((nick) => nick.trim().isNotEmpty).toSet().toList();

        if (busca.isEmpty) {
          return sugestoes.take(8);
        }

        return sugestoes.where((nick) => nick.toLowerCase().contains(busca));
      },
      onSelected: (valor) {
        setState(() {
          nickAdversario = valor;
        });
      },
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) {
            return TextField(
              controller: textEditingController,
              focusNode: focusNode,
              decoration: const InputDecoration(
                labelText: 'Adversario / player',
                border: OutlineInputBorder(),
                hintText: 'Digite ou escolha um player ja enfrentado',
                prefixIcon: Icon(Icons.person_search_outlined),
              ),
              onChanged: (valor) {
                nickAdversario = valor;
              },
            );
          },
    );
  }

  Widget construirStageField() {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: stage),
      optionsBuilder: (textEditingValue) {
        final String busca = textEditingValue.text.trim().toLowerCase();
        final List<String> sugestoes = widget.sugestoesStages
            .where((stage) => stage.trim().isNotEmpty && stage != 'MK1')
            .toSet()
            .toList();

        if (busca.isEmpty) return sugestoes.take(8);
        return sugestoes.where((stage) => stage.toLowerCase().contains(busca));
      },
      onSelected: (valor) {
        setState(() {
          stage = valor;
        });
      },
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) {
            return TextField(
              controller: textEditingController,
              focusNode: focusNode,
              decoration: const InputDecoration(
                labelText: 'Stage (opcional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.map_outlined),
              ),
              onChanged: (valor) {
                stage = valor;
              },
            );
          },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String nomeAdversario =
        personagemAdversario?.name ?? 'Nenhum personagem definido';
    final String sinalPdl = pdlCalculado >= 0 ? '+' : '';
    final String analiseLabel = venceu ? 'Como venceu' : 'Como perdeu';

    return Scaffold(
      appBar: AppBar(
        title: CompactAppBarTitle(
          editando ? 'Editar partida MK1' : 'Registrar partida MK1',
        ),
        centerTitle: true,
        actions: const [HomeNavigationButton()],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.personagemAtual.name} vs $nomeAdversario',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mortal Kombat 1 - 2D Assist Fighter',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: ListTile(
                      leading: CharacterAvatar(
                        personagem: widget.personagemAtual.name,
                        jogo: widget.jogo,
                        size: 44,
                        initialOverride: widget.personagemAtual.initial,
                      ),
                      title: const Text('Meu personagem'),
                      subtitle: Text(widget.personagemAtual.name),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: ListTile(
                      onTap: escolherAdversario,
                      leading: personagemAdversario == null
                          ? const CircleAvatar(child: Icon(Icons.person_add))
                          : CharacterAvatar(
                              personagem: personagemAdversario!.name,
                              jogo: widget.jogo,
                              size: 44,
                              initialOverride: personagemAdversario!.initial,
                            ),
                      title: const Text('Personagem adversario'),
                      subtitle: Text(nomeAdversario),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SearchableOptionField(
                    label: 'Kameo adversario',
                    value: kameoAdversario,
                    options: kameosMortalKombat1,
                    icon: Icons.group_add_outlined,
                    onChanged: (valor) {
                      setState(() {
                        kameoAdversario = valor;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  construirAutocompletePlayer(),
                  const SizedBox(height: 16),
                  construirStageField(),
                  const SizedBox(height: 16),
                  DatePickerField(
                    label: 'Data da partida',
                    data: dataPartida,
                    onChanged: (valor) {
                      setState(() {
                        dataPartida = valor;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Resultado',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'Vitória', label: Text('Vitória')),
                      ButtonSegment(value: 'Derrota', label: Text('Derrota')),
                    ],
                    selected: {resultado},
                    onSelectionChanged: (valor) {
                      setState(() {
                        resultado = valor.first;
                        ajustarPlacarAoResultado();
                        pdlCalculado = gerarPdl();
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Placar',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: placaresDisponiveis
                        .map(
                          (item) =>
                              ButtonSegment(value: item, label: Text(item)),
                        )
                        .toList(),
                    selected: {placar},
                    onSelectionChanged: (valor) {
                      setState(() {
                        placar = valor.first;
                        pdlCalculado = gerarPdl();
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  SearchableOptionField(
                    label: analiseLabel,
                    value: venceu ? condicaoVitoria : motivoDerrota,
                    options: venceu
                        ? opcoesComoVenceuMortalKombat1
                        : opcoesComoPerdeuMortalKombat1,
                    icon: venceu
                        ? Icons.emoji_events_outlined
                        : Icons.report_problem_outlined,
                    onChanged: (valor) {
                      setState(() {
                        if (venceu) {
                          condicaoVitoria = valor;
                        } else {
                          motivoDerrota = valor;
                        }
                        pdlCalculado = gerarPdl();
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                  Card(
                    child: ListTile(
                      leading: Icon(
                        venceu ? Icons.arrow_upward : Icons.arrow_downward,
                      ),
                      title: const Text('Resumo'),
                      subtitle: Text('$resultado $placar - $analiseLabel'),
                      trailing: Text(
                        '$sinalPdl$pdlCalculado PDL',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Observacoes',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: observacoesController,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'Observacoes',
                      border: OutlineInputBorder(),
                      hintText:
                          'Ex: Kameo pressure, Fatal Blow, mix-up, corner...',
                    ),
                  ),
                  const SizedBox(height: 28),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final Widget calcular = OutlinedButton(
                        onPressed: () {
                          setState(() {
                            pdlCalculado = gerarPdl();
                          });
                        },
                        child: const Text('Calcular PDL'),
                      );
                      final Widget salvar = ElevatedButton(
                        onPressed: salvarPartida,
                        child: Text(
                          editando ? 'Salvar edicao' : 'Salvar partida',
                        ),
                      );

                      if (constraints.maxWidth < 520) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            calcular,
                            const SizedBox(height: 12),
                            salvar,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: calcular),
                          const SizedBox(width: 16),
                          Expanded(child: salvar),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RegistrarPartidaStreetFighterPage extends StatefulWidget {
  final Character personagemAtual;
  final String jogo;
  final List<String> sugestoesPlayers;
  final PartidaRegistrada? partidaInicial;
  final bool repetirUltima;

  const RegistrarPartidaStreetFighterPage({
    super.key,
    required this.personagemAtual,
    this.jogo = jogoStreetFighter6,
    this.sugestoesPlayers = const [],
    this.partidaInicial,
    this.repetirUltima = false,
  });

  @override
  State<RegistrarPartidaStreetFighterPage> createState() =>
      _RegistrarPartidaStreetFighterPageState();
}

class _RegistrarPartidaStreetFighterPageState
    extends State<RegistrarPartidaStreetFighterPage> {
  Character? personagemAdversario;
  String nickAdversario = '';
  String round1Resultado = 'Vitória';
  String round2Resultado = 'Vitória';
  String? round3Resultado;
  String observacoes = '';
  DateTime dataPartida = DateTime.now();
  int pdlCalculado = 0;

  late TextEditingController observacoesController;

  bool get editando {
    return widget.partidaInicial != null && !widget.repetirUltima;
  }

  bool get precisaRound3 {
    return resultadoEhVitoria(round1Resultado) !=
        resultadoEhVitoria(round2Resultado);
  }

  List<String> get roundsPreenchidos {
    return [
      round1Resultado,
      round2Resultado,
      if (precisaRound3 && round3Resultado != null) round3Resultado!,
    ];
  }

  int get roundsVencidos {
    return roundsPreenchidos.where(resultadoEhVitoria).length;
  }

  int get roundsPerdidos {
    return roundsPreenchidos.where(resultadoEhDerrota).length;
  }

  String get placar {
    return '${roundsVencidos}x$roundsPerdidos';
  }

  String get resultadoFinal {
    if (roundsVencidos >= 2) return 'Vitória';
    if (roundsPerdidos >= 2) return 'Derrota';
    return 'Pendente';
  }

  String get resultadoFinalTexto {
    return resultadoFinal == 'Pendente'
        ? 'Pendente'
        : '$resultadoFinal $placar';
  }

  @override
  void initState() {
    super.initState();

    final PartidaRegistrada? partida = widget.partidaInicial;
    if (partida != null) {
      personagemAdversario = encontrarPersonagem(partida.personagemAdversario);
      nickAdversario = partida.nickAdversario == 'Sem nick'
          ? ''
          : partida.nickAdversario;

      if (!widget.repetirUltima) {
        observacoes = partida.observacoes;
        dataPartida = partida.data;

        if (partida.round1Resultado.trim().isNotEmpty &&
            partida.round2Resultado.trim().isNotEmpty) {
          round1Resultado = partida.round1Resultado;
          round2Resultado = partida.round2Resultado;
          round3Resultado = partida.round3Resultado.trim().isEmpty
              ? null
              : partida.round3Resultado;
        } else {
          aplicarRoundsPorPlacar(partida.resultado, partida.stage);
        }
      }
    }

    ajustarRound3();
    pdlCalculado = gerarPdl();
    observacoesController = TextEditingController(text: observacoes);
  }

  @override
  void dispose() {
    observacoesController.dispose();
    super.dispose();
  }

  Character? encontrarPersonagem(String nome) {
    if (nome.trim().isEmpty) return null;

    final String nomeNormalizado = normalizarNomePersonagem(nome);
    for (final personagem in rosterDoJogo(widget.jogo)) {
      if (personagem.name == nomeNormalizado) {
        return personagem;
      }
    }

    return null;
  }

  void aplicarRoundsPorPlacar(String resultado, String placarSalvo) {
    final String texto = '$resultado $placarSalvo';

    if (texto.contains('2x0')) {
      round1Resultado = 'Vitória';
      round2Resultado = 'Vitória';
      round3Resultado = null;
    } else if (texto.contains('2x1')) {
      round1Resultado = 'Vitória';
      round2Resultado = 'Derrota';
      round3Resultado = 'Vitória';
    } else if (texto.contains('0x2')) {
      round1Resultado = 'Derrota';
      round2Resultado = 'Derrota';
      round3Resultado = null;
    } else if (texto.contains('1x2')) {
      round1Resultado = 'Derrota';
      round2Resultado = 'Vitória';
      round3Resultado = 'Derrota';
    }
  }

  void ajustarRound3() {
    if (precisaRound3) {
      round3Resultado ??= 'Vitória';
    } else {
      round3Resultado = null;
    }
  }

  void atualizarRound(int numeroRound, String resultado) {
    setState(() {
      if (numeroRound == 1) {
        round1Resultado = resultado;
      } else if (numeroRound == 2) {
        round2Resultado = resultado;
      } else {
        round3Resultado = resultado;
      }

      ajustarRound3();
      pdlCalculado = gerarPdl();
    });
  }

  Future<void> escolherAdversario() async {
    final Character? adversarioEscolhido = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelecionarPersonagemPage(
          titulo: 'Personagem Adversário',
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
    if (resultadoFinal == 'Pendente') return 0;

    return calcularPdlStreetFighter(
      roundsVencidos: roundsVencidos,
      roundsPerdidos: roundsPerdidos,
      venceuRound1: resultadoEhVitoria(round1Resultado),
      chegouAoRound3: precisaRound3,
      venceuRound3: resultadoEhVitoria(round3Resultado ?? ''),
    );
  }

  void mostrarAviso(String titulo, String mensagem) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(titulo),
          content: Text(mensagem),
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

  void salvarPartida() {
    if (personagemAdversario == null) {
      mostrarAviso(
        'Personagem adversário não escolhido',
        'Escolha o personagem adversário antes de salvar a partida.',
      );
      return;
    }

    if (resultadoFinal == 'Pendente') {
      mostrarAviso(
        'Rounds incompletos',
        'Preencha os rounds até fechar 2 vitórias ou 2 derrotas.',
      );
      return;
    }

    final int pdlFinal = gerarPdl();
    final String nickFinal = nickAdversario.trim().isEmpty
        ? 'Desconhecido'
        : nickAdversario.trim();

    setState(() {
      pdlCalculado = pdlFinal;
    });

    final PartidaRegistrada partida = PartidaRegistrada(
      jogo: jogoStreetFighter6,
      personagemJogador: widget.personagemAtual.name,
      nickAdversario: nickFinal,
      personagemAdversario: personagemAdversario!.name,
      stage: 'Resultado $placar',
      resultado: resultadoFinal,
      stocks: roundsVencidos,
      porcentagem: roundsPerdidos,
      formaDeKill: resultadoEhVitoria(resultadoFinal)
          ? 'Vitória $placar'
          : 'Não aplicável',
      formaDeMorte: resultadoEhDerrota(resultadoFinal)
          ? 'Derrota $placar'
          : 'Não aplicável',
      observacoes: observacoes.trim(),
      pdlGerado: pdlFinal,
      data: dataPartida,
      round1Resultado: round1Resultado,
      round2Resultado: round2Resultado,
      round3Resultado: precisaRound3 ? (round3Resultado ?? '') : '',
      placarRounds: placar,
    );

    showDialog(
      context: context,
      builder: (context) {
        final String sinal = partida.pdlGerado >= 0 ? '+' : '';
        final String textoObservacoes = partida.observacoes.isEmpty
            ? 'Sem observações'
            : partida.observacoes;
        final String resumoRound3 = partida.round3Resultado.trim().isEmpty
            ? ''
            : 'Round 3: ${partida.round3Resultado}\n';

        return AlertDialog(
          title: Text(editando ? 'Partida atualizada' : 'Partida registrada'),
          content: Text(
            'Meu personagem: ${partida.personagemJogador}\n'
            'Personagem adversário: ${partida.personagemAdversario}\n'
            'Jogador adversário: ${partida.nickAdversario}\n'
            'Round 1: ${partida.round1Resultado}\n'
            'Round 2: ${partida.round2Resultado}\n'
            '$resumoRound3'
            'Resultado final: ${partida.resultado} ${partida.placarStreetFighter}\n'
            'Observações: $textoObservacoes\n'
            'PDL gerado: $sinal${partida.pdlGerado}',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, partida);
              },
              child: Text(editando ? 'Concluir edição' : 'Salvar e voltar'),
            ),
          ],
        );
      },
    );
  }

  Widget construirAutocompletePlayer() {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: nickAdversario),
      optionsBuilder: (textEditingValue) {
        final String busca = textEditingValue.text.trim().toLowerCase();
        final List<String> sugestoes = [
          'Desconhecido',
          ...widget.sugestoesPlayers,
        ].where((nick) => nick.trim().isNotEmpty).toSet().toList();

        if (busca.isEmpty) {
          return sugestoes.take(8);
        }

        return sugestoes.where((nick) => nick.toLowerCase().contains(busca));
      },
      onSelected: (valor) {
        setState(() {
          nickAdversario = valor;
        });
      },
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) {
            return TextField(
              controller: textEditingController,
              focusNode: focusNode,
              decoration: const InputDecoration(
                labelText: 'Jogador Adversário',
                border: OutlineInputBorder(),
                hintText: 'Digite ou escolha um player já enfrentado',
                prefixIcon: Icon(Icons.person_search_outlined),
              ),
              onChanged: (valor) {
                nickAdversario = valor;
              },
            );
          },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String nomeAdversario =
        personagemAdversario?.name ?? 'Nenhum personagem definido';
    final String sinalPdl = pdlCalculado >= 0 ? '+' : '';

    return Scaffold(
      appBar: AppBar(
        title: CompactAppBarTitle(
          editando ? 'Editar partida' : 'Registrar Partida',
        ),
        centerTitle: true,
        actions: const [HomeNavigationButton()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.personagemAtual.name} vs $nomeAdversario',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Street Fighter 6 • melhor de 3 rounds',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CharacterAvatar(
                      personagem: widget.personagemAtual.name,
                      jogo: widget.jogo,
                      size: 56,
                      initialOverride: widget.personagemAtual.initial,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Meu Personagem'),
                          Text(
                            widget.personagemAtual.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Personagem Adversário',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    personagemAdversario == null
                        ? const CircleAvatar(
                            radius: 28,
                            child: Icon(Icons.person_search_outlined),
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
                      child: const Text('Selecionar'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Jogador Adversário',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            construirAutocompletePlayer(),
            const SizedBox(height: 24),
            const Text('Rounds', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _StreetRoundSelector(
              label: 'Round 1',
              value: round1Resultado,
              onChanged: (valor) => atualizarRound(1, valor),
            ),
            const SizedBox(height: 12),
            _StreetRoundSelector(
              label: 'Round 2',
              value: round2Resultado,
              onChanged: (valor) => atualizarRound(2, valor),
            ),
            if (precisaRound3) ...[
              const SizedBox(height: 12),
              _StreetRoundSelector(
                label: 'Round 3',
                value: round3Resultado ?? 'Vitória',
                onChanged: (valor) => atualizarRound(3, valor),
              ),
            ],
            const SizedBox(height: 18),
            Card(
              child: ListTile(
                leading: Icon(
                  resultadoEhVitoria(resultadoFinal)
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                ),
                title: const Text('Resultado Final'),
                subtitle: Text(resultadoFinalTexto),
                trailing: Text(
                  '$sinalPdl$pdlCalculado PDL',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 24),
            DatePickerField(
              label: 'Data da partida',
              data: dataPartida,
              onChanged: (valor) {
                setState(() {
                  dataPartida = valor;
                });
              },
            ),
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
                labelText: 'Observações',
                border: OutlineInputBorder(),
                hintText:
                    'Ex: perdi Round 3 por drive impact, comecei bem, adaptei no fim...',
              ),
              onChanged: (valor) {
                observacoes = valor;
              },
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        pdlCalculado = gerarPdl();
                      });
                    },
                    child: const Text('Calcular PDL'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: salvarPartida,
                    child: Text(editando ? 'Salvar edição' : 'Salvar partida'),
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

class _StreetRoundSelector extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  const _StreetRoundSelector({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Vitória', label: Text('Vitória')),
                ButtonSegment(value: 'Derrota', label: Text('Derrota')),
              ],
              selected: {value},
              onSelectionChanged: (valor) {
                onChanged(valor.first);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class RegistrarPartidaGuiltyGearPage extends StatefulWidget {
  final Character personagemAtual;
  final String jogo;
  final List<String> sugestoesPlayers;
  final PartidaRegistrada? partidaInicial;
  final bool repetirUltima;

  const RegistrarPartidaGuiltyGearPage({
    super.key,
    required this.personagemAtual,
    this.jogo = jogoGuiltyGearStrive,
    this.sugestoesPlayers = const [],
    this.partidaInicial,
    this.repetirUltima = false,
  });

  @override
  State<RegistrarPartidaGuiltyGearPage> createState() =>
      _RegistrarPartidaGuiltyGearPageState();
}

class _RegistrarPartidaGuiltyGearPageState
    extends State<RegistrarPartidaGuiltyGearPage> {
  Character? personagemAdversario;
  String resultado = 'Vitória';
  String nickAdversario = '';
  String stage = '';
  String placar = placaresVitoriaGuiltyGearStrive[0];
  String comoVenceu = opcoesComoVenceuGuiltyGearStrive[0];
  String comoPerdeu = opcoesComoPerdeuGuiltyGearStrive[0];
  String observacoes = '';
  DateTime dataPartida = DateTime.now();
  int pdlCalculado = 0;

  late TextEditingController stageController;
  late TextEditingController observacoesController;

  bool get editando {
    return widget.partidaInicial != null && !widget.repetirUltima;
  }

  bool get venceu {
    return resultadoEhVitoria(resultado);
  }

  List<String> get placaresDisponiveis {
    return venceu
        ? placaresVitoriaGuiltyGearStrive
        : placaresDerrotaGuiltyGearStrive;
  }

  String get analiseSelecionada {
    return venceu ? comoVenceu : comoPerdeu;
  }

  @override
  void initState() {
    super.initState();

    final PartidaRegistrada? partida = widget.partidaInicial;
    if (partida != null) {
      personagemAdversario = encontrarPersonagem(partida.personagemAdversario);
      resultado = partida.resultado.trim().isEmpty
          ? resultado
          : partida.resultado;
      nickAdversario = partida.nickAdversario == 'Sem nick'
          ? ''
          : partida.nickAdversario;
      stage = partida.stage;

      final String placarSalvo = partida.placarRounds.trim().isNotEmpty
          ? partida.placarRounds
          : partida.placarStreetFighter;
      if (placaresGuiltyGearStrive.contains(placarSalvo)) {
        placar = placarSalvo;
      }

      if (opcoesComoVenceuGuiltyGearStrive.contains(partida.condicaoVitoria)) {
        comoVenceu = partida.condicaoVitoria;
      }

      if (opcoesComoPerdeuGuiltyGearStrive.contains(partida.motivoDerrota)) {
        comoPerdeu = partida.motivoDerrota;
      }

      if (!widget.repetirUltima) {
        observacoes = partida.observacoes;
        dataPartida = partida.data;
      }
    }

    ajustarPlacarAoResultado();
    pdlCalculado = gerarPdl();
    stageController = TextEditingController(text: stage);
    observacoesController = TextEditingController(text: observacoes);
  }

  @override
  void dispose() {
    stageController.dispose();
    observacoesController.dispose();
    super.dispose();
  }

  Character? encontrarPersonagem(String nome) {
    if (nome.trim().isEmpty) return null;

    final String nomeNormalizado = normalizarNomePersonagem(nome);
    for (final personagem in rosterDoJogo(widget.jogo)) {
      if (personagem.name == nomeNormalizado) {
        return personagem;
      }
    }

    return null;
  }

  void ajustarPlacarAoResultado() {
    if (!placaresDisponiveis.contains(placar)) {
      placar = placaresDisponiveis.first;
    }
  }

  void atualizarResultado(String valor) {
    setState(() {
      resultado = valor;
      ajustarPlacarAoResultado();
      pdlCalculado = gerarPdl();
    });
  }

  void atualizarPlacar(String valor) {
    setState(() {
      placar = valor;
      pdlCalculado = gerarPdl();
    });
  }

  Future<void> escolherAdversario() async {
    final Character? adversarioEscolhido = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelecionarPersonagemPage(
          titulo: 'Personagem adversário',
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
    return calcularPdlGuiltyGear(
      resultado: resultado,
      placar: placar,
      condicaoVitoria: comoVenceu,
      motivoDerrota: comoPerdeu,
    );
  }

  void recalcularPdl() {
    setState(() {
      pdlCalculado = gerarPdl();
    });
  }

  void mostrarAviso(String titulo, String mensagem) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(titulo),
          content: Text(mensagem),
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

  void salvarPartida() {
    if (personagemAdversario == null) {
      mostrarAviso(
        'Personagem adversário não escolhido',
        'Escolha o personagem adversário antes de salvar a partida.',
      );
      return;
    }

    final int pdlFinal = gerarPdl();
    final String nickFinal = nickAdversario.trim().isEmpty
        ? 'Desconhecido'
        : nickAdversario.trim();
    final String stageFinal = stageController.text.trim();

    setState(() {
      pdlCalculado = pdlFinal;
    });

    final PartidaRegistrada partida = PartidaRegistrada(
      jogo: widget.jogo,
      personagemJogador: widget.personagemAtual.name,
      nickAdversario: nickFinal,
      personagemAdversario: personagemAdversario!.name,
      stage: stageFinal,
      resultado: resultado,
      stocks: venceu ? 2 : 0,
      porcentagem: 0,
      formaDeKill: venceu ? comoVenceu : 'Não aplicável',
      formaDeMorte: venceu ? 'Não aplicável' : comoPerdeu,
      observacoes: observacoes.trim(),
      pdlGerado: pdlFinal,
      data: dataPartida,
      condicaoVitoria: venceu ? comoVenceu : '',
      motivoDerrota: venceu ? '' : comoPerdeu,
      placarRounds: placar,
    );

    showDialog(
      context: context,
      builder: (context) {
        final String sinal = partida.pdlGerado >= 0 ? '+' : '';
        final String textoStage = partida.stage.trim().isEmpty
            ? 'Não informado'
            : partida.stage;
        final String textoObservacoes = partida.observacoes.isEmpty
            ? 'Sem observações'
            : partida.observacoes;
        final String analiseLabel = venceu ? 'Como venceu' : 'Como perdeu';

        return AlertDialog(
          title: Text(editando ? 'Partida atualizada' : 'Partida registrada'),
          content: Text(
            'Meu personagem: ${partida.personagemJogador}\n'
            'Personagem adversário: ${partida.personagemAdversario}\n'
            'Jogador adversário: ${partida.nickAdversario}\n'
            'Stage: $textoStage\n'
            'Resultado: ${partida.resultado} ${partida.placarStreetFighter}\n'
            '$analiseLabel: ${partida.analiseResultado}\n'
            'Observações: $textoObservacoes\n'
            'PDL gerado: $sinal${partida.pdlGerado}',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, partida);
              },
              child: Text(editando ? 'Concluir edição' : 'Salvar e voltar'),
            ),
          ],
        );
      },
    );
  }

  Widget construirAutocompletePlayer() {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: nickAdversario),
      optionsBuilder: (textEditingValue) {
        final String busca = textEditingValue.text.trim().toLowerCase();
        final List<String> sugestoes = [
          'Desconhecido',
          ...widget.sugestoesPlayers,
        ].where((nick) => nick.trim().isNotEmpty).toSet().toList();

        if (busca.isEmpty) {
          return sugestoes.take(8);
        }

        return sugestoes.where((nick) => nick.toLowerCase().contains(busca));
      },
      onSelected: (valor) {
        setState(() {
          nickAdversario = valor;
        });
      },
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) {
            return TextField(
              controller: textEditingController,
              focusNode: focusNode,
              decoration: const InputDecoration(
                labelText: 'Jogador adversário',
                border: OutlineInputBorder(),
                hintText: 'Digite ou escolha um player já enfrentado',
                prefixIcon: Icon(Icons.person_search_outlined),
              ),
              onChanged: (valor) {
                nickAdversario = valor;
              },
            );
          },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String nomeAdversario =
        personagemAdversario?.name ?? 'Nenhum personagem definido';
    final String sinalPdl = pdlCalculado >= 0 ? '+' : '';
    final String analiseLabel = venceu ? 'Como venceu' : 'Como perdeu';

    return Scaffold(
      appBar: AppBar(
        title: CompactAppBarTitle(
          editando ? 'Editar partida' : 'Registrar partida',
        ),
        centerTitle: true,
        actions: const [HomeNavigationButton()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.personagemAtual.name} vs $nomeAdversario',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Guilty Gear -Strive- • melhor de 3 rounds',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CharacterAvatar(
                          personagem: widget.personagemAtual.name,
                          jogo: widget.jogo,
                          size: 56,
                          initialOverride: widget.personagemAtual.initial,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Meu personagem'),
                              Text(
                                widget.personagemAtual.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Personagem adversário',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final Widget avatar = personagemAdversario == null
                            ? const CircleAvatar(
                                radius: 28,
                                child: Icon(Icons.person_search_outlined),
                              )
                            : CharacterAvatar(
                                personagem: personagemAdversario!.name,
                                jogo: widget.jogo,
                                size: 56,
                                initialOverride: personagemAdversario!.initial,
                              );
                        final Widget texto = Text(
                          nomeAdversario,
                          style: const TextStyle(fontSize: 18),
                        );
                        final Widget botao = OutlinedButton(
                          onPressed: escolherAdversario,
                          child: const Text('Selecionar'),
                        );

                        if (constraints.maxWidth < 420) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  avatar,
                                  const SizedBox(width: 16),
                                  Expanded(child: texto),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(width: double.infinity, child: botao),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            avatar,
                            const SizedBox(width: 16),
                            Expanded(child: texto),
                            botao,
                          ],
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Jogador adversário',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                construirAutocompletePlayer(),
                const SizedBox(height: 24),
                DatePickerField(
                  label: 'Data da partida',
                  data: dataPartida,
                  onChanged: (valor) {
                    setState(() {
                      dataPartida = valor;
                    });
                  },
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: stageController,
                  decoration: const InputDecoration(
                    labelText: 'Stage opcional',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.map_outlined),
                  ),
                  onChanged: (valor) {
                    stage = valor;
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'Resultado',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'Vitória', label: Text('Vitória')),
                    ButtonSegment(value: 'Derrota', label: Text('Derrota')),
                  ],
                  selected: {resultado},
                  onSelectionChanged: (valor) {
                    atualizarResultado(valor.first);
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'Placar',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: placaresDisponiveis
                      .map(
                        (item) => ButtonSegment(value: item, label: Text(item)),
                      )
                      .toList(),
                  selected: {placar},
                  onSelectionChanged: (valor) {
                    atualizarPlacar(valor.first);
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  analiseLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SearchableOptionField(
                  label: venceu ? 'Como venceu' : 'Como perdeu',
                  value: analiseSelecionada,
                  options: venceu
                      ? opcoesComoVenceuGuiltyGearStrive
                      : opcoesComoPerdeuGuiltyGearStrive,
                  icon: venceu
                      ? Icons.trending_up_outlined
                      : Icons.warning_amber_outlined,
                  onChanged: (valor) {
                    setState(() {
                      if (venceu) {
                        comoVenceu = valor;
                      } else {
                        comoPerdeu = valor;
                      }
                      pdlCalculado = gerarPdl();
                    });
                  },
                ),
                const SizedBox(height: 18),
                Card(
                  child: ListTile(
                    leading: Icon(
                      venceu ? Icons.arrow_upward : Icons.arrow_downward,
                    ),
                    title: const Text('Resultado final'),
                    subtitle: Text('$resultado $placar • $analiseSelecionada'),
                    trailing: Text(
                      '$sinalPdl$pdlCalculado PDL',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
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
                    labelText: 'Observações',
                    border: OutlineInputBorder(),
                    hintText:
                        'Ex: preso no canto, burst mal usado, bom Roman Cancel...',
                  ),
                  onChanged: (valor) {
                    observacoes = valor;
                  },
                ),
                const SizedBox(height: 28),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final Widget calcular = OutlinedButton(
                      onPressed: recalcularPdl,
                      child: const Text('Calcular PDL'),
                    );
                    final Widget salvar = ElevatedButton(
                      onPressed: salvarPartida,
                      child: Text(
                        editando ? 'Salvar edição' : 'Salvar partida',
                      ),
                    );

                    if (constraints.maxWidth < 520) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          calcular,
                          const SizedBox(height: 12),
                          salvar,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: calcular),
                        const SizedBox(width: 16),
                        Expanded(child: salvar),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RegistrarPartidaKofXVPage extends StatefulWidget {
  final String jogo;
  final List<String> sugestoesPlayers;
  final PartidaRegistrada? partidaInicial;
  final TimePrincipalKofXV timePrincipal;
  final bool repetirUltima;

  const RegistrarPartidaKofXVPage({
    super.key,
    this.jogo = jogoKofXV,
    this.sugestoesPlayers = const [],
    this.partidaInicial,
    this.timePrincipal = timePrincipalKofVazio,
    this.repetirUltima = false,
  });

  @override
  State<RegistrarPartidaKofXVPage> createState() =>
      _RegistrarPartidaKofXVPageState();
}

class _RegistrarPartidaKofXVPageState extends State<RegistrarPartidaKofXVPage> {
  Character? meuPoint;
  Character? meuMid;
  Character? meuAnchor;
  Character? adversarioPoint;
  Character? adversarioMid;
  Character? adversarioAnchor;

  String resultado = 'Vitória';
  String nickAdversario = '';
  String placar = placaresVitoriaKofXV[0];
  int personagensRestantes = 1;
  String quemCaiuPrimeiro = participantesAnaliseKofXV.last;
  String quemFechouLuta = participantesAnaliseKofXV.last;
  String condicaoVitoria = opcoesComoVenceuKofXV[0];
  String motivoDerrota = opcoesComoPerdeuKofXV[0];
  String observacoes = '';
  DateTime dataPartida = DateTime.now();
  int pdlCalculado = 0;

  late TextEditingController observacoesController;

  bool get editando {
    return widget.partidaInicial != null && !widget.repetirUltima;
  }

  bool get venceu {
    return resultadoEhVitoria(resultado);
  }

  List<String> get placaresDisponiveis {
    return venceu ? placaresVitoriaKofXV : placaresDerrotaKofXV;
  }

  String get meuTimeKey {
    return chaveTimeKofXV(
      meuPoint?.name ?? '',
      meuMid?.name ?? '',
      meuAnchor?.name ?? '',
    );
  }

  String get meuTimeTexto {
    return meuPoint != null && meuMid != null && meuAnchor != null
        ? 'Point: ${meuPoint!.name} / Mid: ${meuMid!.name} / Anchor: ${meuAnchor!.name}'
        : 'Time incompleto';
  }

  String get timeAdversarioTexto {
    return adversarioPoint != null &&
            adversarioMid != null &&
            adversarioAnchor != null
        ? 'Point: ${adversarioPoint!.name} / Mid: ${adversarioMid!.name} / Anchor: ${adversarioAnchor!.name}'
        : 'Time adversario incompleto';
  }

  @override
  void initState() {
    super.initState();

    final PartidaRegistrada? partida = widget.partidaInicial;
    if (partida != null) {
      if (widget.repetirUltima && widget.timePrincipal.completo) {
        meuPoint = encontrarPersonagem(widget.timePrincipal.point);
        meuMid = encontrarPersonagem(widget.timePrincipal.mid);
        meuAnchor = encontrarPersonagem(widget.timePrincipal.anchor);
      } else {
        meuPoint = encontrarPersonagem(partida.meuTimeSlot1);
        meuMid = encontrarPersonagem(partida.meuTimeSlot2);
        meuAnchor = encontrarPersonagem(partida.meuTimeSlot3);
      }
      adversarioPoint = encontrarPersonagem(partida.timeAdversarioSlot1);
      adversarioMid = encontrarPersonagem(partida.timeAdversarioSlot2);
      adversarioAnchor = encontrarPersonagem(partida.timeAdversarioSlot3);
      resultado = partida.resultado.isEmpty ? 'Vitória' : partida.resultado;
      nickAdversario = partida.nickAdversario == 'Sem nick'
          ? ''
          : partida.nickAdversario;
      if (placaresKofXV.contains(partida.placarStreetFighter)) {
        placar = partida.placarStreetFighter;
      }
      personagensRestantes = partida.stocks.clamp(0, 3).toInt();
      if (participantesAnaliseKofXV.contains(partida.primeiroDerrotado)) {
        quemCaiuPrimeiro = partida.primeiroDerrotado;
      }
      if (participantesAnaliseKofXV.contains(partida.personagemDestaque)) {
        quemFechouLuta = partida.personagemDestaque;
      }
      if (opcoesComoVenceuKofXV.contains(partida.condicaoVitoria)) {
        condicaoVitoria = partida.condicaoVitoria;
      }
      if (opcoesComoPerdeuKofXV.contains(partida.motivoDerrota)) {
        motivoDerrota = partida.motivoDerrota;
      }
      observacoes = partida.observacoes;
      dataPartida = partida.data;

      if (widget.repetirUltima) {
        resultado = 'Vitória';
        placar = placaresVitoriaKofXV[0];
        personagensRestantes = 1;
        quemCaiuPrimeiro = participantesAnaliseKofXV.last;
        quemFechouLuta = participantesAnaliseKofXV.last;
        condicaoVitoria = opcoesComoVenceuKofXV[0];
        motivoDerrota = opcoesComoPerdeuKofXV[0];
        observacoes = '';
        dataPartida = DateTime.now();
      }
    } else if (widget.timePrincipal.completo) {
      meuPoint = encontrarPersonagem(widget.timePrincipal.point);
      meuMid = encontrarPersonagem(widget.timePrincipal.mid);
      meuAnchor = encontrarPersonagem(widget.timePrincipal.anchor);
    }

    ajustarPlacarAoResultado();
    pdlCalculado = gerarPdl();
    observacoesController = TextEditingController(text: observacoes);
  }

  @override
  void dispose() {
    observacoesController.dispose();
    super.dispose();
  }

  Character? encontrarPersonagem(String nome) {
    if (nome.trim().isEmpty) return null;

    final String nomeNormalizado = normalizarNomePersonagem(nome);
    for (final personagem in rosterDoJogo(widget.jogo)) {
      if (personagem.name == nomeNormalizado) {
        return personagem;
      }
    }

    return null;
  }

  void ajustarPlacarAoResultado() {
    if (!placaresDisponiveis.contains(placar)) {
      placar = placaresDisponiveis.first;
    }
  }

  int gerarPdl() {
    return calcularPdlKofXV(
      resultado: resultado,
      placar: placar,
      personagensRestantes: personagensRestantes,
      condicaoVitoria: condicaoVitoria,
      motivoDerrota: motivoDerrota,
    );
  }

  Future<void> escolherPersonagem({
    required String titulo,
    required ValueChanged<Character> onEscolhido,
  }) async {
    final Character? personagemEscolhido = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelecionarPersonagemPage(
          titulo: titulo,
          personagens: rosterDoJogo(widget.jogo),
          jogoAtual: widget.jogo,
        ),
      ),
    );

    if (personagemEscolhido != null) {
      setState(() {
        onEscolhido(personagemEscolhido);
        pdlCalculado = gerarPdl();
      });
    }
  }

  void mostrarAviso(String titulo, String mensagem) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(titulo),
          content: Text(mensagem),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ok'),
            ),
          ],
        );
      },
    );
  }

  void salvarPartida() {
    if (meuPoint == null || meuMid == null || meuAnchor == null) {
      mostrarAviso(
        'Time incompleto',
        'Monte Point, Mid e Anchor antes de salvar.',
      );
      return;
    }

    if (adversarioPoint == null ||
        adversarioMid == null ||
        adversarioAnchor == null) {
      mostrarAviso(
        'Time adversario incompleto',
        'Escolha Point, Mid e Anchor do adversario antes de salvar.',
      );
      return;
    }

    final int pdlFinal = gerarPdl();
    final String nickFinal = nickAdversario.trim().isEmpty
        ? 'Desconhecido'
        : nickAdversario.trim();

    setState(() {
      pdlCalculado = pdlFinal;
    });

    final PartidaRegistrada partida = PartidaRegistrada(
      jogo: widget.jogo,
      personagemJogador: meuTimeKey,
      nickAdversario: nickFinal,
      personagemAdversario: adversarioPoint!.name,
      stage: 'Team Order 3v3',
      resultado: resultado,
      stocks: personagensRestantes,
      porcentagem: 0,
      formaDeKill: venceu ? condicaoVitoria : 'Não aplicável',
      formaDeMorte: venceu ? 'Não aplicável' : motivoDerrota,
      observacoes: observacoesController.text.trim(),
      pdlGerado: pdlFinal,
      data: dataPartida,
      meuTimeSlot1: meuPoint!.name,
      meuTimeSlot2: meuMid!.name,
      meuTimeSlot3: meuAnchor!.name,
      timeAdversarioSlot1: adversarioPoint!.name,
      timeAdversarioSlot2: adversarioMid!.name,
      timeAdversarioSlot3: adversarioAnchor!.name,
      personagemDestaque: quemFechouLuta,
      primeiroDerrotado: quemCaiuPrimeiro,
      personagemInimigoProblema: chaveTimeKofXV(
        adversarioPoint!.name,
        adversarioMid!.name,
        adversarioAnchor!.name,
      ),
      condicaoVitoria: venceu ? condicaoVitoria : '',
      motivoDerrota: venceu ? '' : motivoDerrota,
      placarRounds: placar,
    );

    showDialog(
      context: context,
      builder: (context) {
        final String sinal = partida.pdlGerado >= 0 ? '+' : '';
        final String textoObservacoes = partida.observacoes.isEmpty
            ? 'Sem observacoes'
            : partida.observacoes;
        final String analiseLabel = venceu ? 'Como venceu' : 'Como perdeu';

        return AlertDialog(
          title: Text(editando ? 'Partida atualizada' : 'Partida registrada'),
          content: Text(
            'Meu time: ${partida.meuTimeTexto}\n'
            'Time adversario: ${partida.timeAdversarioTexto}\n'
            'Adversario: ${partida.nickAdversario}\n'
            'Resultado: ${partida.resultado} ${partida.placarStreetFighter}\n'
            'Personagens restantes: ${partida.stocks}\n'
            '$analiseLabel: ${partida.analiseResultado}\n'
            'Caiu primeiro: ${partida.primeiroDerrotado}\n'
            'Fechou: ${partida.personagemDestaque}\n'
            'Observacoes: $textoObservacoes\n'
            'PDL gerado: $sinal${partida.pdlGerado}',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, partida);
              },
              child: Text(editando ? 'Concluir edicao' : 'Salvar e voltar'),
            ),
          ],
        );
      },
    );
  }

  Widget construirAutocompletePlayer() {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: nickAdversario),
      optionsBuilder: (textEditingValue) {
        final String busca = textEditingValue.text.trim().toLowerCase();
        final List<String> sugestoes = [
          'Desconhecido',
          ...widget.sugestoesPlayers,
        ].where((nick) => nick.trim().isNotEmpty).toSet().toList();

        if (busca.isEmpty) {
          return sugestoes.take(8);
        }

        return sugestoes.where((nick) => nick.toLowerCase().contains(busca));
      },
      onSelected: (valor) {
        setState(() {
          nickAdversario = valor;
        });
      },
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) {
            return TextField(
              controller: textEditingController,
              focusNode: focusNode,
              decoration: const InputDecoration(
                labelText: 'Adversario / player',
                border: OutlineInputBorder(),
                hintText: 'Digite ou escolha um player ja enfrentado',
                prefixIcon: Icon(Icons.person_search_outlined),
              ),
              onChanged: (valor) {
                nickAdversario = valor;
              },
            );
          },
    );
  }

  Widget construirSlots({
    required String titulo,
    required List<_KofSlotConfig> slots,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: slots
                  .map(
                    (slot) => SizedBox(
                      width: MediaQuery.sizeOf(context).width < 760
                          ? double.infinity
                          : 220,
                      child: _InvincibleCharacterSlot(
                        label: slot.label,
                        personagem: slot.personagem,
                        jogo: widget.jogo,
                        onTap: () => escolherPersonagem(
                          titulo: slot.tituloSeletor,
                          onEscolhido: slot.onEscolhido,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final String sinalPdl = pdlCalculado >= 0 ? '+' : '';
    final String analiseLabel = venceu ? 'Como venceu' : 'Como perdeu';

    return Scaffold(
      appBar: AppBar(
        title: CompactAppBarTitle(
          editando ? 'Editar partida KOF XV' : 'Registrar partida KOF XV',
        ),
        centerTitle: true,
        actions: const [HomeNavigationButton()],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$meuTimeTexto vs $timeAdversarioTexto',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The King of Fighters XV - Team Order',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 28),
                  construirSlots(
                    titulo: 'Meu time',
                    slots: [
                      _KofSlotConfig(
                        label: 'Point',
                        tituloSeletor: 'Meu Point',
                        personagem: meuPoint,
                        onEscolhido: (personagem) => meuPoint = personagem,
                      ),
                      _KofSlotConfig(
                        label: 'Mid',
                        tituloSeletor: 'Meu Mid',
                        personagem: meuMid,
                        onEscolhido: (personagem) => meuMid = personagem,
                      ),
                      _KofSlotConfig(
                        label: 'Anchor',
                        tituloSeletor: 'Meu Anchor',
                        personagem: meuAnchor,
                        onEscolhido: (personagem) => meuAnchor = personagem,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  construirSlots(
                    titulo: 'Time adversario',
                    slots: [
                      _KofSlotConfig(
                        label: 'Point adversario',
                        tituloSeletor: 'Point adversario',
                        personagem: adversarioPoint,
                        onEscolhido: (personagem) =>
                            adversarioPoint = personagem,
                      ),
                      _KofSlotConfig(
                        label: 'Mid adversario',
                        tituloSeletor: 'Mid adversario',
                        personagem: adversarioMid,
                        onEscolhido: (personagem) => adversarioMid = personagem,
                      ),
                      _KofSlotConfig(
                        label: 'Anchor adversario',
                        tituloSeletor: 'Anchor adversario',
                        personagem: adversarioAnchor,
                        onEscolhido: (personagem) =>
                            adversarioAnchor = personagem,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Adversario',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  construirAutocompletePlayer(),
                  const SizedBox(height: 24),
                  DatePickerField(
                    label: 'Data da partida',
                    data: dataPartida,
                    onChanged: (valor) {
                      setState(() {
                        dataPartida = valor;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Resultado',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'Vitória', label: Text('Vitória')),
                      ButtonSegment(value: 'Derrota', label: Text('Derrota')),
                    ],
                    selected: {resultado},
                    onSelectionChanged: (valor) {
                      setState(() {
                        resultado = valor.first;
                        ajustarPlacarAoResultado();
                        pdlCalculado = gerarPdl();
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Placar',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: placaresDisponiveis
                        .map(
                          (item) =>
                              ButtonSegment(value: item, label: Text(item)),
                        )
                        .toList(),
                    selected: {placar},
                    onSelectionChanged: (valor) {
                      setState(() {
                        placar = valor.first;
                        pdlCalculado = gerarPdl();
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  SearchableOptionField(
                    label: 'Personagens restantes',
                    value: '$personagensRestantes',
                    options: personagensRestantesKofXV,
                    icon: Icons.groups_outlined,
                    onChanged: (valor) {
                      setState(() {
                        personagensRestantes = int.tryParse(valor) ?? 0;
                        pdlCalculado = gerarPdl();
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  SearchableOptionField(
                    label: 'Quem caiu primeiro?',
                    value: quemCaiuPrimeiro,
                    options: participantesAnaliseKofXV,
                    icon: Icons.south_outlined,
                    onChanged: (valor) {
                      setState(() {
                        quemCaiuPrimeiro = valor;
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  SearchableOptionField(
                    label: 'Quem fechou a luta?',
                    value: quemFechouLuta,
                    options: participantesAnaliseKofXV,
                    icon: Icons.flag_outlined,
                    onChanged: (valor) {
                      setState(() {
                        quemFechouLuta = valor;
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  SearchableOptionField(
                    label: analiseLabel,
                    value: venceu ? condicaoVitoria : motivoDerrota,
                    options: venceu
                        ? opcoesComoVenceuKofXV
                        : opcoesComoPerdeuKofXV,
                    icon: venceu
                        ? Icons.emoji_events_outlined
                        : Icons.report_problem_outlined,
                    onChanged: (valor) {
                      setState(() {
                        if (venceu) {
                          condicaoVitoria = valor;
                        } else {
                          motivoDerrota = valor;
                        }
                        pdlCalculado = gerarPdl();
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                  Card(
                    child: ListTile(
                      leading: Icon(
                        venceu ? Icons.arrow_upward : Icons.arrow_downward,
                      ),
                      title: const Text('Resumo'),
                      subtitle: Text(
                        '$resultado $placar - $personagensRestantes restantes - $analiseLabel',
                      ),
                      trailing: Text(
                        '$sinalPdl$pdlCalculado PDL',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Observacoes',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: observacoesController,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'Observacoes',
                      border: OutlineInputBorder(),
                      hintText:
                          'Ex: point caiu cedo, anchor fechou, MAX Mode...',
                    ),
                  ),
                  const SizedBox(height: 28),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final Widget calcular = OutlinedButton(
                        onPressed: () {
                          setState(() {
                            pdlCalculado = gerarPdl();
                          });
                        },
                        child: const Text('Calcular PDL'),
                      );
                      final Widget salvar = ElevatedButton(
                        onPressed: salvarPartida,
                        child: Text(
                          editando ? 'Salvar edicao' : 'Salvar partida',
                        ),
                      );

                      if (constraints.maxWidth < 520) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            calcular,
                            const SizedBox(height: 12),
                            salvar,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: calcular),
                          const SizedBox(width: 16),
                          Expanded(child: salvar),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _KofSlotConfig {
  final String label;
  final String tituloSeletor;
  final Character? personagem;
  final ValueChanged<Character> onEscolhido;

  const _KofSlotConfig({
    required this.label,
    required this.tituloSeletor,
    required this.personagem,
    required this.onEscolhido,
  });
}

class RegistrarPartida2XKOPage extends StatefulWidget {
  final String jogo;
  final List<String> sugestoesPlayers;
  final PartidaRegistrada? partidaInicial;
  final TimePrincipal2XKO timePrincipal;
  final bool repetirUltima;

  const RegistrarPartida2XKOPage({
    super.key,
    this.jogo = jogo2Xko,
    this.sugestoesPlayers = const [],
    this.partidaInicial,
    this.timePrincipal = timePrincipal2XKOVazio,
    this.repetirUltima = false,
  });

  @override
  State<RegistrarPartida2XKOPage> createState() =>
      _RegistrarPartida2XKOPageState();
}

class _RegistrarPartida2XKOPageState extends State<RegistrarPartida2XKOPage> {
  Character? meuPoint;
  Character? meuAssist;
  Character? adversarioPoint;
  Character? adversarioAssist;

  String resultado = 'Vitória';
  String nickAdversario = '';
  String placar = placaresVitoria2XKO[0];
  String condicaoVitoria = opcoesComoVenceu2XKO[0];
  String motivoDerrota = opcoesComoPerdeu2XKO[0];
  String quemAbriuHit = participantesAnalise2XKO.last;
  String quemFechouLuta = participantesAnalise2XKO.last;
  String observacoes = '';
  DateTime dataPartida = DateTime.now();
  int pdlCalculado = 0;

  late TextEditingController observacoesController;

  bool get editando {
    return widget.partidaInicial != null && !widget.repetirUltima;
  }

  bool get venceu {
    return resultadoEhVitoria(resultado);
  }

  List<String> get placaresDisponiveis {
    return venceu ? placaresVitoria2XKO : placaresDerrota2XKO;
  }

  String get minhaDuplaKey {
    return chaveDupla2XKO(meuPoint?.name ?? '', meuAssist?.name ?? '');
  }

  String get minhaDuplaTexto {
    return meuPoint != null && meuAssist != null
        ? 'Point: ${meuPoint!.name} / Assist: ${meuAssist!.name}'
        : 'Dupla incompleta';
  }

  String get duplaAdversariaTexto {
    return adversarioPoint != null && adversarioAssist != null
        ? 'Point: ${adversarioPoint!.name} / Assist: ${adversarioAssist!.name}'
        : 'Dupla adversária incompleta';
  }

  @override
  void initState() {
    super.initState();

    final PartidaRegistrada? partida = widget.partidaInicial;
    if (partida != null) {
      if (widget.repetirUltima && widget.timePrincipal.completo) {
        meuPoint = encontrarPersonagem(widget.timePrincipal.point);
        meuAssist = encontrarPersonagem(widget.timePrincipal.assist);
      } else {
        meuPoint = encontrarPersonagem(partida.meuTimeSlot1);
        meuAssist = encontrarPersonagem(partida.meuTimeSlot2);
      }
      adversarioPoint = encontrarPersonagem(partida.timeAdversarioSlot1);
      adversarioAssist = encontrarPersonagem(partida.timeAdversarioSlot2);
      resultado = partida.resultado.isEmpty ? 'Vitória' : partida.resultado;
      nickAdversario = partida.nickAdversario == 'Sem nick'
          ? ''
          : partida.nickAdversario;
      if (placares2XKO.contains(partida.placarStreetFighter)) {
        placar = partida.placarStreetFighter;
      }
      if (opcoesComoVenceu2XKO.contains(partida.condicaoVitoria)) {
        condicaoVitoria = partida.condicaoVitoria;
      }
      if (opcoesComoPerdeu2XKO.contains(partida.motivoDerrota)) {
        motivoDerrota = partida.motivoDerrota;
      }
      if (participantesAnalise2XKO.contains(partida.personagemDestaque)) {
        quemAbriuHit = partida.personagemDestaque;
      }
      if (participantesAnalise2XKO.contains(partida.primeiroDerrotado)) {
        quemFechouLuta = partida.primeiroDerrotado;
      }
      observacoes = partida.observacoes;
      dataPartida = partida.data;

      if (widget.repetirUltima) {
        resultado = 'Vitória';
        placar = placaresVitoria2XKO[0];
        condicaoVitoria = opcoesComoVenceu2XKO[0];
        motivoDerrota = opcoesComoPerdeu2XKO[0];
        quemAbriuHit = participantesAnalise2XKO.last;
        quemFechouLuta = participantesAnalise2XKO.last;
        observacoes = '';
        dataPartida = DateTime.now();
      }
    } else if (widget.timePrincipal.completo) {
      meuPoint = encontrarPersonagem(widget.timePrincipal.point);
      meuAssist = encontrarPersonagem(widget.timePrincipal.assist);
    }

    ajustarPlacarAoResultado();
    pdlCalculado = gerarPdl();
    observacoesController = TextEditingController(text: observacoes);
  }

  @override
  void dispose() {
    observacoesController.dispose();
    super.dispose();
  }

  Character? encontrarPersonagem(String nome) {
    if (nome.trim().isEmpty) return null;

    final String nomeNormalizado = normalizarNomePersonagem(nome);
    for (final personagem in rosterDoJogo(widget.jogo)) {
      if (personagem.name == nomeNormalizado) {
        return personagem;
      }
    }

    return null;
  }

  void ajustarPlacarAoResultado() {
    if (!placaresDisponiveis.contains(placar)) {
      placar = placaresDisponiveis.first;
    }
  }

  int gerarPdl() {
    return calcularPdl2XKO(
      resultado: resultado,
      placar: placar,
      condicaoVitoria: condicaoVitoria,
      motivoDerrota: motivoDerrota,
    );
  }

  Future<void> escolherPersonagem({
    required String titulo,
    required ValueChanged<Character> onEscolhido,
  }) async {
    final Character? personagemEscolhido = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelecionarPersonagemPage(
          titulo: titulo,
          personagens: rosterDoJogo(widget.jogo),
          jogoAtual: widget.jogo,
        ),
      ),
    );

    if (personagemEscolhido != null) {
      setState(() {
        onEscolhido(personagemEscolhido);
        pdlCalculado = gerarPdl();
      });
    }
  }

  void mostrarAviso(String titulo, String mensagem) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(titulo),
          content: Text(mensagem),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ok'),
            ),
          ],
        );
      },
    );
  }

  void salvarPartida() {
    if (meuPoint == null || meuAssist == null) {
      mostrarAviso(
        'Dupla incompleta',
        'Monte Point/Main e Assist/Second antes de salvar.',
      );
      return;
    }

    if (adversarioPoint == null || adversarioAssist == null) {
      mostrarAviso(
        'Dupla adversária incompleta',
        'Escolha Point e Assist do adversário antes de salvar.',
      );
      return;
    }

    final int pdlFinal = gerarPdl();
    final String nickFinal = nickAdversario.trim().isEmpty
        ? 'Desconhecido'
        : nickAdversario.trim();
    final String teamKey = minhaDuplaKey;

    setState(() {
      pdlCalculado = pdlFinal;
    });

    final PartidaRegistrada partida = PartidaRegistrada(
      jogo: widget.jogo,
      personagemJogador: teamKey,
      nickAdversario: nickFinal,
      personagemAdversario: adversarioPoint!.name,
      stage: 'Tag 2v2',
      resultado: resultado,
      stocks: 0,
      porcentagem: 0,
      formaDeKill: venceu ? condicaoVitoria : 'Não aplicável',
      formaDeMorte: venceu ? 'Não aplicável' : motivoDerrota,
      observacoes: observacoesController.text.trim(),
      pdlGerado: pdlFinal,
      data: dataPartida,
      meuTimeSlot1: meuPoint!.name,
      meuTimeSlot2: meuAssist!.name,
      timeAdversarioSlot1: adversarioPoint!.name,
      timeAdversarioSlot2: adversarioAssist!.name,
      personagemDestaque: quemAbriuHit,
      primeiroDerrotado: quemFechouLuta,
      personagemInimigoProblema: chaveDupla2XKO(
        adversarioPoint!.name,
        adversarioAssist!.name,
      ),
      condicaoVitoria: venceu ? condicaoVitoria : '',
      motivoDerrota: venceu ? '' : motivoDerrota,
      placarRounds: placar,
    );

    showDialog(
      context: context,
      builder: (context) {
        final String sinal = partida.pdlGerado >= 0 ? '+' : '';
        final String textoObservacoes = partida.observacoes.isEmpty
            ? 'Sem observações'
            : partida.observacoes;
        final String analiseLabel = venceu ? 'Como venceu' : 'Como perdeu';

        return AlertDialog(
          title: Text(editando ? 'Partida atualizada' : 'Partida registrada'),
          content: Text(
            'Minha dupla: ${partida.meuTimeTexto}\n'
            'Dupla adversária: ${partida.timeAdversarioTexto}\n'
            'Adversário: ${partida.nickAdversario}\n'
            'Resultado: ${partida.resultado} ${partida.placarStreetFighter}\n'
            '$analiseLabel: ${partida.analiseResultado}\n'
            'Abriu hit: ${partida.personagemDestaque}\n'
            'Fechou luta: ${partida.primeiroDerrotado}\n'
            'Observações: $textoObservacoes\n'
            'PDL gerado: $sinal${partida.pdlGerado}',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, partida);
              },
              child: Text(editando ? 'Concluir edição' : 'Salvar e voltar'),
            ),
          ],
        );
      },
    );
  }

  Widget construirAutocompletePlayer() {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: nickAdversario),
      optionsBuilder: (textEditingValue) {
        final String busca = textEditingValue.text.trim().toLowerCase();
        final List<String> sugestoes = [
          'Desconhecido',
          ...widget.sugestoesPlayers,
        ].where((nick) => nick.trim().isNotEmpty).toSet().toList();

        if (busca.isEmpty) {
          return sugestoes.take(8);
        }

        return sugestoes.where((nick) => nick.toLowerCase().contains(busca));
      },
      onSelected: (valor) {
        setState(() {
          nickAdversario = valor;
        });
      },
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) {
            return TextField(
              controller: textEditingController,
              focusNode: focusNode,
              decoration: const InputDecoration(
                labelText: 'Adversário / player',
                border: OutlineInputBorder(),
                hintText: 'Digite ou escolha um player já enfrentado',
                prefixIcon: Icon(Icons.person_search_outlined),
              ),
              onChanged: (valor) {
                nickAdversario = valor;
              },
            );
          },
    );
  }

  Widget construirTimeUsuario() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Meu time', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children:
                  [
                        _InvincibleCharacterSlot(
                          label: 'Point/Main',
                          personagem: meuPoint,
                          jogo: widget.jogo,
                          onTap: () => escolherPersonagem(
                            titulo: 'Meu Point/Main',
                            onEscolhido: (personagem) => meuPoint = personagem,
                          ),
                        ),
                        _InvincibleCharacterSlot(
                          label: 'Assist/Second',
                          personagem: meuAssist,
                          jogo: widget.jogo,
                          onTap: () => escolherPersonagem(
                            titulo: 'Meu Assist/Second',
                            onEscolhido: (personagem) => meuAssist = personagem,
                          ),
                        ),
                      ]
                      .map(
                        (slot) => SizedBox(
                          width: MediaQuery.sizeOf(context).width < 680
                              ? double.infinity
                              : 260,
                          child: slot,
                        ),
                      )
                      .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget construirTimeAdversario() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Time adversário',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children:
              [
                    _InvincibleCharacterSlot(
                      label: 'Point adversário',
                      personagem: adversarioPoint,
                      jogo: widget.jogo,
                      onTap: () => escolherPersonagem(
                        titulo: 'Point adversário',
                        onEscolhido: (personagem) =>
                            adversarioPoint = personagem,
                      ),
                    ),
                    _InvincibleCharacterSlot(
                      label: 'Assist adversário',
                      personagem: adversarioAssist,
                      jogo: widget.jogo,
                      onTap: () => escolherPersonagem(
                        titulo: 'Assist adversário',
                        onEscolhido: (personagem) =>
                            adversarioAssist = personagem,
                      ),
                    ),
                  ]
                  .map(
                    (slot) => SizedBox(
                      width: MediaQuery.sizeOf(context).width < 680
                          ? double.infinity
                          : 260,
                      child: slot,
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final String sinalPdl = pdlCalculado >= 0 ? '+' : '';
    final String analiseLabel = venceu ? 'Como venceu' : 'Como perdeu';

    return Scaffold(
      appBar: AppBar(
        title: CompactAppBarTitle(
          editando ? 'Editar partida 2XKO' : 'Registrar partida 2XKO',
        ),
        centerTitle: true,
        actions: const [HomeNavigationButton()],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$minhaDuplaTexto vs $duplaAdversariaTexto',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '2XKO • Tag Fighter 2v2',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 28),
                  construirTimeUsuario(),
                  const SizedBox(height: 24),
                  construirTimeAdversario(),
                  const SizedBox(height: 24),
                  const Text(
                    'Adversário',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  construirAutocompletePlayer(),
                  const SizedBox(height: 24),
                  DatePickerField(
                    label: 'Data da partida',
                    data: dataPartida,
                    onChanged: (valor) {
                      setState(() {
                        dataPartida = valor;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Resultado',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'Vitória', label: Text('Vitória')),
                      ButtonSegment(value: 'Derrota', label: Text('Derrota')),
                    ],
                    selected: {resultado},
                    onSelectionChanged: (valor) {
                      setState(() {
                        resultado = valor.first;
                        ajustarPlacarAoResultado();
                        pdlCalculado = gerarPdl();
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Placar',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: placaresDisponiveis
                        .map(
                          (item) =>
                              ButtonSegment(value: item, label: Text(item)),
                        )
                        .toList(),
                    selected: {placar},
                    onSelectionChanged: (valor) {
                      setState(() {
                        placar = valor.first;
                        pdlCalculado = gerarPdl();
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  SearchableOptionField(
                    label: analiseLabel,
                    value: venceu ? condicaoVitoria : motivoDerrota,
                    options: venceu
                        ? opcoesComoVenceu2XKO
                        : opcoesComoPerdeu2XKO,
                    icon: venceu
                        ? Icons.emoji_events_outlined
                        : Icons.report_problem_outlined,
                    onChanged: (valor) {
                      setState(() {
                        if (venceu) {
                          condicaoVitoria = valor;
                        } else {
                          motivoDerrota = valor;
                        }
                        pdlCalculado = gerarPdl();
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  SearchableOptionField(
                    label: 'Quem abriu hit?',
                    value: quemAbriuHit,
                    options: participantesAnalise2XKO,
                    icon: Icons.flash_on_outlined,
                    onChanged: (valor) {
                      setState(() {
                        quemAbriuHit = valor;
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  SearchableOptionField(
                    label: 'Quem fechou a luta?',
                    value: quemFechouLuta,
                    options: participantesAnalise2XKO,
                    icon: Icons.flag_outlined,
                    onChanged: (valor) {
                      setState(() {
                        quemFechouLuta = valor;
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                  Card(
                    child: ListTile(
                      leading: Icon(
                        venceu ? Icons.arrow_upward : Icons.arrow_downward,
                      ),
                      title: const Text('Resumo'),
                      subtitle: Text('$resultado $placar • $analiseLabel'),
                      trailing: Text(
                        '$sinalPdl$pdlCalculado PDL',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Observações',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: observacoesController,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'Observações',
                      border: OutlineInputBorder(),
                      hintText:
                          'Ex: assist punido, tag combo funcionou, comeback...',
                    ),
                  ),
                  const SizedBox(height: 28),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final Widget calcular = OutlinedButton(
                        onPressed: () {
                          setState(() {
                            pdlCalculado = gerarPdl();
                          });
                        },
                        child: const Text('Calcular PDL'),
                      );
                      final Widget salvar = ElevatedButton(
                        onPressed: salvarPartida,
                        child: Text(
                          editando ? 'Salvar edição' : 'Salvar partida',
                        ),
                      );

                      if (constraints.maxWidth < 520) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            calcular,
                            const SizedBox(height: 12),
                            salvar,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: calcular),
                          const SizedBox(width: 16),
                          Expanded(child: salvar),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RegistrarPartidaInvinciblePage extends StatefulWidget {
  final String jogo;
  final List<String> sugestoesPlayers;
  final PartidaRegistrada? partidaInicial;
  final TimePrincipalInvincible? timePrincipal;
  final bool repetirUltima;

  const RegistrarPartidaInvinciblePage({
    super.key,
    this.jogo = jogoInvincibleVs,
    this.sugestoesPlayers = const [],
    this.partidaInicial,
    this.timePrincipal,
    this.repetirUltima = false,
  });

  @override
  State<RegistrarPartidaInvinciblePage> createState() =>
      _RegistrarPartidaInvinciblePageState();
}

class _RegistrarPartidaInvinciblePageState
    extends State<RegistrarPartidaInvinciblePage> {
  Character? meuSlot1;
  Character? meuSlot2;
  Character? meuSlot3;
  Character? adversarioSlot1;
  Character? adversarioSlot2;
  Character? adversarioSlot3;

  String resultado = 'Vitória';
  String nickAdversario = '';
  String personagemDestaque = '';
  String primeiroDerrotado = '';
  String personagemInimigoProblema = '';
  String condicaoVitoria = condicoesVitoriaInvincible[0];
  String motivoDerrota = motivosDerrotaInvincible[0];
  String observacoes = '';
  DateTime dataPartida = DateTime.now();
  int lpCalculado = 0;

  late TextEditingController observacoesController;

  bool get editando {
    return widget.partidaInicial != null && !widget.repetirUltima;
  }

  List<String> get nomesMeuTime {
    return [
      meuSlot1,
      meuSlot2,
      meuSlot3,
    ].whereType<Character>().map((personagem) => personagem.name).toList();
  }

  List<String> get nomesTimeAdversario {
    return [
      adversarioSlot1,
      adversarioSlot2,
      adversarioSlot3,
    ].whereType<Character>().map((personagem) => personagem.name).toList();
  }

  String get meuTimeTexto {
    return nomesMeuTime.length == 3 ? nomesMeuTime.join(' / ') : 'Meu time 3v3';
  }

  String get timeAdversarioTexto {
    return nomesTimeAdversario.length == 3
        ? nomesTimeAdversario.join(' / ')
        : 'Time adversário 3v3';
  }

  @override
  void initState() {
    super.initState();

    final PartidaRegistrada? partida = widget.partidaInicial;

    if (partida != null) {
      if (widget.repetirUltima && widget.timePrincipal?.completo == true) {
        final TimePrincipalInvincible time = widget.timePrincipal!;
        meuSlot1 = encontrarPersonagemInvincible(time.slot1);
        meuSlot2 = encontrarPersonagemInvincible(time.slot2);
        meuSlot3 = encontrarPersonagemInvincible(time.slot3);
      } else {
        meuSlot1 = encontrarPersonagemInvincible(partida.meuTimeSlot1);
        meuSlot2 = encontrarPersonagemInvincible(partida.meuTimeSlot2);
        meuSlot3 = encontrarPersonagemInvincible(partida.meuTimeSlot3);
      }
      adversarioSlot1 = encontrarPersonagemInvincible(
        partida.timeAdversarioSlot1,
      );
      adversarioSlot2 = encontrarPersonagemInvincible(
        partida.timeAdversarioSlot2,
      );
      adversarioSlot3 = encontrarPersonagemInvincible(
        partida.timeAdversarioSlot3,
      );
      resultado = partida.resultado.isEmpty ? 'Vitória' : partida.resultado;
      nickAdversario = partida.nickAdversario == 'Sem nick'
          ? ''
          : partida.nickAdversario;
      personagemDestaque = partida.personagemDestaque;
      primeiroDerrotado = partida.primeiroDerrotado;
      personagemInimigoProblema = partida.personagemInimigoProblema;
      condicaoVitoria =
          condicoesVitoriaInvincible.contains(partida.condicaoVitoria)
          ? partida.condicaoVitoria
          : condicoesVitoriaInvincible[0];
      motivoDerrota = motivosDerrotaInvincible.contains(partida.motivoDerrota)
          ? partida.motivoDerrota
          : motivosDerrotaInvincible[0];
      observacoes = partida.observacoes;
      dataPartida = partida.data;
      if (widget.repetirUltima) {
        resultado = 'Vit\u00C3\u00B3ria';
        personagemDestaque = '';
        primeiroDerrotado = '';
        personagemInimigoProblema = '';
        condicaoVitoria = condicoesVitoriaInvincible[0];
        motivoDerrota = motivosDerrotaInvincible[0];
        observacoes = '';
        dataPartida = DateTime.now();
      }
    } else if (widget.timePrincipal?.completo == true) {
      final TimePrincipalInvincible time = widget.timePrincipal!;
      meuSlot1 = encontrarPersonagemInvincible(time.slot1);
      meuSlot2 = encontrarPersonagemInvincible(time.slot2);
      meuSlot3 = encontrarPersonagemInvincible(time.slot3);
    }

    sincronizarAnaliseSelecionada();
    lpCalculado = gerarLp();

    observacoesController = TextEditingController(text: observacoes);
  }

  @override
  void dispose() {
    observacoesController.dispose();
    super.dispose();
  }

  Character? encontrarPersonagemInvincible(String nome) {
    if (nome.trim().isEmpty) return null;

    final String nomeNormalizado = normalizarNomePersonagem(nome);
    for (final personagem in rosterDoJogo(widget.jogo)) {
      if (personagem.name == nomeNormalizado) {
        return personagem;
      }
    }

    return null;
  }

  void sincronizarAnaliseSelecionada() {
    final List<String> meuTime = nomesMeuTime;
    final List<String> inimigos = nomesTimeAdversario;

    if (!meuTime.contains(personagemDestaque)) {
      personagemDestaque = meuTime.isEmpty ? '' : meuTime.first;
    }

    if (!meuTime.contains(primeiroDerrotado)) {
      primeiroDerrotado = meuTime.isEmpty ? '' : meuTime.first;
    }

    if (!inimigos.contains(personagemInimigoProblema)) {
      personagemInimigoProblema = inimigos.isEmpty ? '' : inimigos.first;
    }
  }

  Future<void> escolherPersonagem({
    required String titulo,
    required ValueChanged<Character> onEscolhido,
  }) async {
    final Character? personagemEscolhido = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelecionarPersonagemPage(
          titulo: titulo,
          personagens: rosterDoJogo(widget.jogo),
          jogoAtual: widget.jogo,
        ),
      ),
    );

    if (personagemEscolhido != null) {
      setState(() {
        onEscolhido(personagemEscolhido);
        sincronizarAnaliseSelecionada();
        lpCalculado = gerarLp();
      });
    }
  }

  int gerarLp() {
    return calcularLpInvincible(
      resultado: resultado,
      condicaoVitoria: condicaoVitoria,
      motivoDerrota: motivoDerrota,
    );
  }

  void calcularLp() {
    setState(() {
      lpCalculado = gerarLp();
    });
  }

  void mostrarAviso(String titulo, String mensagem) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(titulo),
          content: Text(mensagem),
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

  void salvarPartida() {
    if ([
      meuSlot1,
      meuSlot2,
      meuSlot3,
    ].any((personagem) => personagem == null)) {
      mostrarAviso(
        'Meu time incompleto',
        'Escolha os 3 personagens do seu time antes de salvar.',
      );
      return;
    }

    if ([
      adversarioSlot1,
      adversarioSlot2,
      adversarioSlot3,
    ].any((personagem) => personagem == null)) {
      mostrarAviso(
        'Time adversário incompleto',
        'Escolha os 3 personagens do time adversário antes de salvar.',
      );
      return;
    }

    if (personagemDestaque.trim().isEmpty ||
        primeiroDerrotado.trim().isEmpty ||
        personagemInimigoProblema.trim().isEmpty) {
      mostrarAviso(
        'Análise incompleta',
        'Informe destaque, primeiro derrotado e personagem inimigo problema.',
      );
      return;
    }

    final int lpFinal = gerarLp();
    final String nickFinal = nickAdversario.trim().isEmpty
        ? 'Desconhecido'
        : nickAdversario.trim();

    setState(() {
      lpCalculado = lpFinal;
    });

    final PartidaRegistrada partida = PartidaRegistrada(
      jogo: jogoInvincibleVs,
      personagemJogador: meuSlot1!.name,
      nickAdversario: nickFinal,
      personagemAdversario: adversarioSlot1!.name,
      stage: 'Time 3v3',
      resultado: resultado,
      stocks: 0,
      porcentagem: 0,
      formaDeKill: resultado == 'Vitória' ? condicaoVitoria : 'Não aplicável',
      formaDeMorte: resultado == 'Derrota' ? motivoDerrota : 'Não aplicável',
      observacoes: observacoes.trim(),
      pdlGerado: lpFinal,
      data: dataPartida,
      meuTimeSlot1: meuSlot1!.name,
      meuTimeSlot2: meuSlot2!.name,
      meuTimeSlot3: meuSlot3!.name,
      timeAdversarioSlot1: adversarioSlot1!.name,
      timeAdversarioSlot2: adversarioSlot2!.name,
      timeAdversarioSlot3: adversarioSlot3!.name,
      personagemDestaque: personagemDestaque,
      primeiroDerrotado: primeiroDerrotado,
      personagemInimigoProblema: personagemInimigoProblema,
      condicaoVitoria: resultado == 'Vitória' ? condicaoVitoria : '',
      motivoDerrota: resultado == 'Derrota' ? motivoDerrota : '',
    );

    showDialog(
      context: context,
      builder: (context) {
        final String sinal = partida.pdlGerado >= 0 ? '+' : '';
        final String textoObservacoes = partida.observacoes.isEmpty
            ? 'Sem observações'
            : partida.observacoes;

        return AlertDialog(
          title: Text(editando ? 'Partida atualizada' : 'Partida registrada'),
          content: Text(
            'Meu time: ${partida.meuTimeTexto}\n'
            'Time adversário: ${partida.timeAdversarioTexto}\n'
            'Adversário: ${partida.nickAdversario}\n'
            'Resultado: ${partida.resultado}\n'
            '${partida.resultado == 'Vitória' ? 'Como venceu' : 'Como perdeu'}: ${partida.analiseResultado}\n'
            'Destaque: ${partida.personagemDestaque}\n'
            'Primeiro derrotado: ${partida.primeiroDerrotado}\n'
            'Inimigo problema: ${partida.personagemInimigoProblema}\n'
            'Observações: $textoObservacoes\n'
            'LP gerado: $sinal${partida.pdlGerado}',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, partida);
              },
              child: Text(editando ? 'Concluir edição' : 'Salvar e voltar'),
            ),
          ],
        );
      },
    );
  }

  Widget construirAutocompletePlayer() {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: nickAdversario),
      optionsBuilder: (textEditingValue) {
        final String busca = textEditingValue.text.trim().toLowerCase();
        final List<String> sugestoes = [
          'Desconhecido',
          ...widget.sugestoesPlayers,
        ].where((nick) => nick.trim().isNotEmpty).toSet().toList();

        if (busca.isEmpty) {
          return sugestoes.take(8);
        }

        return sugestoes.where((nick) => nick.toLowerCase().contains(busca));
      },
      onSelected: (valor) {
        setState(() {
          nickAdversario = valor;
        });
      },
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) {
            return TextField(
              controller: textEditingController,
              focusNode: focusNode,
              decoration: const InputDecoration(
                labelText: 'Adversário / player',
                border: OutlineInputBorder(),
                hintText:
                    'Digite, escolha um player ou deixe como Desconhecido',
                prefixIcon: Icon(Icons.person_search_outlined),
              ),
              onChanged: (valor) {
                nickAdversario = valor;
              },
            );
          },
    );
  }

  Widget construirSecaoTime({
    required String titulo,
    required List<Character?> slots,
    required List<VoidCallback> onTapSlots,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final bool compacto = constraints.maxWidth < 680;
            final double larguraSlot = compacto
                ? (constraints.maxWidth - 12) / 2
                : (constraints.maxWidth - 24) / 3;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (int index = 0; index < slots.length; index++)
                  SizedBox(
                    width: compacto ? larguraSlot : larguraSlot,
                    child: _InvincibleCharacterSlot(
                      label: 'Slot ${index + 1}',
                      personagem: slots[index],
                      jogo: widget.jogo,
                      onTap: onTapSlots[index],
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final String sinalLp = lpCalculado >= 0 ? '+' : '';
    final List<String> opcoesMeuTime = nomesMeuTime.isEmpty
        ? ['Escolha o time primeiro']
        : nomesMeuTime;
    final List<String> opcoesInimigos = nomesTimeAdversario.isEmpty
        ? ['Escolha o time adversário primeiro']
        : nomesTimeAdversario;
    final bool vitoria = resultado == 'Vitória';

    return Scaffold(
      appBar: AppBar(
        title: CompactAppBarTitle(
          editando ? 'Editar partida 3v3' : 'Registrar partida 3v3',
        ),
        centerTitle: true,
        actions: const [HomeNavigationButton()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$meuTimeTexto vs $timeAdversarioTexto',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Invincible VS • tracker de composição de time',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 28),
            construirSecaoTime(
              titulo: 'Meu time',
              slots: [meuSlot1, meuSlot2, meuSlot3],
              onTapSlots: [
                () => escolherPersonagem(
                  titulo: 'Meu time - Slot 1',
                  onEscolhido: (personagem) => meuSlot1 = personagem,
                ),
                () => escolherPersonagem(
                  titulo: 'Meu time - Slot 2',
                  onEscolhido: (personagem) => meuSlot2 = personagem,
                ),
                () => escolherPersonagem(
                  titulo: 'Meu time - Slot 3',
                  onEscolhido: (personagem) => meuSlot3 = personagem,
                ),
              ],
            ),
            const SizedBox(height: 24),
            construirSecaoTime(
              titulo: 'Time adversário',
              slots: [adversarioSlot1, adversarioSlot2, adversarioSlot3],
              onTapSlots: [
                () => escolherPersonagem(
                  titulo: 'Time adversário - Slot 1',
                  onEscolhido: (personagem) => adversarioSlot1 = personagem,
                ),
                () => escolherPersonagem(
                  titulo: 'Time adversário - Slot 2',
                  onEscolhido: (personagem) => adversarioSlot2 = personagem,
                ),
                () => escolherPersonagem(
                  titulo: 'Time adversário - Slot 3',
                  onEscolhido: (personagem) => adversarioSlot3 = personagem,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Adversário',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            construirAutocompletePlayer(),
            const SizedBox(height: 24),
            DatePickerField(
              label: 'Data da partida',
              data: dataPartida,
              onChanged: (valor) {
                setState(() {
                  dataPartida = valor;
                });
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Resultado',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Vitória', label: Text('Vitória')),
                ButtonSegment(value: 'Derrota', label: Text('Derrota')),
              ],
              selected: {resultado},
              onSelectionChanged: (valor) {
                setState(() {
                  resultado = valor.first;
                  lpCalculado = gerarLp();
                });
              },
            ),
            const SizedBox(height: 24),
            if (vitoria)
              SearchableOptionField(
                label: 'Como venceu',
                value: condicaoVitoria,
                options: condicoesVitoriaInvincible,
                icon: Icons.emoji_events_outlined,
                onChanged: (valor) {
                  setState(() {
                    condicaoVitoria = valor;
                    lpCalculado = gerarLp();
                  });
                },
              )
            else
              SearchableOptionField(
                label: 'Como perdeu',
                value: motivoDerrota,
                options: motivosDerrotaInvincible,
                icon: Icons.report_problem_outlined,
                onChanged: (valor) {
                  setState(() {
                    motivoDerrota = valor;
                    lpCalculado = gerarLp();
                  });
                },
              ),
            const SizedBox(height: 18),
            SearchableOptionField(
              label: 'Personagem destaque',
              value: opcoesMeuTime.contains(personagemDestaque)
                  ? personagemDestaque
                  : opcoesMeuTime.first,
              options: opcoesMeuTime,
              icon: Icons.star_outline,
              onChanged: (valor) {
                if (!nomesMeuTime.contains(valor)) return;
                setState(() {
                  personagemDestaque = valor;
                });
              },
            ),
            const SizedBox(height: 14),
            SearchableOptionField(
              label: 'Primeiro derrotado',
              value: opcoesMeuTime.contains(primeiroDerrotado)
                  ? primeiroDerrotado
                  : opcoesMeuTime.first,
              options: opcoesMeuTime,
              icon: Icons.health_and_safety_outlined,
              onChanged: (valor) {
                if (!nomesMeuTime.contains(valor)) return;
                setState(() {
                  primeiroDerrotado = valor;
                });
              },
            ),
            const SizedBox(height: 14),
            SearchableOptionField(
              label: 'Personagem inimigo problema',
              value: opcoesInimigos.contains(personagemInimigoProblema)
                  ? personagemInimigoProblema
                  : opcoesInimigos.first,
              options: opcoesInimigos,
              icon: Icons.priority_high_outlined,
              onChanged: (valor) {
                if (!nomesTimeAdversario.contains(valor)) return;
                setState(() {
                  personagemInimigoProblema = valor;
                });
              },
            ),
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
                hintText:
                    'Ex: erro de tag, assist decisivo, personagem âncora virou o round...',
              ),
              onChanged: (valor) {
                observacoes = valor;
              },
            ),
            const SizedBox(height: 28),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(Icons.trending_up),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'LP calculado: $sinalLp$lpCalculado',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
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
                    onPressed: calcularLp,
                    child: const Text('Calcular LP'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: salvarPartida,
                    child: Text(editando ? 'Salvar edição' : 'Salvar partida'),
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

class _InvincibleCharacterSlot extends StatelessWidget {
  final String label;
  final Character? personagem;
  final String jogo;
  final VoidCallback onTap;

  const _InvincibleCharacterSlot({
    required this.label,
    required this.personagem,
    required this.jogo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Character? personagemSelecionado = personagem;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 116),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 10),
            Row(
              children: [
                if (personagemSelecionado == null)
                  CircleAvatar(
                    radius: 26,
                    child: Text(label.replaceAll('Slot ', '')),
                  )
                else
                  CharacterAvatar(
                    personagem: personagemSelecionado.name,
                    jogo: jogo,
                    size: 52,
                    initialOverride: personagemSelecionado.initial,
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    personagemSelecionado?.name ?? 'Escolher',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const Icon(Icons.search),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
