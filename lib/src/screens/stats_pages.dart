part of '../../main.dart';

class ResumoTreinoPage extends StatelessWidget {
  final Character personagemAtual;
  final List<PartidaRegistrada> historico;
  final String jogoAtual;
  final Map<String, String> smashCoverPreferences;

  const ResumoTreinoPage({
    super.key,
    required this.personagemAtual,
    required this.historico,
    required this.jogoAtual,
    this.smashCoverPreferences = const {},
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

    final List<PartidaRegistrada> partidasHojePersonagem = historico
        .where(
          (partida) => partidaPertenceAoContextoAtual(
            partida,
            jogo: jogoAtual,
            personagemAtual: personagemAtual.name,
          ),
        )
        .where((partida) => isMesmoDia(partida.data, hoje))
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

    final double winrate = totalPartidas == 0
        ? 0
        : (vitorias / totalPartidas) * 100;

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

    final List<PartidaRegistrada> partidasComObservacoes =
        partidasHojePersonagem
            .where((partida) => partida.observacoes.trim().isNotEmpty)
            .take(5)
            .toList();

    final String sinalPdl = saldoPdl >= 0 ? '+' : '';

    return Scaffold(
      appBar: AppBar(
        title: const CompactAppBarTitle('Resumo do treino'),
        centerTitle: true,
        actions: const [HomeNavigationButton()],
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
                              final String sinalMatchup = matchup.saldoPdl >= 0
                                  ? '+'
                                  : '';

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: MatchupHeader(
                                        jogo: jogoAtual,
                                        personagem: personagemAtual.name,
                                        adversario:
                                            matchup.personagemAdversario,
                                        avatarSize: 26,
                                        smashCoverPreferences:
                                            smashCoverPreferences,
                                        usarPreferenciaVisualSmash: true,
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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
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
  final Map<String, String> smashCoverPreferences;

  const EstatisticasPage({
    super.key,
    required this.personagemAtual,
    required this.historico,
    required this.jogoAtual,
    this.smashCoverPreferences = const {},
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
          smashCoverPreferences: smashCoverPreferences,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<PartidaRegistrada> partidasDoPersonagem = historico
        .where(
          (partida) => partidaPertenceAoContextoAtual(
            partida,
            jogo: jogoAtual,
            personagemAtual: personagemAtual.name,
          ),
        )
        .toList();

    final int totalPartidas = partidasDoPersonagem.length;
    final int vitorias = partidasDoPersonagem
        .where((partida) => partida.resultado == 'Vitória')
        .length;
    final int derrotas = partidasDoPersonagem
        .where((partida) => partida.resultado == 'Derrota')
        .length;

    final double winrate = totalPartidas == 0
        ? 0
        : (vitorias / totalPartidas) * 100;

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

    final double mediaPdl = totalPartidas == 0 ? 0 : saldoPdl / totalPartidas;

    final List<PlayerResumo> rankingPlayers = gerarRankingPlayers(
      partidasDoPersonagem,
    );

    final List<MatchupResumo> rankingMatchups = gerarRankingMatchups(
      partidasDoPersonagem,
    );

    final String nickMaisEnfrentado = rankingPlayers.isEmpty
        ? 'Sem dados'
        : rankingPlayers.first.nick;

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
    final MatchupResumo? piorMatchup = piorMatchupPorWinrate(rankingMatchups);
    final MatchupResumo? maiorGanho = maiorGanhoPdlPorMatchup(rankingMatchups);
    final MatchupResumo? maiorPerda = maiorPerdaPdlPorMatchup(rankingMatchups);

    final String nomePiorMatchup =
        piorMatchup?.personagemAdversario ?? 'Sem dados';
    final String focoAutomatico = gerarFocoAutomatico(
      morteMaisComum,
      nomePiorMatchup,
    );

    final List<PartidaRegistrada> ultimasPartidas = partidasDoPersonagem
        .take(5)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const CompactAppBarTitle('Estatísticas'),
        centerTitle: true,
        actions: const [HomeNavigationButton()],
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
                            'Leitura de desempenho',
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
                  AnalisesSection(
                    personagemAtual: personagemAtual,
                    historico: partidasDoPersonagem,
                    jogoAtual: jogoAtual,
                    smashCoverPreferences: smashCoverPreferences,
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
                            final String sinalPdl = partida.pdlGerado >= 0
                                ? '+'
                                : '';

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
                                    smashCoverPreferences:
                                        smashCoverPreferences,
                                    usarPreferenciaVisualSmash: true,
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

class EstatisticasStreetFighterPage extends StatelessWidget {
  final Character personagemAtual;
  final List<PartidaRegistrada> historico;
  final String jogoAtual;

  const EstatisticasStreetFighterPage({
    super.key,
    required this.personagemAtual,
    required this.historico,
    required this.jogoAtual,
  });

  int sequenciaAtual(List<PartidaRegistrada> partidas) {
    if (partidas.isEmpty) return 0;

    final bool sequenciaDeVitoria = resultadoEhVitoria(
      partidas.first.resultado,
    );
    int sequencia = 0;

    for (final partida in partidas) {
      if (resultadoEhVitoria(partida.resultado) == sequenciaDeVitoria) {
        sequencia++;
      } else {
        break;
      }
    }

    return sequenciaDeVitoria ? sequencia : -sequencia;
  }

  String textoSequencia(int sequencia) {
    if (sequencia > 0) return '$sequencia vitória(s)';
    if (sequencia < 0) return '${sequencia.abs()} derrota(s)';
    return 'Sem dados';
  }

  @override
  Widget build(BuildContext context) {
    final List<PartidaRegistrada> partidas = historico
        .where(
          (partida) => partidaPertenceAoContextoAtual(
            partida,
            jogo: jogoAtual,
            personagemAtual: personagemAtual.name,
          ),
        )
        .toList();

    final int totalPartidas = partidas.length;
    final int vitorias = partidas.where((partida) {
      return resultadoEhVitoria(partida.resultado);
    }).length;
    final int derrotas = partidas.where((partida) {
      return resultadoEhDerrota(partida.resultado);
    }).length;
    final double winrate = totalPartidas == 0
        ? 0
        : (vitorias / totalPartidas) * 100;

    final int roundsVencidos = partidas.fold(
      0,
      (soma, partida) => soma + partida.roundsVencidos,
    );
    final int roundsPerdidos = partidas.fold(
      0,
      (soma, partida) => soma + partida.roundsPerdidos,
    );
    final int totalRounds = roundsVencidos + roundsPerdidos;
    final double winrateRounds = totalRounds == 0
        ? 0
        : (roundsVencidos / totalRounds) * 100;

    int contarPlacar(String resultado, String placar) {
      return partidas.where((partida) {
        final bool resultadoConfere = resultado == 'Vitória'
            ? resultadoEhVitoria(partida.resultado)
            : resultadoEhDerrota(partida.resultado);

        return resultadoConfere && partida.placarStreetFighter == placar;
      }).length;
    }

    final int vitorias20 = contarPlacar('Vitória', '2x0');
    final int vitorias21 = contarPlacar('Vitória', '2x1');
    final int derrotas02 = contarPlacar('Derrota', '0x2');
    final int derrotas12 = contarPlacar('Derrota', '1x2');
    final int partidasRound3 = partidas.where((partida) {
      return partida.chegouAoRound3;
    }).length;
    final int vitoriasRound3 = partidas.where((partida) {
      return resultadoEhVitoria(partida.round3Resultado);
    }).length;
    final double aproveitamentoRound3 = partidasRound3 == 0
        ? 0
        : (vitoriasRound3 / partidasRound3) * 100;
    final double mediaRoundsVencidos = totalPartidas == 0
        ? 0
        : roundsVencidos / totalPartidas;

    final int saldoPdl = partidas.fold(
      0,
      (soma, partida) => soma + partida.pdlGerado,
    );
    final double mediaPdl = totalPartidas == 0 ? 0 : saldoPdl / totalPartidas;
    final int sequencia = sequenciaAtual(partidas);

    final List<PlayerResumo> rankingPlayers = gerarRankingPlayers(partidas);
    final List<MatchupResumo> rankingMatchups = gerarRankingMatchups(partidas);
    final List<EvolucaoPdlPonto> evolucaoPdl = gerarEvolucaoPdl(partidas);
    final List<AnaliseComparativaItem> porMatchup = gerarComparativoPorCampo(
      partidas,
      (partida) => partida.personagemAdversario,
    );
    final List<AnaliseComparativaItem> porPlayer = gerarComparativoPorCampo(
      partidas,
      (partida) => partida.nickAdversario,
    );
    final List<FrequenciaItem> placares = gerarRankingFrequencia(
      partidas.map((partida) {
        return '${partida.resultado} ${partida.placarStreetFighter}';
      }).toList(),
    );

    final MatchupResumo? melhorMatchup = melhorMatchupPorWinrate(
      rankingMatchups,
    );
    final MatchupResumo? piorMatchup = piorMatchupPorWinrate(rankingMatchups);

    return Scaffold(
      appBar: AppBar(
        title: const CompactAppBarTitle('Estatísticas Street Fighter'),
        centerTitle: true,
        actions: const [HomeNavigationButton()],
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
                    'Street Fighter 6 • ${personagemAtual.name}',
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
                            titulo: 'Win rate de partidas',
                            valor: '${winrate.toStringAsFixed(1)}%',
                          ),
                          LinhaEstatistica(
                            titulo: 'Saldo de PDL',
                            valor: formatarSaldo(saldoPdl),
                          ),
                          LinhaEstatistica(
                            titulo: 'Média de PDL por partida',
                            valor: mediaPdl >= 0
                                ? '+${mediaPdl.toStringAsFixed(1)}'
                                : mediaPdl.toStringAsFixed(1),
                          ),
                          LinhaEstatistica(
                            titulo: 'Sequência atual',
                            valor: textoSequencia(sequencia),
                          ),
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
                            titulo: 'Jogador mais enfrentado',
                            valor: rankingPlayers.isEmpty
                                ? 'Sem dados'
                                : rankingPlayers.first.nick,
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
                            'Rounds',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          LinhaEstatistica(
                            titulo: 'Rounds vencidos',
                            valor: '$roundsVencidos',
                          ),
                          LinhaEstatistica(
                            titulo: 'Rounds perdidos',
                            valor: '$roundsPerdidos',
                          ),
                          LinhaEstatistica(
                            titulo: 'Win rate de rounds',
                            valor: '${winrateRounds.toStringAsFixed(1)}%',
                          ),
                          LinhaEstatistica(
                            titulo: 'Média de rounds vencidos',
                            valor: mediaRoundsVencidos.toStringAsFixed(2),
                          ),
                          LinhaEstatistica(
                            titulo: 'Partidas no Round 3',
                            valor: '$partidasRound3',
                          ),
                          LinhaEstatistica(
                            titulo: 'Aproveitamento no Round 3',
                            valor:
                                '${aproveitamentoRound3.toStringAsFixed(1)}%',
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
                            'Distribuição de placares',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          LinhaEstatistica(
                            titulo: 'Vitória 2x0',
                            valor: '$vitorias20',
                          ),
                          LinhaEstatistica(
                            titulo: 'Vitória 2x1',
                            valor: '$vitorias21',
                          ),
                          LinhaEstatistica(
                            titulo: 'Derrota 0x2',
                            valor: '$derrotas02',
                          ),
                          LinhaEstatistica(
                            titulo: 'Derrota 1x2',
                            valor: '$derrotas12',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (evolucaoPdl.length > 1)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Evolução de PDL',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 220,
                              child: PdlLineChart(pontos: evolucaoPdl),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (evolucaoPdl.length > 1) const SizedBox(height: 16),
                  ComparativoCard(
                    titulo: 'Win rate por matchup',
                    subtitulo: 'Personagens adversários mais enfrentados.',
                    itens: porMatchup.take(8).toList(),
                    pontosLabel: 'PDL',
                  ),
                  const SizedBox(height: 16),
                  ComparativoCard(
                    titulo: 'Contra jogadores',
                    subtitulo: 'Taxa de vitória por player enfrentado.',
                    itens: porPlayer.take(8).toList(),
                    pontosLabel: 'PDL',
                  ),
                  const SizedBox(height: 16),
                  FrequenciaCard(
                    titulo: 'Placares mais comuns',
                    subtitulo: 'Distribuição geral dos resultados salvos.',
                    itens: placares.take(8).toList(),
                    icon: Icons.scoreboard_outlined,
                  ),
                ],
              ),
            ),
    );
  }
}

class EstatisticasInvinciblePage extends StatelessWidget {
  final List<PartidaRegistrada> historico;
  final String jogoAtual;
  final TimePrincipalInvincible timePrincipalInvincible;

  const EstatisticasInvinciblePage({
    super.key,
    required this.historico,
    required this.jogoAtual,
    this.timePrincipalInvincible = timePrincipalInvincibleVazio,
  });

  AnaliseComparativaItem? melhorPorWinrate(List<AnaliseComparativaItem> itens) {
    if (itens.isEmpty) return null;

    final List<AnaliseComparativaItem> ordenados = [...itens];
    ordenados.sort((a, b) {
      final int winrateCompare = b.winrate.compareTo(a.winrate);
      if (winrateCompare != 0) return winrateCompare;

      final int totalCompare = b.total.compareTo(a.total);
      if (totalCompare != 0) return totalCompare;

      return b.saldoPdl.compareTo(a.saldoPdl);
    });

    return ordenados.first;
  }

  AnaliseComparativaItem? piorPorWinrate(List<AnaliseComparativaItem> itens) {
    if (itens.isEmpty) return null;

    final List<AnaliseComparativaItem> ordenados = [...itens];
    ordenados.sort((a, b) {
      final int winrateCompare = a.winrate.compareTo(b.winrate);
      if (winrateCompare != 0) return winrateCompare;

      final int totalCompare = b.total.compareTo(a.total);
      if (totalCompare != 0) return totalCompare;

      return a.saldoPdl.compareTo(b.saldoPdl);
    });

    return ordenados.first;
  }

  String nomePrimeiro(List<FrequenciaItem> itens) {
    return itens.isEmpty ? 'Sem dados' : itens.first.nome;
  }

  @override
  Widget build(BuildContext context) {
    final List<PartidaRegistrada> partidas = historico
        .where(
          (partida) => partidaPertenceAoContextoAtual(
            partida,
            jogo: jogoAtual,
            timePrincipalInvincible: timePrincipalInvincible,
          ),
        )
        .toList();
    final String tituloEscopo = timePrincipalInvincible.completo
        ? timePrincipalInvincible.texto
        : 'Time atual';

    final int totalPartidas = partidas.length;
    final int vitorias = partidas
        .where((partida) => partida.resultado == 'Vitória')
        .length;
    final int derrotas = partidas
        .where((partida) => partida.resultado == 'Derrota')
        .length;
    final double winrate = totalPartidas == 0
        ? 0
        : (vitorias / totalPartidas) * 100;

    final int lpGanho = partidas
        .where((partida) => partida.pdlGerado > 0)
        .fold(0, (soma, partida) => soma + partida.pdlGerado);
    final int lpPerdido = partidas
        .where((partida) => partida.pdlGerado < 0)
        .fold(0, (soma, partida) => soma + partida.pdlGerado);
    final int saldoLp = partidas.fold(
      0,
      (soma, partida) => soma + partida.pdlGerado,
    );
    final double mediaLp = totalPartidas == 0 ? 0 : saldoLp / totalPartidas;

    final List<AnaliseComparativaItem> porComposicao = gerarComparativoPorCampo(
      partidas,
      (partida) => partida.meuTimeTexto,
    );
    final List<AnaliseComparativaItem> porComposicaoInimiga =
        gerarComparativoPorCampo(
          partidas,
          (partida) => partida.timeAdversarioTexto,
        );
    final List<AnaliseComparativaItem> porAdversario = gerarComparativoPorCampo(
      partidas,
      (partida) => partida.nickAdversario,
    );

    final AnaliseComparativaItem? melhorComposicao = melhorPorWinrate(
      porComposicao,
    );
    final AnaliseComparativaItem? piorComposicao = piorPorWinrate(
      porComposicao,
    );
    final AnaliseComparativaItem? timePrincipal = porComposicao.isEmpty
        ? null
        : porComposicao.first;

    final List<FrequenciaItem> personagensEmVitorias = gerarRankingFrequencia(
      partidas
          .where((partida) => partida.resultado == 'Vitória')
          .expand((partida) => partida.meuTime)
          .toList(),
    );
    final List<FrequenciaItem> primeirosDerrotados = gerarRankingFrequencia(
      partidas.map((partida) => partida.primeiroDerrotado).toList(),
    );
    final List<FrequenciaItem> inimigosEmDerrotas = gerarRankingFrequencia(
      partidas
          .where((partida) => partida.resultado == 'Derrota')
          .expand((partida) => partida.timeAdversario)
          .toList(),
    );
    final List<FrequenciaItem> inimigosProblema = gerarRankingFrequencia(
      partidas.map((partida) => partida.personagemInimigoProblema).toList(),
    );
    final List<FrequenciaItem> condicoesVitoria = gerarRankingFrequencia(
      partidas.map((partida) => partida.condicaoVitoria).toList(),
    );
    final List<FrequenciaItem> motivosDerrota = gerarRankingFrequencia(
      partidas.map((partida) => partida.motivoDerrota).toList(),
    );
    final List<PlayerResumo> rankingPlayers = gerarRankingPlayers(partidas);
    final List<EvolucaoPdlPonto> evolucaoLp = gerarEvolucaoPdl(partidas);

    final String sinalSaldo = saldoLp >= 0 ? '+' : '';
    final String mediaFormatada = mediaLp >= 0
        ? '+${mediaLp.toStringAsFixed(1)}'
        : mediaLp.toStringAsFixed(1);

    return Scaffold(
      appBar: AppBar(
        title: const CompactAppBarTitle('Estatísticas de times'),
        centerTitle: true,
        actions: const [HomeNavigationButton()],
      ),
      body: totalPartidas == 0
          ? Center(
              child: Text(
                'Ainda não existem partidas 3v3 registradas com $tituloEscopo.',
                style: const TextStyle(fontSize: 18),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tituloEscopo,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Leitura por composição de time 3v3.',
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
                            titulo: 'Saldo de LP',
                            valor: '$sinalSaldo$saldoLp',
                          ),
                          LinhaEstatistica(
                            titulo: 'LP ganho',
                            valor: '+$lpGanho',
                          ),
                          LinhaEstatistica(
                            titulo: 'LP perdido',
                            valor: '$lpPerdido',
                          ),
                          LinhaEstatistica(
                            titulo: 'Média de LP por partida',
                            valor: mediaFormatada,
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
                            'Leitura 3v3',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          LinhaEstatistica(
                            titulo: 'Melhor composição',
                            valor: melhorComposicao == null
                                ? 'Sem dados'
                                : '${melhorComposicao.nome} • ${melhorComposicao.winrate.toStringAsFixed(1)}% WR',
                          ),
                          LinhaEstatistica(
                            titulo: 'Pior composição',
                            valor: piorComposicao == null
                                ? 'Sem dados'
                                : '${piorComposicao.nome} • ${piorComposicao.winrate.toStringAsFixed(1)}% WR',
                          ),
                          LinhaEstatistica(
                            titulo: 'Time principal',
                            valor: timePrincipal?.nome ?? 'Sem dados',
                          ),
                          LinhaEstatistica(
                            titulo: 'Mais presente em vitórias',
                            valor: nomePrimeiro(personagensEmVitorias),
                          ),
                          LinhaEstatistica(
                            titulo: 'Mais cai primeiro',
                            valor: nomePrimeiro(primeirosDerrotados),
                          ),
                          LinhaEstatistica(
                            titulo: 'Inimigo em derrotas',
                            valor: nomePrimeiro(inimigosEmDerrotas),
                          ),
                          LinhaEstatistica(
                            titulo: 'Inimigo problema',
                            valor: nomePrimeiro(inimigosProblema),
                          ),
                          LinhaEstatistica(
                            titulo: 'Adversário mais enfrentado',
                            valor: rankingPlayers.isEmpty
                                ? 'Sem dados'
                                : rankingPlayers.first.nick,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (evolucaoLp.length > 1)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Evolução de LP',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 220,
                              child: PdlLineChart(pontos: evolucaoLp),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (evolucaoLp.length > 1) const SizedBox(height: 16),
                  ComparativoCard(
                    titulo: 'Taxa por composição',
                    subtitulo: 'Winrate e saldo de LP por trio usado.',
                    itens: porComposicao.take(8).toList(),
                    pontosLabel: 'LP',
                  ),
                  const SizedBox(height: 16),
                  ComparativoCard(
                    titulo: 'Contra composições inimigas',
                    subtitulo:
                        'Times adversários que mais apareceram no histórico.',
                    itens: porComposicaoInimiga.take(8).toList(),
                    pontosLabel: 'LP',
                  ),
                  const SizedBox(height: 16),
                  ComparativoCard(
                    titulo: 'Contra adversários',
                    subtitulo: 'Taxa de vitória por player enfrentado.',
                    itens: porAdversario.take(8).toList(),
                    pontosLabel: 'LP',
                  ),
                  const SizedBox(height: 16),
                  FrequenciaCard(
                    titulo: 'Personagens em vitórias',
                    subtitulo: 'Quem mais aparece nas vitórias do seu time.',
                    itens: personagensEmVitorias.take(8).toList(),
                    icon: Icons.star_outline,
                  ),
                  const SizedBox(height: 16),
                  FrequenciaCard(
                    titulo: 'Primeiros derrotados',
                    subtitulo: 'Quem costuma cair primeiro no seu trio.',
                    itens: primeirosDerrotados.take(8).toList(),
                    icon: Icons.health_and_safety_outlined,
                  ),
                  const SizedBox(height: 16),
                  FrequenciaCard(
                    titulo: 'Inimigos em derrotas',
                    subtitulo:
                        'Personagens inimigos mais presentes quando você perde.',
                    itens: inimigosEmDerrotas.take(8).toList(),
                    icon: Icons.priority_high_outlined,
                  ),
                  const SizedBox(height: 16),
                  FrequenciaCard(
                    titulo: 'Condições de vitória',
                    subtitulo: 'Como suas vitórias estão acontecendo.',
                    itens: condicoesVitoria.take(8).toList(),
                    icon: Icons.emoji_events_outlined,
                  ),
                  const SizedBox(height: 16),
                  FrequenciaCard(
                    titulo: 'Motivos de derrota',
                    subtitulo: 'Onde vale revisar primeiro no treino.',
                    itens: motivosDerrota.take(8).toList(),
                    icon: Icons.report_problem_outlined,
                  ),
                ],
              ),
            ),
    );
  }
}
