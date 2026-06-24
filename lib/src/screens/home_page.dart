part of '../../main.dart';

class HomePage extends StatefulWidget {
  final String jogoAtual;
  final String? personagemInicialNome;
  final TimePrincipalInvincible? timePrincipalInicial;

  const HomePage({
    super.key,
    required this.jogoAtual,
    this.personagemInicialNome,
    this.timePrincipalInicial,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

enum _HomePageMenuAction { perfil, configuracoes, resetar }

class _HomePageState extends State<HomePage> {
  PlayerProfile perfil = perfilPadrao;

  late Map<String, Character> personagens;

  late String personagemAtualNome;

  TimePrincipalInvincible timePrincipalInvincible =
      timePrincipalInvincibleVazio;

  Map<String, String> smashCoverPreferences = {};

  List<PartidaRegistrada> historico = [];

  bool carregando = true;

  /// Nome do personagem padrão (primeiro do roster do jogo atual).
  String get personagemPadraoDoJogo {
    final roster = rosterDoJogo(widget.jogoAtual);
    return roster.isNotEmpty ? roster.first.name : '';
  }

  @override
  void initState() {
    super.initState();
    personagens = {
      for (final personagem in rosterDoJogo(widget.jogoAtual))
        personagem.name: personagem,
    };
    personagemAtualNome =
        widget.personagemInicialNome ?? personagemPadraoDoJogo;
    carregarDados();
  }

  Character get personagemAtual {
    return personagens[personagemAtualNome] ??
        personagens[personagemPadraoDoJogo] ??
        Character(
          name: personagemPadraoDoJogo,
          initial: personagemPadraoDoJogo.isNotEmpty
              ? personagemPadraoDoJogo[0].toUpperCase()
              : '?',
          rank: rankInicialDoJogo(widget.jogoAtual),
          pdl: 0,
        );
  }

  List<PartidaRegistrada> get historicoDoContextoAtual {
    return filtrarHistoricoPorContextoAtual(
      historico,
      jogo: widget.jogoAtual,
      personagemAtual: personagemAtual.name,
      timePrincipalInvincible: timePrincipalInvincible,
    );
  }

  PartidaRegistrada? get ultimaPartidaDoContextoAtual {
    final List<PartidaRegistrada> partidas = historicoDoContextoAtual;
    return partidas.isEmpty ? null : partidas.first;
  }

  Map<String, dynamic> gerarDadosPersistidos() {
    return {
      'perfilJogador': perfil.toJson(),
      'jogoAtual': widget.jogoAtual,
      'personagemAtualNome': personagemAtualNome,
      'timePrincipalInvincible': timePrincipalInvincible.toJson(),
      prefsKeySmashCoverPreferences: smashCoverPreferences,
      'personagens': personagens.values
          .map((personagem) => personagem.toJson())
          .toList(),
      'historico': historico.map((partida) => partida.toJson()).toList(),
    };
  }

  void _aplicarDadosMap(Map<String, dynamic> dados) {
    final dynamic personagensRaw = dados['personagens'];
    final dynamic historicoRaw = dados['historico'];
    final dynamic personagemAtualRaw = dados['personagemAtualNome'];
    final dynamic timePrincipalRaw = dados['timePrincipalInvincible'];
    final dynamic perfilRaw = dados['perfilJogador'];
    final dynamic smashCoverPreferencesRaw =
        dados[prefsKeySmashCoverPreferences];

    personagens = {
      for (final personagem in rosterDoJogo(widget.jogoAtual))
        personagem.name: personagem,
    };
    timePrincipalInvincible = timePrincipalInvincibleVazio;

    if (personagensRaw is List) {
      final Map<String, Character> importados = {};
      for (final item in personagensRaw) {
        if (item is Map<String, dynamic>) {
          try {
            final Character personagem = Character.fromJson(item);
            importados[personagem.name] = personagem;
          } catch (_) {}
        }
      }

      personagens.addAll(importados);
    }

    for (final personagemBase in rosterDoJogo(widget.jogoAtual)) {
      personagens.putIfAbsent(personagemBase.name, () => personagemBase);
    }

    historico = [];
    if (historicoRaw is List) {
      final List<PartidaRegistrada> importadas = [];
      for (final item in historicoRaw) {
        if (item is Map<String, dynamic>) {
          try {
            importadas.add(PartidaRegistrada.fromJson(item));
          } catch (_) {}
        }
      }
      historico = importadas;
    }

    if (personagemAtualRaw is String &&
        personagens.containsKey(personagemAtualRaw)) {
      personagemAtualNome = personagemAtualRaw;
    }

    if (timePrincipalRaw is Map<String, dynamic>) {
      try {
        timePrincipalInvincible = TimePrincipalInvincible.fromJson(
          timePrincipalRaw,
        );
      } catch (_) {}
    } else if (timePrincipalRaw is Map) {
      try {
        timePrincipalInvincible = TimePrincipalInvincible.fromJson(
          Map<String, dynamic>.from(timePrincipalRaw),
        );
      } catch (_) {}
    }

    if (perfilRaw is Map<String, dynamic>) {
      try {
        perfil = PlayerProfile.fromJson(perfilRaw);
      } catch (_) {}
    }

    smashCoverPreferences = normalizarPreferenciasCapaSmash(
      smashCoverPreferencesRaw,
    );
  }

  Future<Map<String, String>> carregarPreferenciasCapaSmashPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? preferenciasRaw = prefs.getString(
      prefsKeySmashCoverPreferences,
    );

    if (preferenciasRaw == null) return {};

    try {
      return normalizarPreferenciasCapaSmash(jsonDecode(preferenciasRaw));
    } catch (_) {
      return {};
    }
  }

  Future<void> carregarDados() async {
    bool carregouArquivo = false;
    final Map<String, dynamic>? dadosArquivo = await _lerDadosArquivo();
    if (dadosArquivo != null) {
      _aplicarDadosMap(dadosArquivo);
      carregouArquivo = true;
    }

    if (!carregouArquivo) {
      final prefs = await SharedPreferences.getInstance();

      final String? personagensSalvos = prefs.getString('personagens');
      final String? historicoSalvo = prefs.getString('historico');
      final String? personagemAtualSalvo = prefs.getString(
        'personagemAtualNome',
      );
      final String? perfilSalvo = prefs.getString('perfilJogador');
      final String? timePrincipalSalvo = prefs.getString(
        'timePrincipalInvincible',
      );
      final String? preferenciasCapaSmashSalvas = prefs.getString(
        prefsKeySmashCoverPreferences,
      );

      if (personagensSalvos != null) {
        try {
          final dynamic decoded = jsonDecode(personagensSalvos);
          if (decoded is List) {
            final Map<String, Character> importados = {};
            for (final item in decoded) {
              if (item is Map<String, dynamic>) {
                try {
                  final Character personagem = Character.fromJson(item);
                  importados[personagem.name] = personagem;
                } catch (_) {}
              }
            }

            personagens.addAll(importados);
          }
        } catch (_) {}

        for (final personagemBase in rosterDoJogo(widget.jogoAtual)) {
          personagens.putIfAbsent(personagemBase.name, () => personagemBase);
        }
      }

      if (historicoSalvo != null) {
        try {
          final dynamic decoded = jsonDecode(historicoSalvo);
          if (decoded is List) {
            historico = decoded
                .whereType<Map<String, dynamic>>()
                .map((item) => PartidaRegistrada.fromJson(item))
                .toList();
          }
        } catch (_) {
          historico = [];
        }
      }

      if (personagemAtualSalvo != null &&
          personagens.containsKey(personagemAtualSalvo)) {
        personagemAtualNome = personagemAtualSalvo;
      }

      if (timePrincipalSalvo != null) {
        try {
          final dynamic decoded = jsonDecode(timePrincipalSalvo);
          if (decoded is Map<String, dynamic>) {
            timePrincipalInvincible = TimePrincipalInvincible.fromJson(decoded);
          } else if (decoded is Map) {
            timePrincipalInvincible = TimePrincipalInvincible.fromJson(
              Map<String, dynamic>.from(decoded),
            );
          }
        } catch (_) {}
      }

      if (perfilSalvo != null) {
        try {
          final dynamic decoded = jsonDecode(perfilSalvo);
          if (decoded is Map<String, dynamic>) {
            perfil = PlayerProfile.fromJson(decoded);
          }
        } catch (_) {}
      }

      if (preferenciasCapaSmashSalvas != null) {
        try {
          smashCoverPreferences = normalizarPreferenciasCapaSmash(
            jsonDecode(preferenciasCapaSmashSalvas),
          );
        } catch (_) {}
      }
    }

    if (smashCoverPreferences.isEmpty) {
      smashCoverPreferences = await carregarPreferenciasCapaSmashPrefs();
    }

    if (widget.personagemInicialNome != null &&
        personagens.containsKey(widget.personagemInicialNome)) {
      personagemAtualNome = widget.personagemInicialNome!;
    }

    final bool recebeuTimeInicial = widget.timePrincipalInicial != null;
    if (widget.timePrincipalInicial != null) {
      timePrincipalInvincible = widget.timePrincipalInicial!;
      if (timePrincipalInvincible.slot1.isNotEmpty &&
          personagens.containsKey(timePrincipalInvincible.slot1)) {
        personagemAtualNome = timePrincipalInvincible.slot1;
      }
    }

    recalcularPersonagensPeloHistorico();

    setState(() {
      carregando = false;
    });

    if (recebeuTimeInicial) {
      await salvarDados();
    }
  }

  Future<void> salvarDados() async {
    final prefs = await SharedPreferences.getInstance();

    await _salvarDadosArquivo(gerarDadosPersistidos());

    await prefs.setString('personagemAtualNome', personagemAtualNome);
    await prefs.setString(
      'timePrincipalInvincible',
      jsonEncode(timePrincipalInvincible.toJson()),
    );
    await prefs.setString('perfilJogador', jsonEncode(perfil.toJson()));
    await prefs.setString(
      prefsKeySmashCoverPreferences,
      jsonEncode(smashCoverPreferences),
    );
    await prefs.remove('personagens');
    await prefs.remove('historico');
  }

  String get pastaBackupPath {
    final String? userProfile = Platform.environment['USERPROFILE'];

    if (userProfile != null && userProfile.trim().isNotEmpty) {
      return '$userProfile${Platform.pathSeparator}Documents${Platform.pathSeparator}LabTracker_Backups';
    }

    return '${Directory.current.path}${Platform.pathSeparator}LabTracker_Backups';
  }

  Map<String, dynamic> gerarDadosBackup() {
    return {
      'app': 'LabTracker',
      'versaoBackup': 2,
      'criadoEm': DateTime.now().toIso8601String(),
      'perfilJogador': perfil.toJson(),
      'jogoAtual': widget.jogoAtual,
      'personagemAtualNome': personagemAtualNome,
      'timePrincipalInvincible': timePrincipalInvincible.toJson(),
      prefsKeySmashCoverPreferences: smashCoverPreferences,
      'personagens': personagens.values
          .map((personagem) => personagem.toJson())
          .toList(),
      'historico': historico.map((partida) => partida.toJson()).toList(),
    };
  }

  Future<String> exportarBackup() async {
    final Directory pastaBackup = Directory(pastaBackupPath);

    if (!await pastaBackup.exists()) {
      await pastaBackup.create(recursive: true);
    }

    final DateTime agora = DateTime.now();
    String doisDigitos(int numero) => numero.toString().padLeft(2, '0');

    final String nomeArquivo =
        'labtracker_backup_'
        '${agora.year}${doisDigitos(agora.month)}${doisDigitos(agora.day)}_'
        '${doisDigitos(agora.hour)}${doisDigitos(agora.minute)}${doisDigitos(agora.second)}.json';

    final String caminhoArquivo =
        '${pastaBackup.path}${Platform.pathSeparator}$nomeArquivo';

    final File arquivoBackup = File(caminhoArquivo);
    const JsonEncoder encoder = JsonEncoder.withIndent('  ');

    await arquivoBackup.writeAsString(
      encoder.convert(gerarDadosBackup()),
      flush: true,
    );

    return arquivoBackup.path;
  }

  Future<String> importarBackupMaisRecente() async {
    final Directory pastaBackup = Directory(pastaBackupPath);

    if (!await pastaBackup.exists()) {
      throw Exception(
        'A pasta de backup ainda não existe. Exporte um backup primeiro.',
      );
    }

    final List<File> arquivos = pastaBackup
        .listSync()
        .whereType<File>()
        .where((arquivo) => arquivo.path.toLowerCase().endsWith('.json'))
        .toList();

    if (arquivos.isEmpty) {
      throw Exception(
        'Nenhum arquivo .json de backup foi encontrado na pasta.',
      );
    }

    arquivos.sort((a, b) {
      return b.lastModifiedSync().compareTo(a.lastModifiedSync());
    });

    final File arquivoMaisRecente = arquivos.first;
    final String conteudo = await arquivoMaisRecente.readAsString();
    final Map<String, dynamic> dados = jsonDecode(conteudo);

    if (dados['app'] != 'LabTracker') {
      throw Exception(
        'Esse arquivo não parece ser um backup válido do LabTracker.',
      );
    }

    setState(() {
      _aplicarDadosMap(dados);

      if (!personagens.containsKey(personagemAtualNome)) {
        personagemAtualNome = personagemPadraoDoJogo;
      }

      recalcularPersonagensPeloHistorico();
    });

    await salvarDados();

    return arquivoMaisRecente.path;
  }

  void recalcularPersonagensPeloHistorico() {
    final Map<String, Character> novosPersonagens = {
      for (final personagem in rosterDoJogo(widget.jogoAtual))
        personagem.name: personagem,
    };

    final List<PartidaRegistrada> partidasEmOrdemCronologica = historico
        .where((partida) => partidaPertenceAoJogo(partida, widget.jogoAtual))
        .toList()
        .reversed
        .toList();

    void aplicarPontos(String nomePersonagem, int pontos) {
      if (nomePersonagem.trim().isEmpty) return;

      final Character personagem =
          novosPersonagens[nomePersonagem] ??
          Character(
            name: nomePersonagem,
            initial: nomePersonagem.isNotEmpty
                ? nomePersonagem[0].toUpperCase()
                : '?',
            rank: rankInicialDoJogo(widget.jogoAtual),
            pdl: 0,
          );

      final int novoPdl = personagem.pdl + pontos;
      final int pdlCorrigido = novoPdl < 0 ? 0 : novoPdl;

      novosPersonagens[personagem.name] = personagem.copyWith(
        pdl: pdlCorrigido,
        rank: calcularRankDoJogo(widget.jogoAtual, pdlCorrigido),
      );
    }

    for (final partida in partidasEmOrdemCronologica) {
      if (widget.jogoAtual == jogoInvincibleVs && partida.isInvincible) {
        for (final personagem in partida.meuTime) {
          aplicarPontos(personagem, partida.pdlGerado);
        }
      } else {
        aplicarPontos(partida.personagemJogador, partida.pdlGerado);
      }
    }

    personagens = novosPersonagens;

    if (!personagens.containsKey(personagemAtualNome)) {
      personagemAtualNome = personagemPadraoDoJogo;
    }
  }

  Future<void> resetarDados() async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Resetar dados?'),
          content: const Text(
            'Isso vai apagar o PDL, ranks e histórico salvos no LabTracker.',
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
              child: const Text('Resetar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    await _removerDadosArquivo();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('personagens');
    await prefs.remove('historico');
    await prefs.remove('personagemAtualNome');
    await prefs.remove('timePrincipalInvincible');
    await prefs.remove('perfilJogador');
    await prefs.remove(prefsKeySmashCoverPreferences);

    setState(() {
      personagens = {
        for (final personagem in rosterDoJogo(widget.jogoAtual))
          personagem.name: personagem,
      };
      historico = [];
      personagemAtualNome = personagemPadraoDoJogo;
      timePrincipalInvincible = timePrincipalInvincibleVazio;
      smashCoverPreferences = {};
      perfil = perfilPadrao;
    });
  }

  Future<void> atualizarPreferenciaCapaSmash(
    String personagem,
    String preferencia,
  ) async {
    if (!jogoEhSmash(widget.jogoAtual)) return;

    final String nome = normalizarPersonagemCapaSmash(personagem);
    if (!personagemTemPreferenciaCapaSmash(nome)) return;

    final Map<String, String> novasPreferencias = {...smashCoverPreferences};

    if (opcaoCapaSmashPorId(nome, preferencia) == null) {
      novasPreferencias.remove(nome);
    } else {
      novasPreferencias[nome] = preferencia;
    }

    setState(() {
      smashCoverPreferences = novasPreferencias;
    });

    await salvarDados();
  }

  Future<void> abrirSelecaoDePersonagem() async {
    final Character? personagemEscolhido = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelecionarPersonagemPage(
          titulo: 'Escolher seu personagem',
          personagens: personagens.values.toList(),
          jogoAtual: widget.jogoAtual,
        ),
      ),
    );

    if (personagemEscolhido != null) {
      setState(() {
        personagemAtualNome = personagemEscolhido.name;
      });

      await marcarPersonagemRecente(widget.jogoAtual, personagemEscolhido.name);
      await marcarJogoRecente(widget.jogoAtual);
      await salvarDados();
    }
  }

  Future<bool> abrirMontarTimePrincipal() async {
    final TimePrincipalInvincible? time =
        await Navigator.push<TimePrincipalInvincible>(
          context,
          MaterialPageRoute<TimePrincipalInvincible>(
            builder: (context) =>
                MontarTimeInvinciblePage(timeInicial: timePrincipalInvincible),
          ),
        );

    if (time == null) return false;

    setState(() {
      timePrincipalInvincible = time;
      if (time.slot1.isNotEmpty && personagens.containsKey(time.slot1)) {
        personagemAtualNome = time.slot1;
      }
    });

    await marcarJogoRecente(widget.jogoAtual);
    for (final personagem in time.personagens) {
      await marcarPersonagemRecente(widget.jogoAtual, personagem);
    }

    await salvarDados();
    return true;
  }

  List<String> sugestoesFrequentes(Iterable<String> itens) {
    return gerarRankingFrequencia(
      itens.toList(),
    ).map((item) => item.nome).take(8).toList();
  }

  Future<void> abrirRegistrarPartida({
    PartidaRegistrada? partidaInicial,
    bool repetirUltima = false,
  }) async {
    if (widget.jogoAtual == jogoInvincibleVs &&
        !timePrincipalInvincible.completo) {
      final bool montouTime = await abrirMontarTimePrincipal();
      if (!montouTime || !timePrincipalInvincible.completo) return;
    }

    if (!mounted) return;

    final List<PartidaRegistrada> partidasDoContexto = historicoDoContextoAtual;

    final PartidaRegistrada? partida = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          if (widget.jogoAtual == jogoInvincibleVs) {
            return RegistrarPartidaInvinciblePage(
              jogo: widget.jogoAtual,
              sugestoesPlayers: gerarSugestoesPlayers(partidasDoContexto),
              timePrincipal: timePrincipalInvincible,
              partidaInicial: partidaInicial,
              repetirUltima: repetirUltima,
            );
          }

          if (widget.jogoAtual == jogoStreetFighter6) {
            return RegistrarPartidaStreetFighterPage(
              personagemAtual: personagemAtual,
              jogo: widget.jogoAtual,
              sugestoesPlayers: gerarSugestoesPlayers(partidasDoContexto),
              partidaInicial: partidaInicial,
              repetirUltima: repetirUltima,
            );
          }

          return RegistrarPartidaPage(
            personagemAtual: personagemAtual,
            jogo: widget.jogoAtual,
            sugestoesPlayers: gerarSugestoesPlayers(partidasDoContexto),
            sugestoesStages: sugestoesFrequentes(
              partidasDoContexto.map((partida) => partida.stage),
            ),
            sugestoesKills: sugestoesFrequentes(
              partidasDoContexto.map((partida) => partida.formaDeKill),
            ),
            sugestoesMortes: sugestoesFrequentes(
              partidasDoContexto.map((partida) => partida.formaDeMorte),
            ),
            partidaInicial: partidaInicial,
          );
        },
      ),
    );

    if (partida != null) {
      setState(() {
        historico.insert(0, partida);
        recalcularPersonagensPeloHistorico();
      });

      await marcarJogoRecente(widget.jogoAtual);
      if (widget.jogoAtual == jogoInvincibleVs) {
        for (final personagem in partida.meuTime) {
          await marcarPersonagemRecente(widget.jogoAtual, personagem);
        }
      } else {
        await marcarPersonagemRecente(
          widget.jogoAtual,
          partida.personagemJogador,
        );
      }
      await salvarDados();
    }
  }

  Future<void> abrirRepetirUltimaPartida() async {
    final PartidaRegistrada? ultimaPartida = ultimaPartidaDoContextoAtual;
    if (ultimaPartida == null) return;

    await abrirRegistrarPartida(
      partidaInicial: ultimaPartida,
      repetirUltima: true,
    );
  }

  Future<void> abrirHistorico() async {
    final bool? houveAlteracao = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HistoricoPage(
          historico: historico,
          personagemAtual: personagemReferenciaAtual(),
          jogo: widget.jogoAtual,
          timePrincipalInvincible: timePrincipalInvincible,
          smashCoverPreferences: smashCoverPreferences,
          onHistoricoAlterado: () async {
            if (!mounted) return;
            setState(() {
              recalcularPersonagensPeloHistorico();
            });
            await salvarDados();
          },
        ),
      ),
    );

    if (houveAlteracao == true) {
      setState(() {
        recalcularPersonagensPeloHistorico();
      });

      await salvarDados();
    }
  }

  void abrirEstatisticas() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          if (widget.jogoAtual == jogoInvincibleVs) {
            return EstatisticasInvinciblePage(
              historico: historico,
              jogoAtual: widget.jogoAtual,
              timePrincipalInvincible: timePrincipalInvincible,
            );
          }

          if (widget.jogoAtual == jogoStreetFighter6) {
            return EstatisticasStreetFighterPage(
              personagemAtual: personagemAtual,
              historico: historico,
              jogoAtual: widget.jogoAtual,
            );
          }

          return EstatisticasPage(
            personagemAtual: personagemAtual,
            historico: historico,
            jogoAtual: widget.jogoAtual,
            smashCoverPreferences: smashCoverPreferences,
          );
        },
      ),
    );
  }

  void abrirResumoTreino() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          if (widget.jogoAtual == jogoInvincibleVs) {
            return EstatisticasInvinciblePage(
              historico: historico,
              jogoAtual: widget.jogoAtual,
              timePrincipalInvincible: timePrincipalInvincible,
            );
          }

          if (widget.jogoAtual == jogoStreetFighter6) {
            return EstatisticasStreetFighterPage(
              personagemAtual: personagemAtual,
              historico: historico,
              jogoAtual: widget.jogoAtual,
            );
          }

          return ResumoTreinoPage(
            personagemAtual: personagemAtual,
            historico: historico,
            jogoAtual: widget.jogoAtual,
            smashCoverPreferences: smashCoverPreferences,
          );
        },
      ),
    );
  }

  Future<void> abrirPerfil() async {
    final PlayerProfile? perfilEditado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PerfilJogadorPage(
          perfil: perfil,
          personagemAtual: personagemReferenciaAtual(),
          jogoAtual: widget.jogoAtual,
          smashCoverPreferences: smashCoverPreferences,
          onSmashCoverPreferenceChanged: atualizarPreferenciaCapaSmash,
        ),
      ),
    );

    smashCoverPreferences = await carregarPreferenciasCapaSmashPrefs();

    if (perfilEditado != null) {
      setState(() {
        perfil = perfilEditado;
      });

      await salvarDados();
    }
  }

  void abrirConfiguracoes() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConfiguracoesPage(
          pastaBackupPath: pastaBackupPath,
          exportarBackup: exportarBackup,
          importarBackupMaisRecente: importarBackupMaisRecente,
          abrirPerfil: abrirPerfil,
        ),
      ),
    );
  }

  void voltarTelaAnterior() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }

    irParaSelecaoDeJogos(context);
  }

  void executarAcaoMenuHome(_HomePageMenuAction acao) {
    switch (acao) {
      case _HomePageMenuAction.perfil:
        abrirPerfil();
        break;
      case _HomePageMenuAction.configuracoes:
        abrirConfiguracoes();
        break;
      case _HomePageMenuAction.resetar:
        resetarDados();
        break;
    }
  }

  List<Widget> construirAcoesAppBar(bool compacta) {
    if (compacta) {
      return [
        const HomeNavigationButton(),
        PopupMenuButton<_HomePageMenuAction>(
          tooltip: 'Mais opções',
          icon: const Icon(Icons.more_vert),
          onSelected: executarAcaoMenuHome,
          itemBuilder: (context) {
            return const [
              PopupMenuItem(
                value: _HomePageMenuAction.perfil,
                child: ListTile(
                  leading: Icon(Icons.person_outline),
                  title: Text('Meu perfil'),
                ),
              ),
              PopupMenuItem(
                value: _HomePageMenuAction.configuracoes,
                child: ListTile(
                  leading: Icon(Icons.settings_outlined),
                  title: Text('Configurações'),
                ),
              ),
              PopupMenuItem(
                value: _HomePageMenuAction.resetar,
                child: ListTile(
                  leading: Icon(Icons.delete_outline),
                  title: Text('Resetar dados'),
                ),
              ),
            ];
          },
        ),
      ];
    }

    return [
      const HomeNavigationButton(),
      IconButton(
        onPressed: abrirPerfil,
        tooltip: 'Meu perfil',
        icon: const Icon(Icons.person_outline),
      ),
      IconButton(
        onPressed: abrirConfiguracoes,
        tooltip: 'Configurações e backup',
        icon: const Icon(Icons.settings_outlined),
      ),
      IconButton(
        onPressed: resetarDados,
        tooltip: 'Resetar dados',
        icon: const Icon(Icons.delete_outline),
      ),
    ];
  }

  int get totalPartidasDoJogo {
    return historicoDoContextoAtual.length;
  }

  int get totalVitorias {
    return historicoDoContextoAtual
        .where((partida) => resultadoEhVitoria(partida.resultado))
        .length;
  }

  int get totalDerrotas {
    return historicoDoContextoAtual
        .where((partida) => resultadoEhDerrota(partida.resultado))
        .length;
  }

  int get lpTimePrincipal {
    if (!timePrincipalInvincible.completo) return 0;

    int lp = 0;
    final List<PartidaRegistrada> partidasDoTime = historicoDoContextoAtual;

    for (final partida in partidasDoTime.reversed) {
      lp += partida.pdlGerado;
      if (lp < 0) lp = 0;
    }

    return lp;
  }

  Character personagemReferenciaAtual() {
    if (widget.jogoAtual == jogoInvincibleVs &&
        timePrincipalInvincible.slot1.isNotEmpty &&
        personagens.containsKey(timePrincipalInvincible.slot1)) {
      return personagens[timePrincipalInvincible.slot1]!;
    }

    return personagemAtual;
  }

  @override
  Widget build(BuildContext context) {
    if (carregando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final bool isInvincible = widget.jogoAtual == jogoInvincibleVs;
    final bool isStreetFighter = widget.jogoAtual == jogoStreetFighter6;
    final Character personagem = personagemAtual;
    final String pontosLabel = labelPontosRank(widget.jogoAtual);
    final String contextoAtual = isInvincible
        ? (timePrincipalInvincible.completo
              ? timePrincipalInvincible.texto
              : 'Nenhum time principal definido')
        : personagem.name;
    final bool appBarCompacta = MediaQuery.sizeOf(context).width < 480;

    return Scaffold(
      appBar: AppBar(
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          child: LtLogo(scale: 0.8, showProgress: false),
        ),
        centerTitle: true,
        leading: IconButton(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          padding: const EdgeInsets.all(12),
          visualDensity: VisualDensity.standard,
          onPressed: voltarTelaAnterior,
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back),
        ),
        actions: construirAcoesAppBar(appBarCompacta),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bem-vindo, ${perfil.nick}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            if (isInvincible)
              Text(
                perfil.regiao.trim().isEmpty
                    ? '${widget.jogoAtual} - $contextoAtual'
                    : '${widget.jogoAtual} - $contextoAtual - ${perfil.regiao}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            if (!isInvincible)
              Text(
                perfil.regiao.trim().isEmpty
                    ? '${widget.jogoAtual} • ${personagem.name}'
                    : '${widget.jogoAtual} • ${personagem.name} • ${perfil.regiao}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            const SizedBox(height: 32),
            Card(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bool isMobileCard = constraints.maxWidth < 520;
                  final double avatarSize = isMobileCard ? 56 : 68;

                  final bool timeCompleto = timePrincipalInvincible.completo;
                  final int lpTime = lpTimePrincipal;
                  final String rankTime = calcularRankDoJogo(
                    widget.jogoAtual,
                    lpTime,
                  );
                  final List<String> nomesTime =
                      timePrincipalInvincible.personagens;

                  final Widget avatar = isInvincible
                      ? SizedBox(
                          width: isMobileCard ? double.infinity : 188,
                          child: Wrap(
                            alignment: isMobileCard
                                ? WrapAlignment.center
                                : WrapAlignment.start,
                            spacing: 8,
                            runSpacing: 8,
                            children: timeCompleto
                                ? [
                                    for (final nome in nomesTime)
                                      CharacterAvatar(
                                        personagem: nome,
                                        jogo: widget.jogoAtual,
                                        size: avatarSize,
                                        initialOverride:
                                            personagens[nome]?.initial,
                                      ),
                                  ]
                                : [
                                    CircleAvatar(
                                      radius: avatarSize / 2,
                                      child: const Icon(Icons.groups_outlined),
                                    ),
                                  ],
                          ),
                        )
                      : CharacterAvatar(
                          personagem: personagem.name,
                          jogo: widget.jogoAtual,
                          size: avatarSize,
                          initialOverride: personagem.initial,
                          smashCoverPreferences: smashCoverPreferences,
                          usarPreferenciaVisualSmash: true,
                        );

                  final Widget perfilInfo = Column(
                    crossAxisAlignment: isMobileCard
                        ? CrossAxisAlignment.center
                        : CrossAxisAlignment.start,
                    children: [
                      Text(
                        isInvincible
                            ? 'Time Atual'
                            : isStreetFighter
                            ? 'Personagem Atual'
                            : 'Perfil atual',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: isMobileCard
                            ? TextAlign.center
                            : TextAlign.start,
                        style: TextStyle(
                          fontSize: isMobileCard ? 20 : 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Jogo: ${widget.jogoAtual}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: isMobileCard
                            ? TextAlign.center
                            : TextAlign.start,
                      ),
                      if (isInvincible)
                        Text(
                          'Time: $contextoAtual',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          textAlign: isMobileCard
                              ? TextAlign.center
                              : TextAlign.start,
                        )
                      else
                        Text(
                          'Personagem: ${personagem.name}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: isMobileCard
                              ? TextAlign.center
                              : TextAlign.start,
                        ),
                      const SizedBox(height: 6),
                      Wrap(
                        alignment: isMobileCard
                            ? WrapAlignment.center
                            : WrapAlignment.start,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          const Text('Rank:'),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: RankBadge(
                              rank: isInvincible ? rankTime : personagem.rank,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isInvincible
                            ? '$pontosLabel do time: $lpTime'
                            : '$pontosLabel: ${personagem.pdl}',
                      ),
                    ],
                  );

                  final Widget trocarButton = SizedBox(
                    width: isMobileCard ? double.infinity : null,
                    child: OutlinedButton(
                      onPressed: isInvincible
                          ? abrirMontarTimePrincipal
                          : abrirSelecaoDePersonagem,
                      child: Text(
                        isInvincible
                            ? (timeCompleto ? 'Alterar Time' : 'Montar Time')
                            : isStreetFighter
                            ? 'Selecionar Personagem'
                            : 'Trocar personagem',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );

                  return Padding(
                    padding: EdgeInsets.all(isMobileCard ? 16 : 20),
                    child: isMobileCard
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              avatar,
                              const SizedBox(height: 14),
                              perfilInfo,
                              const SizedBox(height: 16),
                              trocarButton,
                            ],
                          )
                        : Row(
                            children: [
                              avatar,
                              const SizedBox(width: 20),
                              Expanded(child: perfilInfo),
                              const SizedBox(width: 12),
                              trocarButton,
                            ],
                          ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: InfoBox(
                        titulo: 'Partidas',
                        valor: '$totalPartidasDoJogo',
                      ),
                    ),
                    Expanded(
                      child: InfoBox(
                        titulo: 'Vitórias',
                        valor: '$totalVitorias',
                      ),
                    ),
                    Expanded(
                      child: InfoBox(
                        titulo: 'Derrotas',
                        valor: '$totalDerrotas',
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
                  child: ElevatedButton(
                    onPressed: () => abrirRegistrarPartida(),
                    child: const Text('Registrar partida'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: abrirHistorico,
                    child: const Text('Ver histórico'),
                  ),
                ),
              ],
            ),
            if (ultimaPartidaDoContextoAtual != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: abrirRepetirUltimaPartida,
                  icon: const Icon(Icons.replay_outlined),
                  label: const Text('Repetir ultima partida'),
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: abrirEstatisticas,
                icon: const Icon(Icons.bar_chart),
                label: const Text('Ver estatísticas'),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: abrirResumoTreino,
                icon: const Icon(Icons.today_outlined),
                label: Text(
                  widget.jogoAtual == jogoInvincibleVs
                      ? 'Leitura de times'
                      : 'Resumo do treino de hoje',
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: abrirPerfil,
                icon: const Icon(Icons.person_outline),
                label: const Text('Meu perfil'),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: abrirConfiguracoes,
                icon: const Icon(Icons.backup_outlined),
                label: const Text('Backup e configurações'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
