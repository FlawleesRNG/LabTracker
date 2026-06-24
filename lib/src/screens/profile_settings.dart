part of '../../main.dart';

class PerfilJogadorPage extends StatefulWidget {
  final PlayerProfile perfil;
  final Character personagemAtual;
  final String jogoAtual;
  final Map<String, String> smashCoverPreferences;
  final Future<void> Function(String personagem, String preferencia)
  onSmashCoverPreferenceChanged;

  const PerfilJogadorPage({
    super.key,
    required this.perfil,
    required this.personagemAtual,
    required this.jogoAtual,
    required this.smashCoverPreferences,
    required this.onSmashCoverPreferenceChanged,
  });

  @override
  State<PerfilJogadorPage> createState() => _PerfilJogadorPageState();
}

class _PerfilJogadorPageState extends State<PerfilJogadorPage> {
  late TextEditingController nickController;
  late TextEditingController regiaoController;
  late Map<String, String> smashCoverPreferences;
  Map<String, List<String>> personagensFavoritosPorJogo = {};
  Map<String, List<String>> personagensRecentesPorJogo = {};
  List<PartidaRegistrada> historicoPersistido = [];

  @override
  void initState() {
    super.initState();
    nickController = TextEditingController(text: widget.perfil.nick);
    regiaoController = TextEditingController(text: widget.perfil.regiao);
    smashCoverPreferences = {...widget.smashCoverPreferences};
    carregarPerfilPorJogo();
  }

  @override
  void dispose() {
    nickController.dispose();
    regiaoController.dispose();
    super.dispose();
  }

  void salvarPerfil() {
    if (nickController.text.trim().isEmpty) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Nick não informado'),
            content: const Text('Digite seu nick antes de salvar o perfil.'),
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

    final PlayerProfile perfilEditado = widget.perfil.copyWith(
      nick: nickController.text.trim(),
      regiao: regiaoController.text.trim(),
      tagSecundaria: '',
      jogoPrincipal: '',
      mainPrincipal: '',
      bio: '',
    );

    Navigator.pop(context, perfilEditado);
  }

  bool get mostrarPreferenciasCapaSmash {
    return jogoEhSmash(widget.jogoAtual);
  }

  Future<void> carregarPerfilPorJogo() async {
    final Map<String, List<String>> favoritos =
        await carregarPersonagensFavoritosPorJogo();
    final Map<String, List<String>> recentes =
        await carregarPersonagensRecentesPorJogo();
    final List<PartidaRegistrada> historico =
        await carregarHistoricoPersistido();

    if (!mounted) return;

    setState(() {
      personagensFavoritosPorJogo = favoritos;
      personagensRecentesPorJogo = recentes;
      historicoPersistido = historico;
    });
  }

  Future<void> alterarCapaSmash(String personagem) async {
    final String nome = normalizarPersonagemCapaSmash(personagem);
    final List<SmashCoverOption> opcoes = opcoesCapaSmash(nome);
    if (opcoes.isEmpty) return;

    final String preferenciaAtual = smashCoverPreferences[nome] ?? '';

    final String? preferenciaEscolhida = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        return ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text(
              'Escolha a capa de $nome',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(
                preferenciaAtual.isEmpty
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
              ),
              title: const Text('Padrão'),
              onTap: () {
                Navigator.pop(context, '');
              },
            ),
            for (final opcao in opcoes)
              ListTile(
                leading: Icon(
                  preferenciaAtual == opcao.id
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                ),
                title: Text(opcao.label),
                onTap: () {
                  Navigator.pop(context, opcao.id);
                },
              ),
          ],
        );
      },
    );

    if (preferenciaEscolhida == null) return;

    await widget.onSmashCoverPreferenceChanged(nome, preferenciaEscolhida);

    if (!mounted) return;

    setState(() {
      final Map<String, String> novasPreferencias = {...smashCoverPreferences};

      if (preferenciaEscolhida.isEmpty) {
        novasPreferencias.remove(nome);
      } else {
        novasPreferencias[nome] = preferenciaEscolhida;
      }

      smashCoverPreferences = novasPreferencias;
    });
  }

  Widget cardPreferenciasCapaSmash() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Aparência do personagem',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text('Super Smash Bros. Ultimate'),
            const SizedBox(height: 12),
            for (final personagem in personagensSmashComPreferenciaCapa)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CharacterAvatar(
                  personagem: personagem,
                  jogo: jogoSmashUltimate,
                  size: 44,
                  smashCoverPreferences: smashCoverPreferences,
                  usarPreferenciaVisualSmash: true,
                ),
                title: Text(personagem),
                subtitle: Text(
                  'Capa atual: ${rotuloPreferenciaCapaSmash(personagem, smashCoverPreferences)}',
                ),
                trailing: TextButton(
                  onPressed: () {
                    alterarCapaSmash(personagem);
                  },
                  child: const Text('Alterar capa'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget cardPerfilPorJogo() {
    final Map<String, GameUsageStats> usoPorJogo = calcularUsoPorJogo(
      historicoPersistido,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Perfil por jogo',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            for (final jogo in jogosDisponiveis)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  jogo == widget.jogoAtual
                      ? Icons.sports_esports
                      : Icons.videogame_asset_outlined,
                ),
                title: Text(jogo, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  [
                    '${usoPorJogo[jogo]?.partidas ?? 0} partidas',
                    if ((personagensRecentesPorJogo[jogo] ?? const [])
                        .isNotEmpty)
                      'Ultimo: ${(personagensRecentesPorJogo[jogo] ?? const []).first}',
                    if ((personagensFavoritosPorJogo[jogo] ?? const [])
                        .isNotEmpty)
                      'Favoritos: ${(personagensFavoritosPorJogo[jogo] ?? const []).take(3).join(', ')}',
                  ].join(' - '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meu perfil'), centerTitle: true),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Meu perfil',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Mantenha só o essencial: seu nick e, se quiser, sua região.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        TextField(
                          controller: nickController,
                          decoration: const InputDecoration(
                            labelText: 'Nick',
                            border: OutlineInputBorder(),
                            hintText: 'Ex: Flawlees',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: regiaoController,
                          decoration: const InputDecoration(
                            labelText: 'Região opcional',
                            border: OutlineInputBorder(),
                            hintText: 'Ex: SC - Brasil',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                cardPerfilPorJogo(),
                if (mostrarPreferenciasCapaSmash) ...[
                  const SizedBox(height: 16),
                  cardPreferenciasCapaSmash(),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: salvarPerfil,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Salvar perfil'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ConfiguracoesPage extends StatelessWidget {
  static const String versaoApp = '1.0.0-alpha';
  static const String emailSugestoes = 'guilhermegafelipi@gmail.com';
  static const String textoProjetoIndependente =
      'LabTracker é um projeto independente de acompanhamento de partidas.\n'
      'Este app não é afiliado, patrocinado ou aprovado pela Nintendo ou por qualquer publicadora dos jogos mencionados.\n'
      'Marcas, nomes e personagens pertencem aos seus respectivos donos.';

  final String pastaBackupPath;
  final Future<String> Function() exportarBackup;
  final Future<String> Function() importarBackupMaisRecente;
  final Future<void> Function() abrirPerfil;

  const ConfiguracoesPage({
    super.key,
    required this.pastaBackupPath,
    required this.exportarBackup,
    required this.importarBackupMaisRecente,
    required this.abrirPerfil,
  });

  Future<void> mostrarMensagem(
    BuildContext context,
    String titulo,
    String mensagem,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(titulo),
          content: SelectableText(mensagem),
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

  Future<void> enviarSugestao(BuildContext context) async {
    final Uri uri = Uri(
      scheme: 'mailto',
      path: emailSugestoes,
      queryParameters: const {
        'subject': 'Sugestão para o LabTracker',
        'body': 'Olá, tenho uma sugestão para o LabTracker:\n\n',
      },
    );

    final bool abriu = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!abriu && context.mounted) {
      await mostrarMensagem(
        context,
        'Enviar sugestão',
        'Não foi possível abrir o app de email automaticamente.\n\n'
            'Envie sua sugestão para:\n\n$emailSugestoes',
      );
    }
  }

  Future<void> mostrarSobre(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sobre o LabTracker'),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'LabTracker',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('Criado por: Guilherme Felipi / FlawleesRNG'),
                Text('Versão: 1.0.0-alpha'),
                SizedBox(height: 16),
                Text(
                  'Projeto para acompanhar partidas, evolução, estatísticas, matchups e pontos de melhoria.',
                ),
                SizedBox(height: 16),
                SelectableText(textoProjetoIndependente),
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                enviarSugestao(context);
              },
              icon: const Icon(Icons.mail_outline),
              label: const Text('Enviar sugestão'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> mostrarGlossario(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.82,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              children: const [
                Text(
                  'Glossário de golpes',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Guia rápido para entender as nomenclaturas usadas no registro de partidas.',
                ),
                SizedBox(height: 20),
                LinhaEstatistica(titulo: 'Jab', valor: 'Ataque neutro rápido'),
                LinhaEstatistica(titulo: 'F-tilt', valor: 'Tilt para frente'),
                LinhaEstatistica(titulo: 'Up tilt', valor: 'Tilt para cima'),
                LinhaEstatistica(titulo: 'Down tilt', valor: 'Tilt para baixo'),
                LinhaEstatistica(titulo: 'F-smash', valor: 'Smash para frente'),
                LinhaEstatistica(titulo: 'Up smash', valor: 'Smash para cima'),
                LinhaEstatistica(
                  titulo: 'Down smash',
                  valor: 'Smash para baixo',
                ),
                LinhaEstatistica(titulo: 'Nair', valor: 'Aerial neutro'),
                LinhaEstatistica(titulo: 'Fair', valor: 'Aerial para frente'),
                LinhaEstatistica(titulo: 'Bair', valor: 'Aerial para trás'),
                LinhaEstatistica(titulo: 'Up air', valor: 'Aerial para cima'),
                LinhaEstatistica(
                  titulo: 'Down air',
                  valor: 'Aerial para baixo',
                ),
                LinhaEstatistica(titulo: 'Neutral B', valor: 'Especial neutro'),
                LinhaEstatistica(titulo: 'Side B', valor: 'Especial lateral'),
                LinhaEstatistica(
                  titulo: 'Up B',
                  valor: 'Especial para cima / recovery',
                ),
                LinhaEstatistica(
                  titulo: 'Down B',
                  valor: 'Especial para baixo',
                ),
                LinhaEstatistica(titulo: 'Grab', valor: 'Agarrão'),
                LinhaEstatistica(
                  titulo: 'Forward throw',
                  valor: 'Arremesso para frente',
                ),
                LinhaEstatistica(
                  titulo: 'Back throw',
                  valor: 'Arremesso para trás',
                ),
                LinhaEstatistica(
                  titulo: 'Up throw',
                  valor: 'Arremesso para cima',
                ),
                LinhaEstatistica(
                  titulo: 'Down throw',
                  valor: 'Arremesso para baixo',
                ),
                LinhaEstatistica(
                  titulo: 'Spike',
                  valor: 'Golpe que manda para baixo',
                ),
                LinhaEstatistica(
                  titulo: 'Shield break',
                  valor: 'Quebra de escudo',
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> confirmarImportacao(BuildContext context) async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Importar backup?'),
          content: const Text(
            'Isso vai substituir os dados atuais pelo backup mais recente encontrado na pasta de backups.',
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
              child: const Text('Importar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    try {
      final String caminho = await importarBackupMaisRecente();

      if (!context.mounted) return;

      await mostrarMensagem(
        context,
        'Backup importado',
        'Dados restaurados com sucesso de:\n\n$caminho',
      );
    } catch (erro) {
      if (!context.mounted) return;

      await mostrarMensagem(
        context,
        'Erro ao importar',
        erro.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> executarExportacao(BuildContext context) async {
    try {
      final String caminho = await exportarBackup();

      if (!context.mounted) return;

      await mostrarMensagem(
        context,
        'Backup exportado',
        'Backup salvo com sucesso em:\n\n$caminho',
      );
    } catch (erro) {
      if (!context.mounted) return;

      await mostrarMensagem(
        context,
        'Erro ao exportar',
        erro.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup e configurações'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Backup local',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Exporte seus dados para não perder histórico, PDL, ranks e observações.',
            ),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Meu perfil'),
                subtitle: const Text('Editar nick e região.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: abrirPerfil,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Glossário de golpes'),
                subtitle: const Text(
                  'Entenda termos como Up B, Bair, F-tilt e throws.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  mostrarGlossario(context);
                },
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Sobre o LabTracker'),
                subtitle: const Text('Versão, créditos e envio de sugestão.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  mostrarSobre(context);
                },
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
                      'Pasta dos backups',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SelectableText(pastaBackupPath),
                    const SizedBox(height: 12),
                    const Text(
                      'Os arquivos são salvos em formato .json. Você pode copiar essa pasta para o Drive, pendrive ou outro PC.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  executarExportacao(context);
                },
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('Exportar backup'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  confirmarImportacao(context);
                },
                icon: const Icon(Icons.download_outlined),
                label: const Text('Importar backup mais recente'),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Como usar',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      '1. Clique em Exportar backup depois de sessões importantes.\n'
                      '2. Guarde o arquivo .json em um lugar seguro.\n'
                      '3. Para restaurar, coloque o arquivo na pasta de backups e clique em Importar backup mais recente.',
                    ),
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
