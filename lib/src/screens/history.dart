part of '../../main.dart';

class HistoricoPage extends StatefulWidget {
  final List<PartidaRegistrada> historico;
  final Character personagemAtual;
  final String jogo;
  final TimePrincipalInvincible timePrincipalInvincible;
  final Map<String, String> smashCoverPreferences;
  final Future<void> Function()? onHistoricoAlterado;

  const HistoricoPage({
    super.key,
    required this.historico,
    required this.personagemAtual,
    this.jogo = 'Super Smash Bros. Ultimate',
    this.timePrincipalInvincible = timePrincipalInvincibleVazio,
    this.smashCoverPreferences = const {},
    this.onHistoricoAlterado,
  });

  @override
  State<HistoricoPage> createState() => _HistoricoPageState();
}

class _HistoricoPageState extends State<HistoricoPage> {
  String filtroResultado = 'Todos';
  String busca = '';
  bool houveAlteracao = false;

  String filtroPlayer = 'Todos';
  String filtroPersonagemAdversario = 'Todos';
  String filtroStage = 'Todos';
  String filtroKill = 'Todos';
  String filtroMorte = 'Todos';
  String filtroMeuPersonagem = 'Todos';
  String filtroInimigoPersonagem = 'Todos';
  String filtroMinhaComposicao = 'Todos';
  String filtroComposicaoInimiga = 'Todos';
  String filtroDestaque = 'Todos';
  String filtroPrimeiroDerrotado = 'Todos';
  String filtroInimigoProblema = 'Todos';
  String filtroCondicaoVitoria = 'Todos';
  String filtroMotivoDerrota = 'Todos';
  String filtroPlacarStreetFighter = 'Todos';

  bool get isInvincible {
    return widget.jogo == jogoInvincibleVs;
  }

  bool get isStreetFighter {
    return widget.jogo == jogoStreetFighter6;
  }

  List<PartidaRegistrada> get historicoDoJogo {
    return filtrarHistoricoPorContextoAtual(
      widget.historico,
      jogo: widget.jogo,
      personagemAtual: widget.personagemAtual.name,
      timePrincipalInvincible: widget.timePrincipalInvincible,
    );
  }

  List<String> get opcoesPlayers {
    return gerarOpcoesFiltro(
      historicoDoJogo.map((partida) => partida.nickAdversario).toList(),
    );
  }

  List<String> get opcoesPersonagensAdversarios {
    return gerarOpcoesFiltro(
      historicoDoJogo.map((partida) => partida.personagemAdversario).toList(),
    );
  }

  List<String> get opcoesStages {
    return gerarOpcoesFiltro(
      historicoDoJogo.map((partida) => partida.stage).toList(),
    );
  }

  List<String> get opcoesKills {
    return gerarOpcoesFiltro(
      historicoDoJogo.map((partida) => partida.formaDeKill).toList(),
    );
  }

  List<String> get opcoesMortes {
    return gerarOpcoesFiltro(
      historicoDoJogo.map((partida) => partida.formaDeMorte).toList(),
    );
  }

  List<String> get opcoesMeuTimePersonagens {
    return gerarOpcoesFiltro(
      historicoDoJogo.expand((partida) => partida.meuTime).toList(),
    );
  }

  List<String> get opcoesInimigosPersonagens {
    return gerarOpcoesFiltro(
      historicoDoJogo.expand((partida) => partida.timeAdversario).toList(),
    );
  }

  List<String> get opcoesMinhasComposicoes {
    return gerarOpcoesFiltro(
      historicoDoJogo.map((partida) => partida.meuTimeTexto).toList(),
    );
  }

  List<String> get opcoesComposicoesInimigas {
    return gerarOpcoesFiltro(
      historicoDoJogo.map((partida) => partida.timeAdversarioTexto).toList(),
    );
  }

  List<String> get opcoesDestaques {
    return gerarOpcoesFiltro(
      historicoDoJogo.map((partida) => partida.personagemDestaque).toList(),
    );
  }

  List<String> get opcoesPrimeirosDerrotados {
    return gerarOpcoesFiltro(
      historicoDoJogo.map((partida) => partida.primeiroDerrotado).toList(),
    );
  }

  List<String> get opcoesInimigosProblema {
    return gerarOpcoesFiltro(
      historicoDoJogo
          .map((partida) => partida.personagemInimigoProblema)
          .toList(),
    );
  }

  List<String> get opcoesCondicoesVitoria {
    return gerarOpcoesFiltro(
      historicoDoJogo.map((partida) => partida.condicaoVitoria).toList(),
    );
  }

  List<String> get opcoesMotivosDerrota {
    return gerarOpcoesFiltro(
      historicoDoJogo.map((partida) => partida.motivoDerrota).toList(),
    );
  }

  List<String> get opcoesPlacaresStreetFighter {
    return gerarOpcoesFiltro(
      historicoDoJogo.map((partida) => partida.placarStreetFighter).toList(),
    );
  }

  bool get filtrosAvancadosAtivos {
    return filtroPlayer != 'Todos' ||
        filtroPersonagemAdversario != 'Todos' ||
        filtroStage != 'Todos' ||
        filtroKill != 'Todos' ||
        filtroMorte != 'Todos' ||
        filtroMeuPersonagem != 'Todos' ||
        filtroInimigoPersonagem != 'Todos' ||
        filtroMinhaComposicao != 'Todos' ||
        filtroComposicaoInimiga != 'Todos' ||
        filtroDestaque != 'Todos' ||
        filtroPrimeiroDerrotado != 'Todos' ||
        filtroInimigoProblema != 'Todos' ||
        filtroCondicaoVitoria != 'Todos' ||
        filtroMotivoDerrota != 'Todos' ||
        filtroPlacarStreetFighter != 'Todos';
  }

  List<PartidaRegistrada> get historicoFiltrado {
    return historicoDoJogo.where((partida) {
      final bool passaResultado =
          filtroResultado == 'Todos' || partida.resultado == filtroResultado;

      final bool passaPlayer =
          filtroPlayer == 'Todos' || partida.nickAdversario == filtroPlayer;

      final bool passaAdversario =
          isInvincible ||
          filtroPersonagemAdversario == 'Todos' ||
          partida.personagemAdversario == filtroPersonagemAdversario;

      final bool passaStage =
          isInvincible ||
          filtroStage == 'Todos' ||
          partida.stage == filtroStage;

      final bool passaKill =
          isInvincible ||
          filtroKill == 'Todos' ||
          partida.formaDeKill == filtroKill;

      final bool passaMorte =
          isInvincible ||
          filtroMorte == 'Todos' ||
          partida.formaDeMorte == filtroMorte;

      final bool passaMeuPersonagem =
          !isInvincible ||
          filtroMeuPersonagem == 'Todos' ||
          partida.meuTime.contains(filtroMeuPersonagem);

      final bool passaInimigoPersonagem =
          !isInvincible ||
          filtroInimigoPersonagem == 'Todos' ||
          partida.timeAdversario.contains(filtroInimigoPersonagem);

      final bool passaMinhaComposicao =
          !isInvincible ||
          filtroMinhaComposicao == 'Todos' ||
          partida.meuTimeTexto == filtroMinhaComposicao;

      final bool passaComposicaoInimiga =
          !isInvincible ||
          filtroComposicaoInimiga == 'Todos' ||
          partida.timeAdversarioTexto == filtroComposicaoInimiga;

      final bool passaDestaque =
          !isInvincible ||
          filtroDestaque == 'Todos' ||
          partida.personagemDestaque == filtroDestaque;

      final bool passaPrimeiroDerrotado =
          !isInvincible ||
          filtroPrimeiroDerrotado == 'Todos' ||
          partida.primeiroDerrotado == filtroPrimeiroDerrotado;

      final bool passaInimigoProblema =
          !isInvincible ||
          filtroInimigoProblema == 'Todos' ||
          partida.personagemInimigoProblema == filtroInimigoProblema;

      final bool passaCondicaoVitoria =
          !isInvincible ||
          filtroCondicaoVitoria == 'Todos' ||
          partida.condicaoVitoria == filtroCondicaoVitoria;

      final bool passaMotivoDerrota =
          !isInvincible ||
          filtroMotivoDerrota == 'Todos' ||
          partida.motivoDerrota == filtroMotivoDerrota;

      final bool passaPlacarStreetFighter =
          !isStreetFighter ||
          filtroPlacarStreetFighter == 'Todos' ||
          partida.placarStreetFighter == filtroPlacarStreetFighter;

      final textoBusca = busca.trim().toLowerCase();

      final String textoPartida = isInvincible
          ? [
              partida.nickAdversario,
              partida.meuTimeTexto,
              partida.timeAdversarioTexto,
              partida.personagemDestaque,
              partida.primeiroDerrotado,
              partida.personagemInimigoProblema,
              partida.condicaoVitoria,
              partida.motivoDerrota,
              partida.observacoes,
            ].join(' ')
          : isStreetFighter
          ? [
              partida.nickAdversario,
              partida.personagemAdversario,
              partida.personagemJogador,
              partida.resultado,
              partida.placarStreetFighter,
              partida.round1Resultado,
              partida.round2Resultado,
              partida.round3Resultado,
              partida.observacoes,
            ].join(' ')
          : [
              partida.nickAdversario,
              partida.personagemAdversario,
              partida.stage,
              partida.personagemJogador,
              partida.formaDeKill,
              partida.formaDeMorte,
              partida.observacoes,
            ].join(' ');

      final bool passaBusca =
          textoBusca.isEmpty || textoPartida.toLowerCase().contains(textoBusca);

      return passaResultado &&
          passaPlayer &&
          passaAdversario &&
          passaStage &&
          passaKill &&
          passaMorte &&
          passaMeuPersonagem &&
          passaInimigoPersonagem &&
          passaMinhaComposicao &&
          passaComposicaoInimiga &&
          passaDestaque &&
          passaPrimeiroDerrotado &&
          passaInimigoProblema &&
          passaCondicaoVitoria &&
          passaMotivoDerrota &&
          passaPlacarStreetFighter &&
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
      filtroMeuPersonagem = 'Todos';
      filtroInimigoPersonagem = 'Todos';
      filtroMinhaComposicao = 'Todos';
      filtroComposicaoInimiga = 'Todos';
      filtroDestaque = 'Todos';
      filtroPrimeiroDerrotado = 'Todos';
      filtroInimigoProblema = 'Todos';
      filtroCondicaoVitoria = 'Todos';
      filtroMotivoDerrota = 'Todos';
      filtroPlacarStreetFighter = 'Todos';
    });
  }

  Widget construirDropdownFiltro({
    required String label,
    required String valor,
    required List<String> opcoes,
    required ValueChanged<String> onChanged,
  }) {
    final String valorSeguro = opcoes.contains(valor) ? valor : 'Todos';

    return SearchableOptionField(
      label: label,
      value: valorSeguro,
      options: opcoes,
      onChanged: onChanged,
    );
  }

  Future<void> abrirDetalhes(PartidaRegistrada partida) async {
    final ResultadoDetalhesPartida? resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetalhesPartidaPage(
          partida: partida,
          jogo: widget.jogo,
          sugestoesPlayers: gerarSugestoesPlayers(historicoDoJogo),
          smashCoverPreferences: widget.smashCoverPreferences,
        ),
      ),
    );

    if (resultado == null) return;

    if (resultado.acao == 'apagar') {
      setState(() {
        widget.historico.remove(partida);
        houveAlteracao = true;
      });
      await widget.onHistoricoAlterado?.call();
    }

    if (resultado.acao == 'editar' && resultado.partidaEditada != null) {
      final int index = widget.historico.indexOf(partida);

      if (index != -1) {
        setState(() {
          widget.historico[index] = resultado.partidaEditada!;
          houveAlteracao = true;
        });
        await widget.onHistoricoAlterado?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final partidas = historicoFiltrado;
    final String pontosLabel = labelPontosRank(widget.jogo);

    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, houveAlteracao);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const CompactAppBarTitle('Histórico de partidas'),
          centerTitle: true,
          actions: const [HomeNavigationButton()],
        ),
        body: historicoDoJogo.isEmpty
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
                          decoration: InputDecoration(
                            labelText: 'Buscar no histórico',
                            hintText: isInvincible
                                ? 'Nick, personagem, composição, condição, motivo ou observação...'
                                : 'Nick, personagem, stage, kill, morte ou observação...',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.search),
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
                            ButtonSegment(value: 'Todos', label: Text('Todos')),
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
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.history_outlined),
                            title: Text(
                              isInvincible
                                  ? 'Histórico do time atual'
                                  : 'Histórico de ${widget.personagemAtual.name}',
                            ),
                            subtitle: Text(
                              isInvincible
                                  ? widget.timePrincipalInvincible.texto
                                  : widget.jogo,
                            ),
                          ),
                        ),
                        Card(
                          child: ExpansionTile(
                            initiallyExpanded: filtrosAvancadosAtivos,
                            leading: const Icon(Icons.filter_alt_outlined),
                            title: const Text('Filtros avançados'),
                            subtitle: Text(
                              filtrosAvancadosAtivos
                                  ? 'Filtros específicos ativos'
                                  : isInvincible
                                  ? 'Player, times, personagens e análise'
                                  : isStreetFighter
                                  ? 'Player, personagem adversário e placar'
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
                              if (isInvincible) ...[
                                construirDropdownFiltro(
                                  label: 'Personagem do meu time',
                                  valor: filtroMeuPersonagem,
                                  opcoes: opcoesMeuTimePersonagens,
                                  onChanged: (valor) {
                                    setState(() {
                                      filtroMeuPersonagem = valor;
                                    });
                                  },
                                ),
                                const SizedBox(height: 12),
                                construirDropdownFiltro(
                                  label: 'Personagem inimigo',
                                  valor: filtroInimigoPersonagem,
                                  opcoes: opcoesInimigosPersonagens,
                                  onChanged: (valor) {
                                    setState(() {
                                      filtroInimigoPersonagem = valor;
                                    });
                                  },
                                ),
                                const SizedBox(height: 12),
                                construirDropdownFiltro(
                                  label: 'Composição do meu time',
                                  valor: filtroMinhaComposicao,
                                  opcoes: opcoesMinhasComposicoes,
                                  onChanged: (valor) {
                                    setState(() {
                                      filtroMinhaComposicao = valor;
                                    });
                                  },
                                ),
                                const SizedBox(height: 12),
                                construirDropdownFiltro(
                                  label: 'Composição adversária',
                                  valor: filtroComposicaoInimiga,
                                  opcoes: opcoesComposicoesInimigas,
                                  onChanged: (valor) {
                                    setState(() {
                                      filtroComposicaoInimiga = valor;
                                    });
                                  },
                                ),
                                const SizedBox(height: 12),
                                construirDropdownFiltro(
                                  label: 'Personagem destaque',
                                  valor: filtroDestaque,
                                  opcoes: opcoesDestaques,
                                  onChanged: (valor) {
                                    setState(() {
                                      filtroDestaque = valor;
                                    });
                                  },
                                ),
                                const SizedBox(height: 12),
                                construirDropdownFiltro(
                                  label: 'Primeiro derrotado',
                                  valor: filtroPrimeiroDerrotado,
                                  opcoes: opcoesPrimeirosDerrotados,
                                  onChanged: (valor) {
                                    setState(() {
                                      filtroPrimeiroDerrotado = valor;
                                    });
                                  },
                                ),
                                const SizedBox(height: 12),
                                construirDropdownFiltro(
                                  label: 'Inimigo problema',
                                  valor: filtroInimigoProblema,
                                  opcoes: opcoesInimigosProblema,
                                  onChanged: (valor) {
                                    setState(() {
                                      filtroInimigoProblema = valor;
                                    });
                                  },
                                ),
                                const SizedBox(height: 12),
                                construirDropdownFiltro(
                                  label: 'Condição de vitória',
                                  valor: filtroCondicaoVitoria,
                                  opcoes: opcoesCondicoesVitoria,
                                  onChanged: (valor) {
                                    setState(() {
                                      filtroCondicaoVitoria = valor;
                                    });
                                  },
                                ),
                                const SizedBox(height: 12),
                                construirDropdownFiltro(
                                  label: 'Motivo de derrota',
                                  valor: filtroMotivoDerrota,
                                  opcoes: opcoesMotivosDerrota,
                                  onChanged: (valor) {
                                    setState(() {
                                      filtroMotivoDerrota = valor;
                                    });
                                  },
                                ),
                              ] else if (isStreetFighter) ...[
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
                                  label: 'Placar',
                                  valor: filtroPlacarStreetFighter,
                                  opcoes: opcoesPlacaresStreetFighter,
                                  onChanged: (valor) {
                                    setState(() {
                                      filtroPlacarStreetFighter = valor;
                                    });
                                  },
                                ),
                              ] else ...[
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
                              ],
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
                            final bool venceu = resultadoEhVitoria(
                              partida.resultado,
                            );
                            final String sinalPontos = partida.pdlGerado >= 0
                                ? '+'
                                : '';

                            if (isInvincible) {
                              final String analiseLabel = venceu
                                  ? 'Como venceu'
                                  : 'Como perdeu';
                              final String observacoes =
                                  partida.observacoes.trim().isEmpty
                                  ? ''
                                  : '\nObs: ${partida.observacoes}';

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
                                    partida.meuTimeTexto,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${partida.resultado} • Contra ${partida.nickAdversario}\n'
                                    'Inimigos: ${partida.timeAdversarioTexto}\n'
                                    'Destaque: ${partida.personagemDestaque} • Primeiro derrotado: ${partida.primeiroDerrotado}\n'
                                    '$analiseLabel: ${partida.analiseResultado}$observacoes',
                                  ),
                                  trailing: Text(
                                    '$sinalPontos${partida.pdlGerado} $pontosLabel',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              );
                            }

                            if (isStreetFighter || partida.isStreetFighter) {
                              final String round3Texto =
                                  partida.round3Resultado.trim().isEmpty
                                  ? ''
                                  : '\nRound 3: ${partida.round3Resultado}';

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
                                    'Resultado Final: ${partida.resultado} ${partida.placarStreetFighter}\n'
                                    'Jogador: ${partida.nickAdversario} • Round 1: ${partida.round1Resultado} • Round 2: ${partida.round2Resultado}$round3Texto',
                                  ),
                                  trailing: Text(
                                    '$sinalPontos${partida.pdlGerado} $pontosLabel',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              );
                            }

                            final String labelStocksHistorico = venceu
                                ? 'Suas stocks'
                                : 'Stocks do adversário';

                            final String labelPorcentagemHistorico = venceu
                                ? 'Sua %'
                                : '% do adversário';

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
                                  '$sinalPontos${partida.pdlGerado} $pontosLabel',
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
  final List<String> sugestoesPlayers;
  final Map<String, String> smashCoverPreferences;

  const DetalhesPartidaPage({
    super.key,
    required this.partida,
    this.jogo = 'Super Smash Bros. Ultimate',
    this.sugestoesPlayers = const [],
    this.smashCoverPreferences = const {},
  });

  Future<void> confirmarApagar(BuildContext context) async {
    final String pontosLabel = labelPontosRank(jogo);
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Apagar partida?'),
          content: Text(
            'Essa ação vai remover a partida do histórico e recalcular o $pontosLabel do personagem.',
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

    if (!context.mounted) return;

    if (confirmar == true) {
      Navigator.pop(context, const ResultadoDetalhesPartida.apagar());
    }
  }

  Future<void> abrirEditar(BuildContext context) async {
    final PartidaRegistrada? partidaEditada = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          if (partida.isInvincible || jogo == jogoInvincibleVs) {
            return RegistrarPartidaInvinciblePage(
              jogo: jogoInvincibleVs,
              sugestoesPlayers: sugestoesPlayers,
              partidaInicial: partida,
            );
          }

          if (partida.isStreetFighter || jogo == jogoStreetFighter6) {
            return RegistrarPartidaStreetFighterPage(
              personagemAtual: personagemPorNome(partida.personagemJogador),
              jogo: jogoStreetFighter6,
              sugestoesPlayers: sugestoesPlayers,
              partidaInicial: partida,
            );
          }

          return EditarPartidaPage(
            partida: partida,
            jogo: jogo,
            sugestoesPlayers: sugestoesPlayers,
            smashCoverPreferences: smashCoverPreferences,
          );
        },
      ),
    );

    if (!context.mounted) return;

    if (partidaEditada != null) {
      Navigator.pop(context, ResultadoDetalhesPartida.editar(partidaEditada));
    }
  }

  Widget construirDetalhesInvincible(BuildContext context) {
    final bool venceu = partida.resultado == 'Vitória';
    final String sinalLp = partida.pdlGerado >= 0 ? '+' : '';
    final String analiseLabel = venceu ? 'Como venceu' : 'Como perdeu';
    final String textoObservacoes = partida.observacoes.trim().isEmpty
        ? 'Sem observações'
        : partida.observacoes;

    return Scaffold(
      appBar: AppBar(
        title: const CompactAppBarTitle('Detalhes da partida'),
        centerTitle: true,
        actions: [
          const HomeNavigationButton(),
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
              partida.meuTimeTexto,
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
                      titulo: 'LP gerado',
                      valor: '$sinalLp${partida.pdlGerado}',
                    ),
                    LinhaEstatistica(
                      titulo: 'Meu time',
                      valor: partida.meuTimeTexto,
                    ),
                    LinhaEstatistica(
                      titulo: 'Time adversário',
                      valor: partida.timeAdversarioTexto,
                    ),
                    LinhaEstatistica(
                      titulo: 'Personagem destaque',
                      valor: partida.personagemDestaque,
                    ),
                    LinhaEstatistica(
                      titulo: 'Primeiro derrotado',
                      valor: partida.primeiroDerrotado,
                    ),
                    LinhaEstatistica(
                      titulo: 'Inimigo problema',
                      valor: partida.personagemInimigoProblema,
                    ),
                    LinhaEstatistica(
                      titulo: analiseLabel,
                      valor: partida.analiseResultado,
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

  Widget construirDetalhesStreetFighter(BuildContext context) {
    final String sinalPdl = partida.pdlGerado >= 0 ? '+' : '';
    final String textoObservacoes = partida.observacoes.trim().isEmpty
        ? 'Sem observações'
        : partida.observacoes;
    final String round3Texto = partida.round3Resultado.trim().isEmpty
        ? 'Não jogado'
        : partida.round3Resultado;

    return Scaffold(
      appBar: AppBar(
        title: const CompactAppBarTitle('Detalhes da partida'),
        centerTitle: true,
        actions: [
          const HomeNavigationButton(),
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
                      titulo: 'Resultado Final',
                      valor:
                          '${partida.resultado} ${partida.placarStreetFighter}',
                    ),
                    LinhaEstatistica(
                      titulo: 'PDL gerado',
                      valor: '$sinalPdl${partida.pdlGerado}',
                    ),
                    LinhaEstatistica(
                      titulo: 'Meu Personagem',
                      valor: partida.personagemJogador,
                    ),
                    LinhaEstatistica(
                      titulo: 'Personagem Adversário',
                      valor: partida.personagemAdversario,
                    ),
                    LinhaEstatistica(
                      titulo: 'Jogador Adversário',
                      valor: partida.nickAdversario,
                    ),
                    LinhaEstatistica(
                      titulo: 'Round 1',
                      valor: partida.round1Resultado,
                    ),
                    LinhaEstatistica(
                      titulo: 'Round 2',
                      valor: partida.round2Resultado,
                    ),
                    LinhaEstatistica(titulo: 'Round 3', valor: round3Texto),
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

  @override
  Widget build(BuildContext context) {
    if (partida.isInvincible || jogo == jogoInvincibleVs) {
      return construirDetalhesInvincible(context);
    }

    if (partida.isStreetFighter || jogo == jogoStreetFighter6) {
      return construirDetalhesStreetFighter(context);
    }

    final bool venceu = partida.resultado == 'Vitória';
    final String sinalPdl = partida.pdlGerado >= 0 ? '+' : '';

    final String labelStocks = venceu
        ? 'Suas stocks restantes'
        : 'Stocks restantes do adversário';

    final String labelPorcentagem = venceu
        ? 'Sua porcentagem final'
        : 'Porcentagem final do adversário';

    final String textoObservacoes = partida.observacoes.trim().isEmpty
        ? 'Sem observações'
        : partida.observacoes;

    return Scaffold(
      appBar: AppBar(
        title: const CompactAppBarTitle('Detalhes da partida'),
        centerTitle: true,
        actions: [
          const HomeNavigationButton(),
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
                    LinhaEstatistica(titulo: 'Stage', valor: partida.stage),
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
  final List<String> sugestoesPlayers;
  final Map<String, String> smashCoverPreferences;

  const EditarPartidaPage({
    super.key,
    required this.partida,
    this.jogo = 'Super Smash Bros. Ultimate',
    this.sugestoesPlayers = const [],
    this.smashCoverPreferences = const {},
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
  late String detalheOutroKill;
  late String detalheOutroMorte;
  late String observacoes;
  late DateTime dataPartida;
  late int pdlCalculado;

  late TextEditingController nickController;
  late TextEditingController porcentagemController;
  late TextEditingController outroKillController;
  late TextEditingController outroMorteController;
  late TextEditingController observacoesController;

  @override
  void initState() {
    super.initState();

    personagemJogador = personagemPorNome(widget.partida.personagemJogador);
    personagemAdversario = personagemPorNome(
      widget.partida.personagemAdversario,
    );

    resultado = widget.partida.resultado;
    nickAdversario = widget.partida.nickAdversario;
    stageSelecionado = stagesSmash.contains(widget.partida.stage)
        ? widget.partida.stage
        : stagesSmash[0];
    stocks = widget.partida.stocks;
    porcentagem = widget.partida.porcentagem;

    if (formasDeKill.contains(widget.partida.formaDeKill)) {
      formaDeKill = widget.partida.formaDeKill;
      detalheOutroKill = '';
    } else {
      formaDeKill = 'Outro';
      detalheOutroKill = widget.partida.formaDeKill == 'Não matou'
          ? ''
          : widget.partida.formaDeKill;
    }

    if (formasDeMorte.contains(widget.partida.formaDeMorte)) {
      formaDeMorte = widget.partida.formaDeMorte;
      detalheOutroMorte = '';
    } else {
      formaDeMorte = 'Outro';
      detalheOutroMorte = widget.partida.formaDeMorte == 'Não morreu'
          ? ''
          : widget.partida.formaDeMorte;
    }

    observacoes = widget.partida.observacoes;
    dataPartida = widget.partida.data;
    pdlCalculado = gerarPdl();

    nickController = TextEditingController(text: nickAdversario);
    porcentagemController = TextEditingController(text: porcentagem.toString());
    outroKillController = TextEditingController(text: detalheOutroKill);
    outroMorteController = TextEditingController(text: detalheOutroMorte);
    observacoesController = TextEditingController(text: observacoes);
  }

  @override
  void dispose() {
    nickController.dispose();
    porcentagemController.dispose();
    outroKillController.dispose();
    outroMorteController.dispose();
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
    return calcularPdlDaPartida(
      resultado: resultado,
      stocks: stocks,
      porcentagem: porcentagem,
      formaDeKill: killInformada,
      formaDeMorte: morteInformada,
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
    final String killFinal = killInformada;
    final String morteFinal = morteInformada;

    final PartidaRegistrada partidaEditada = PartidaRegistrada(
      jogo: widget.jogo,
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
      data: dataPartida,
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
        title: const CompactAppBarTitle('Editar partida'),
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
                      smashCoverPreferences: widget.smashCoverPreferences,
                      usarPreferenciaVisualSmash: true,
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
                      child: const Text('Trocar'),
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
              value: stagesSmash.contains(stageSelecionado)
                  ? stageSelecionado
                  : stagesSmash[0],
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
                  controller: outroKillController,
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
                  controller: outroMorteController,
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
