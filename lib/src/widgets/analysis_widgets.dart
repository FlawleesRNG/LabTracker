part of '../../main.dart';

class AnalisesSection extends StatefulWidget {
  final Character personagemAtual;
  final List<PartidaRegistrada> historico;
  final String jogoAtual;
  final Map<String, String> smashCoverPreferences;

  const AnalisesSection({
    super.key,
    required this.personagemAtual,
    required this.historico,
    required this.jogoAtual,
    this.smashCoverPreferences = const {},
  });

  @override
  State<AnalisesSection> createState() => _AnalisesSectionState();
}

class _AnalisesSectionState extends State<AnalisesSection> {
  DateTime? mesComparativoSelecionado;
  String escopoSelecionado = 'Geral';
  String alvoSelecionado = 'Todos';
  String mapaSelecionado = 'Todos';

  @override
  Widget build(BuildContext context) {
    final List<PartidaRegistrada> partidasDoPersonagem = widget.historico
        .where(
          (partida) => partida.personagemJogador == widget.personagemAtual.name,
        )
        .toList();

    final List<String> personagensAdversarios = gerarOpcoesFiltro(
      partidasDoPersonagem
          .map((partida) => partida.personagemAdversario)
          .toList(),
    );
    final List<String> playersAdversarios = gerarOpcoesFiltro(
      partidasDoPersonagem.map((partida) => partida.nickAdversario).toList(),
    );
    final List<String> mapasDisponiveis = gerarOpcoesFiltro(
      partidasDoPersonagem.map((partida) => partida.stage).toList(),
    );
    final List<String> opcoesAlvo = escopoSelecionado == 'Personagem'
        ? personagensAdversarios
        : escopoSelecionado == 'Player'
        ? playersAdversarios
        : const ['Todos'];

    if (!opcoesAlvo.contains(alvoSelecionado)) {
      alvoSelecionado = 'Todos';
    }

    if (!mapasDisponiveis.contains(mapaSelecionado)) {
      mapaSelecionado = 'Todos';
    }

    List<PartidaRegistrada> partidasFiltradas = partidasDoPersonagem;

    if (escopoSelecionado == 'Personagem' && alvoSelecionado != 'Todos') {
      partidasFiltradas = partidasFiltradas
          .where((partida) => partida.personagemAdversario == alvoSelecionado)
          .toList();
    } else if (escopoSelecionado == 'Player' && alvoSelecionado != 'Todos') {
      partidasFiltradas = partidasFiltradas
          .where((partida) => partida.nickAdversario == alvoSelecionado)
          .toList();
    }

    if (mapaSelecionado != 'Todos') {
      partidasFiltradas = partidasFiltradas
          .where((partida) => partida.stage == mapaSelecionado)
          .toList();
    }

    final List<EvolucaoPdlPonto> evolucao = gerarEvolucaoPdl(partidasFiltradas);
    final List<AnaliseComparativaItem> matchups = gerarComparativoPorCampo(
      partidasFiltradas,
      (partida) => partida.personagemAdversario,
    ).take(6).toList();
    final List<AnaliseComparativaItem> mapas = gerarComparativoPorCampo(
      partidasFiltradas,
      (partida) => partida.stage,
    ).take(6).toList();
    final List<FrequenciaItem> kills = gerarRankingFrequencia(
      partidasFiltradas.map((partida) => partida.formaDeKill).toList(),
    ).where((item) => item.nome != 'Não matou').take(5).toList();
    final List<FrequenciaItem> mortes = gerarRankingFrequencia(
      partidasFiltradas.map((partida) => partida.formaDeMorte).toList(),
    ).where((item) => item.nome != 'Não morreu').take(5).toList();
    final List<String> insights = gerarInsightsAvancados(
      partidasFiltradas,
      personagemAtual: widget.personagemAtual.name,
      escopo: escopoSelecionado,
      alvo: alvoSelecionado,
      mapa: mapaSelecionado,
    );

    final DateTime agora = DateTime.now();
    final DateTime mesAtual = DateTime(agora.year, agora.month);
    final DateTime mesAnterior = mesAnteriorDe(agora);
    final List<DateTime> mesesDisponiveis = gerarMesesDisponiveis(
      partidasFiltradas,
    );
    final List<DateTime> mesesComparaveis = mesesDisponiveis
        .where((mes) => !mesmoMesAno(mes, mesAtual))
        .toList();

    DateTime? mesComparativo = mesComparativoSelecionado;
    final bool mesSelecionadoExiste = mesComparativo == null
        ? false
        : mesesComparaveis.any((mes) => mesmoMesAno(mes, mesComparativo!));

    if (!mesSelecionadoExiste) {
      final bool existeMesAnterior = mesesComparaveis.any(
        (mes) => mesmoMesAno(mes, mesAnterior),
      );

      if (existeMesAnterior) {
        mesComparativo = mesesComparaveis.firstWhere(
          (mes) => mesmoMesAno(mes, mesAnterior),
        );
      } else if (mesesComparaveis.isNotEmpty) {
        mesComparativo = mesesComparaveis.first;
      } else {
        mesComparativo = null;
      }
    }

    if (partidasDoPersonagem.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Registre partidas com ${widget.personagemAtual.name} para liberar gráficos, comparativos e dicas.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MatchupHeader(
          jogo: widget.jogoAtual,
          personagem: widget.personagemAtual.name,
          adversario: 'Histórico',
          avatarSize: 42,
          style: Theme.of(context).textTheme.headlineSmall,
          smashCoverPreferences: widget.smashCoverPreferences,
          usarPreferenciaVisualSmash: true,
        ),
        const SizedBox(height: 8),
        Text(
          'Comparativos baseados nas partidas registradas com ${widget.personagemAtual.name}.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filtro da análise',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: escopoSelecionado,
                  decoration: const InputDecoration(
                    labelText: 'Ver dados',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Geral', child: Text('No geral')),
                    DropdownMenuItem(
                      value: 'Personagem',
                      child: Text('Contra personagem específico'),
                    ),
                    DropdownMenuItem(
                      value: 'Player',
                      child: Text('Contra player específico'),
                    ),
                  ],
                  onChanged: (valor) {
                    if (valor == null) return;
                    setState(() {
                      escopoSelecionado = valor;
                      alvoSelecionado = 'Todos';
                    });
                  },
                ),
                if (escopoSelecionado != 'Geral') ...[
                  const SizedBox(height: 12),
                  SearchableOptionField(
                    label: escopoSelecionado == 'Personagem'
                        ? 'Pesquisar personagem adversário'
                        : 'Pesquisar player adversário',
                    value: alvoSelecionado,
                    options: opcoesAlvo,
                    icon: escopoSelecionado == 'Personagem'
                        ? Icons.sports_esports_outlined
                        : Icons.person_search_outlined,
                    onChanged: (valor) {
                      setState(() {
                        alvoSelecionado = valor;
                      });
                    },
                  ),
                ],
                const SizedBox(height: 12),
                SearchableOptionField(
                  label: 'Pesquisar mapa',
                  value: mapaSelecionado,
                  options: mapasDisponiveis,
                  icon: Icons.map_outlined,
                  onChanged: (valor) {
                    setState(() {
                      mapaSelecionado = valor;
                    });
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  '${partidasFiltradas.length} partidas encontradas nesse filtro.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        if (partidasFiltradas.isEmpty) ...[
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Text(
                'Sem partidas para esse filtro. Troque o player, personagem ou mapa.',
              ),
            ),
          ),
        ],
        if (partidasFiltradas.isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Evolução de PDL',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text('Gráfico estilo stonks por partida registrada.'),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 190,
                    width: double.infinity,
                    child: PdlLineChart(pontos: evolucao),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mês atual vs mês escolhido',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (mesesComparaveis.isNotEmpty)
                    DropdownButtonFormField<DateTime>(
                      value: mesComparativo,
                      decoration: const InputDecoration(
                        labelText: 'Comparar com',
                        border: OutlineInputBorder(),
                      ),
                      items: mesesComparaveis.map((mes) {
                        return DropdownMenuItem<DateTime>(
                          value: mes,
                          child: Text(rotuloMesAno(mes)),
                        );
                      }).toList(),
                      onChanged: (novoMes) {
                        setState(() {
                          mesComparativoSelecionado = novoMes;
                        });
                      },
                    ),
                  if (mesesComparaveis.isNotEmpty) const SizedBox(height: 12),
                  LinhaEstatistica(
                    titulo: 'Mês atual',
                    valor: resumoMes(partidasFiltradas, agora),
                  ),
                  LinhaEstatistica(
                    titulo: 'Comparativo',
                    valor: mesComparativo == null
                        ? 'Sem outro mês registrado'
                        : resumoMes(partidasFiltradas, mesComparativo),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ComparativoCard(
            titulo: 'Matchups',
            subtitulo: 'Quem você mais enfrenta e como está seu resultado.',
            itens: matchups,
            usarWinrate: true,
          ),
          const SizedBox(height: 16),
          ComparativoCard(
            titulo: 'Mapas',
            subtitulo: 'Onde você mais joga, ganha e perde PDL.',
            itens: mapas,
            usarWinrate: true,
          ),
          const SizedBox(height: 16),
          FrequenciaCard(
            titulo: 'Formas de kill',
            subtitulo:
                'KOs registrados nesse filtro. As dicas abaixo usam isso como contexto.',
            itens: kills,
            icon: Icons.flash_on,
          ),
          const SizedBox(height: 16),
          FrequenciaCard(
            titulo: 'Formas de morte',
            subtitulo: 'Padrões de morte para revisar no treino.',
            itens: mortes,
            icon: Icons.warning_amber_outlined,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dicas para jogar melhor',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...insights.map((insight) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.auto_awesome, size: 20),
                          const SizedBox(width: 10),
                          Expanded(child: Text(insight)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class PdlLineChart extends StatelessWidget {
  final List<EvolucaoPdlPonto> pontos;

  const PdlLineChart({super.key, required this.pontos});

  @override
  Widget build(BuildContext context) {
    if (pontos.length < 2) {
      return const Center(
        child: Text('Registre pelo menos 2 partidas para desenhar a evolução.'),
      );
    }

    final int saldoFinal = pontos.last.saldo;
    final Color corLinha = saldoFinal >= 0
        ? Colors.greenAccent
        : Colors.redAccent;

    return CustomPaint(
      painter: PdlLineChartPainter(
        pontos: pontos,
        lineColor: corLinha,
        gridColor: Theme.of(context).dividerColor.withOpacity(0.35),
        textColor:
            Theme.of(context).textTheme.bodySmall?.color ??
            Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

class PdlLineChartPainter extends CustomPainter {
  final List<EvolucaoPdlPonto> pontos;
  final Color lineColor;
  final Color gridColor;
  final Color textColor;

  const PdlLineChartPainter({
    required this.pontos,
    required this.lineColor,
    required this.gridColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double left = 46;
    const double right = 12;
    const double top = 14;
    const double bottom = 32;

    final double chartWidth = size.width - left - right;
    final double chartHeight = size.height - top - bottom;

    if (chartWidth <= 0 || chartHeight <= 0) return;

    int minSaldo = pontos.first.saldo;
    int maxSaldo = pontos.first.saldo;

    for (final ponto in pontos) {
      if (ponto.saldo < minSaldo) minSaldo = ponto.saldo;
      if (ponto.saldo > maxSaldo) maxSaldo = ponto.saldo;
    }

    if (minSaldo == maxSaldo) {
      minSaldo -= 10;
      maxSaldo += 10;
    }

    final Paint gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    for (int i = 0; i <= 3; i++) {
      final double y = top + (chartHeight / 3) * i;
      canvas.drawLine(
        Offset(left, y),
        Offset(size.width - right, y),
        gridPaint,
      );
    }

    final double zeroY = top + (maxSaldo / (maxSaldo - minSaldo)) * chartHeight;
    if (zeroY >= top && zeroY <= top + chartHeight) {
      final Paint zeroPaint = Paint()
        ..color = textColor.withOpacity(0.45)
        ..strokeWidth = 1.2;
      canvas.drawLine(
        Offset(left, zeroY),
        Offset(size.width - right, zeroY),
        zeroPaint,
      );
    }

    Offset pontoParaOffset(int index, EvolucaoPdlPonto ponto) {
      final double x = left + (chartWidth / (pontos.length - 1)) * index;
      final double normalizado =
          (ponto.saldo - minSaldo) / (maxSaldo - minSaldo);
      final double y = top + chartHeight - (normalizado * chartHeight);
      return Offset(x, y);
    }

    final Path path = Path();
    for (int i = 0; i < pontos.length; i++) {
      final Offset offset = pontoParaOffset(i, pontos[i]);
      if (i == 0) {
        path.moveTo(offset.dx, offset.dy);
      } else {
        path.lineTo(offset.dx, offset.dy);
      }
    }

    final Paint linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);

    final Paint dotPaint = Paint()..color = lineColor;
    for (int i = 0; i < pontos.length; i++) {
      final bool deveMostrar =
          i == 0 || i == pontos.length - 1 || pontos.length <= 8 || i % 3 == 0;
      if (!deveMostrar) continue;
      canvas.drawCircle(pontoParaOffset(i, pontos[i]), 4, dotPaint);
    }

    void drawText(
      String texto,
      Offset pos, {
      TextAlign align = TextAlign.left,
    }) {
      final TextPainter painter = TextPainter(
        text: TextSpan(
          text: texto,
          style: TextStyle(color: textColor.withOpacity(0.75), fontSize: 11),
        ),
        textDirection: TextDirection.ltr,
        textAlign: align,
      )..layout(maxWidth: 80);

      painter.paint(canvas, pos);
    }

    drawText('$maxSaldo', const Offset(0, top - 2));
    drawText('$minSaldo', Offset(0, top + chartHeight - 12));
    drawText('P1', Offset(left, size.height - 22));
    drawText(
      'P${pontos.length}',
      Offset(size.width - right - 34, size.height - 22),
    );
  }

  @override
  bool shouldRepaint(covariant PdlLineChartPainter oldDelegate) {
    return oldDelegate.pontos != pontos ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.textColor != textColor;
  }
}

class ComparativoCard extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final List<AnaliseComparativaItem> itens;
  final bool usarWinrate;
  final String pontosLabel;

  const ComparativoCard({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.itens,
    this.usarWinrate = true,
    this.pontosLabel = 'PDL',
  });

  @override
  Widget build(BuildContext context) {
    final int maiorTotal = itens.isEmpty
        ? 1
        : itens.map((item) => item.total).reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(subtitulo),
            const SizedBox(height: 16),
            if (itens.isEmpty)
              const Text('Sem dados suficientes.')
            else
              ...itens.map((item) {
                final double fator = item.total / maiorTotal;
                final String saldo = formatarSaldo(item.saldoPdl);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.nome,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            usarWinrate
                                ? '${item.winrate.toStringAsFixed(1)}% • $saldo $pontosLabel'
                                : '${item.total}x • $saldo $pontosLabel',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: fator.clamp(0.08, 1.0).toDouble(),
                          minHeight: 9,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.total} partidas • ${item.vitorias}V / ${item.derrotas}D',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class FrequenciaCard extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final List<FrequenciaItem> itens;
  final IconData icon;

  const FrequenciaCard({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.itens,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final int maior = itens.isEmpty
        ? 1
        : itens.map((item) => item.quantidade).reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(subtitulo),
            const SizedBox(height: 16),
            if (itens.isEmpty)
              const Text('Sem dados suficientes.')
            else
              ...itens.map((item) {
                final double fator = item.quantidade / maior;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(icon, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 3,
                        child: Text(
                          item.nome,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: fator.clamp(0.08, 1.0).toDouble(),
                            minHeight: 9,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${item.quantidade}x',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class MatchupStatsPage extends StatelessWidget {
  final Character personagemAtual;
  final List<PartidaRegistrada> partidasDoPersonagem;
  final String jogoAtual;
  final Map<String, String> smashCoverPreferences;

  const MatchupStatsPage({
    super.key,
    required this.personagemAtual,
    required this.partidasDoPersonagem,
    required this.jogoAtual,
    this.smashCoverPreferences = const {},
  });

  @override
  Widget build(BuildContext context) {
    final List<MatchupResumo> matchups = gerarRankingMatchups(
      partidasDoPersonagem,
    );

    return Scaffold(
      appBar: AppBar(
        title: const CompactAppBarTitle('Matchup Stats'),
        centerTitle: true,
        actions: const [HomeNavigationButton()],
      ),
      body: matchups.isEmpty
          ? Center(
              child: Text(
                'Ainda não existem matchups registrados com ${personagemAtual.name}.',
                style: const TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: matchups.length,
              itemBuilder: (context, index) {
                final matchup = matchups[index];
                final String sinalPdl = matchup.saldoPdl >= 0 ? '+' : '';

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MatchupHeader(
                          jogo: jogoAtual,
                          personagem: personagemAtual.name,
                          adversario: matchup.personagemAdversario,
                          avatarSize: 34,
                          smashCoverPreferences: smashCoverPreferences,
                          usarPreferenciaVisualSmash: true,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        LinhaEstatistica(
                          titulo: 'Partidas',
                          valor: '${matchup.total}',
                        ),
                        LinhaEstatistica(
                          titulo: 'Vitórias / Derrotas',
                          valor: '${matchup.vitorias}V / ${matchup.derrotas}D',
                        ),
                        LinhaEstatistica(
                          titulo: 'Winrate',
                          valor: '${matchup.winrate.toStringAsFixed(1)}%',
                        ),
                        LinhaEstatistica(
                          titulo: 'Saldo de PDL',
                          valor: '$sinalPdl${matchup.saldoPdl}',
                        ),
                        LinhaEstatistica(
                          titulo: 'Kill mais comum',
                          valor: matchup.killMaisComum,
                        ),
                        LinhaEstatistica(
                          titulo: 'Morte mais comum',
                          valor: matchup.morteMaisComum,
                        ),
                        LinhaEstatistica(
                          titulo: 'Stage mais jogado',
                          valor: matchup.stageMaisJogado,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
