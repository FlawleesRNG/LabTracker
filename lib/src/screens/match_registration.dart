part of '../../main.dart';

class RegistrarPartidaPage extends StatefulWidget {
  final Character personagemAtual;
  final String jogo;
  final List<String> sugestoesPlayers;

  const RegistrarPartidaPage({
    super.key,
    required this.personagemAtual,
    this.jogo = 'Super Smash Bros. Ultimate',
    this.sugestoesPlayers = const [],
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
      data: DateTime.now(),
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
      appBar: AppBar(title: const Text('Registrar partida'), centerTitle: true),
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
            const Text(
              'Stage / Mapa',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SearchableOptionField(
              label: 'Pesquisar mapa',
              value: stageSelecionado,
              options: stagesSmash,
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
              value: stocks,
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
                options: formasDeKill,
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
                options: formasDeMorte,
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

class RegistrarPartidaStreetFighterPage extends StatefulWidget {
  final Character personagemAtual;
  final String jogo;
  final List<String> sugestoesPlayers;
  final PartidaRegistrada? partidaInicial;

  const RegistrarPartidaStreetFighterPage({
    super.key,
    required this.personagemAtual,
    this.jogo = jogoStreetFighter6,
    this.sugestoesPlayers = const [],
    this.partidaInicial,
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
    return widget.partidaInicial != null;
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

  String get dataPartidaTexto {
    String doisDigitos(int numero) => numero.toString().padLeft(2, '0');

    return '${doisDigitos(dataPartida.day)}/'
        '${doisDigitos(dataPartida.month)}/${dataPartida.year}';
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

  Future<void> escolherDataPartida() async {
    final DateTime? dataEscolhida = await showDatePicker(
      context: context,
      initialDate: dataPartida,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (dataEscolhida == null) return;

    setState(() {
      dataPartida = DateTime(
        dataEscolhida.year,
        dataEscolhida.month,
        dataEscolhida.day,
        dataPartida.hour,
        dataPartida.minute,
      );
    });
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
              child: Text(editando ? 'Concluir edição' : 'Voltar para Home'),
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
        title: Text(editando ? 'Editar partida' : 'Registrar Partida'),
        centerTitle: true,
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
            const Text(
              'Data da partida',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.event_outlined),
                title: Text(dataPartidaTexto),
                trailing: OutlinedButton(
                  onPressed: escolherDataPartida,
                  child: const Text('Alterar'),
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

class RegistrarPartidaInvinciblePage extends StatefulWidget {
  final String jogo;
  final List<String> sugestoesPlayers;
  final PartidaRegistrada? partidaInicial;
  final TimePrincipalInvincible? timePrincipal;

  const RegistrarPartidaInvinciblePage({
    super.key,
    this.jogo = jogoInvincibleVs,
    this.sugestoesPlayers = const [],
    this.partidaInicial,
    this.timePrincipal,
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
    return widget.partidaInicial != null;
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
      meuSlot1 = encontrarPersonagemInvincible(partida.meuTimeSlot1);
      meuSlot2 = encontrarPersonagemInvincible(partida.meuTimeSlot2);
      meuSlot3 = encontrarPersonagemInvincible(partida.meuTimeSlot3);
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

  String get dataPartidaTexto {
    String doisDigitos(int numero) => numero.toString().padLeft(2, '0');

    return '${doisDigitos(dataPartida.day)}/'
        '${doisDigitos(dataPartida.month)}/${dataPartida.year}';
  }

  Future<void> escolherDataPartida() async {
    final DateTime? dataEscolhida = await showDatePicker(
      context: context,
      initialDate: dataPartida,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (dataEscolhida == null) return;

    setState(() {
      dataPartida = DateTime(
        dataEscolhida.year,
        dataEscolhida.month,
        dataEscolhida.day,
        dataPartida.hour,
        dataPartida.minute,
      );
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
              child: Text(editando ? 'Concluir edição' : 'Voltar para Home'),
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
        title: Text(editando ? 'Editar partida 3v3' : 'Registrar partida 3v3'),
        centerTitle: true,
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
            const Text(
              'Data da partida',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.event_outlined),
                title: Text(dataPartidaTexto),
                trailing: OutlinedButton(
                  onPressed: escolherDataPartida,
                  child: const Text('Alterar'),
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
