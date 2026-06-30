part of '../../main.dart';

class AnaliseComparativaItem {
  final String nome;
  final int total;
  final int vitorias;
  final int derrotas;
  final int saldoPdl;

  const AnaliseComparativaItem({
    required this.nome,
    required this.total,
    required this.vitorias,
    required this.derrotas,
    required this.saldoPdl,
  });

  double get winrate => total == 0 ? 0 : (vitorias / total) * 100;
}

class EvolucaoPdlPonto {
  final int partida;
  final int saldo;

  const EvolucaoPdlPonto({required this.partida, required this.saldo});
}

List<AnaliseComparativaItem> gerarComparativoPorCampo(
  List<PartidaRegistrada> partidas,
  String Function(PartidaRegistrada partida) seletor,
) {
  final Map<String, List<PartidaRegistrada>> grupos = {};

  for (final partida in partidas) {
    final String nome = seletor(partida).trim();
    if (nome.isEmpty || nome == 'Sem dados') continue;

    grupos.putIfAbsent(nome, () => []);
    grupos[nome]!.add(partida);
  }

  final List<AnaliseComparativaItem> ranking = grupos.entries.map((entry) {
    final List<PartidaRegistrada> partidasDoGrupo = entry.value;
    final int total = partidasDoGrupo.length;
    final int vitorias = partidasDoGrupo
        .where((partida) => partida.resultado == 'Vitória')
        .length;
    final int derrotas = partidasDoGrupo
        .where((partida) => partida.resultado == 'Derrota')
        .length;
    final int saldoPdl = partidasDoGrupo.fold(
      0,
      (soma, partida) => soma + partida.pdlGerado,
    );

    return AnaliseComparativaItem(
      nome: entry.key,
      total: total,
      vitorias: vitorias,
      derrotas: derrotas,
      saldoPdl: saldoPdl,
    );
  }).toList();

  ranking.sort((a, b) {
    final int totalCompare = b.total.compareTo(a.total);
    if (totalCompare != 0) return totalCompare;

    final int winrateCompare = b.winrate.compareTo(a.winrate);
    if (winrateCompare != 0) return winrateCompare;

    return b.saldoPdl.compareTo(a.saldoPdl);
  });

  return ranking;
}

List<EvolucaoPdlPonto> gerarEvolucaoPdl(List<PartidaRegistrada> partidas) {
  final List<PartidaRegistrada> cronologico = partidas.reversed.toList();
  final List<EvolucaoPdlPonto> pontos = [];
  int saldo = 0;

  for (int i = 0; i < cronologico.length; i++) {
    saldo += cronologico[i].pdlGerado;
    pontos.add(EvolucaoPdlPonto(partida: i + 1, saldo: saldo));
  }

  return pontos;
}

DateTime mesAnteriorDe(DateTime data) {
  if (data.month == 1) {
    return DateTime(data.year - 1, 12);
  }

  return DateTime(data.year, data.month - 1);
}

bool mesmoMesAno(DateTime data, DateTime referencia) {
  return data.year == referencia.year && data.month == referencia.month;
}

String nomeMesCurto(int mes) {
  const meses = [
    'Jan',
    'Fev',
    'Mar',
    'Abr',
    'Mai',
    'Jun',
    'Jul',
    'Ago',
    'Set',
    'Out',
    'Nov',
    'Dez',
  ];

  return meses[mes - 1];
}

String rotuloMesAno(DateTime data) {
  return '${nomeMesCurto(data.month)} ${data.year}';
}

List<DateTime> gerarMesesDisponiveis(List<PartidaRegistrada> partidas) {
  final Set<String> chaves = {};
  final List<DateTime> meses = [];

  for (final partida in partidas) {
    final String chave = '${partida.data.year}-${partida.data.month}';
    if (chaves.add(chave)) {
      meses.add(DateTime(partida.data.year, partida.data.month));
    }
  }

  meses.sort((a, b) => b.compareTo(a));
  return meses;
}

String resumoMes(List<PartidaRegistrada> partidas, DateTime referencia) {
  final List<PartidaRegistrada> partidasDoMes = partidas
      .where((partida) => mesmoMesAno(partida.data, referencia))
      .toList();

  if (partidasDoMes.isEmpty) {
    return '${rotuloMesAno(referencia)}: sem partidas';
  }

  final int total = partidasDoMes.length;
  final int vitorias = partidasDoMes
      .where((partida) => partida.resultado == 'Vitória')
      .length;
  final int saldo = partidasDoMes.fold(
    0,
    (soma, partida) => soma + partida.pdlGerado,
  );
  final double winrate = (vitorias / total) * 100;

  return '${rotuloMesAno(referencia)}: $total partidas • ${winrate.toStringAsFixed(1)}% WR • ${formatarSaldo(saldo)} PDL';
}

bool contemAlgum(String texto, List<String> termos) {
  final String normalizado = normalizarTexto(texto);
  return termos.any((termo) => normalizado.contains(normalizarTexto(termo)));
}

bool mapaTemLateralCurta(String mapa) {
  return contemAlgum(mapa, [
    'Smashville',
    'Town',
    'Cidade',
    'Yoshi',
    'Hollow Bastion',
  ]);
}

bool mapaFavoreceVertical(String mapa) {
  return contemAlgum(mapa, [
    'Battlefield',
    'Campo de Batalha',
    'Yoshi',
    'Small Battlefield',
    'Pequeno Campo',
  ]);
}

bool personagemPesado(String personagem) {
  return contemAlgum(personagem, [
    'Bowser',
    'Donkey Kong',
    'King K. Rool',
    'King Dedede',
    'Ganondorf',
    'Incineroar',
    'Ridley',
    'Kazuya',
    'Charizard',
  ]);
}

bool personagemLeveOuFragil(String personagem) {
  return contemAlgum(personagem, [
    'Pichu',
    'Pikachu',
    'Jigglypuff',
    'Kirby',
    'Fox',
    'Sheik',
    'Greninja',
    'Sonic',
    'Sora',
    'Mr. Game',
    'Meta Knight',
  ]);
}

bool personagemZoner(String personagem) {
  return contemAlgum(personagem, [
    'Samus',
    'Dark Samus',
    'Link',
    'Young Link',
    'Toon Link',
    'Mega Man',
    'Snake',
    'Duck Hunt',
    'Simon',
    'Richter',
    'Min Min',
    'Steve',
    'Villager',
    'Isabelle',
    'Pac-Man',
    'Robin',
    'Hero',
    'Mii Gunner',
  ]);
}

bool personagemEspadachim(String personagem) {
  return contemAlgum(personagem, [
    'Cloud',
    'Marth',
    'Lucina',
    'Roy',
    'Chrom',
    'Ike',
    'Shulk',
    'Corrin',
    'Byleth',
    'Sephiroth',
    'Pyra',
    'Mythra',
    'Sora',
    'Link',
    'Meta Knight',
    'Mii Swordfighter',
  ]);
}

bool personagemRushdown(String personagem) {
  return contemAlgum(personagem, [
    'Fox',
    'Falco',
    'Captain Falcon',
    'Mario',
    'Roy',
    'Chrom',
    'Joker',
    'Pikachu',
    'Pichu',
    'Sheik',
    'Sonic',
    'Mythra',
    'Zero Suit',
    'Greninja',
    'Ken',
    'Ryu',
    'Terry',
    'Kazuya',
  ]);
}

bool personagemRecoveryExploravel(String personagem) {
  return contemAlgum(personagem, [
    'Cloud',
    'Little Mac',
    'Chrom',
    'Ike',
    'Ganondorf',
    'Dr. Mario',
    'Simon',
    'Richter',
    'Kazuya',
    'Donkey Kong',
    'Captain Falcon',
  ]);
}

bool mapaPlano(String mapa) {
  return contemAlgum(mapa, ['Final Destination', 'Kalos', 'Pokémon Stadium']);
}

String arquetipoPersonagem(String personagem) {
  if (personagemPesado(personagem)) return 'pesado';
  if (personagemZoner(personagem)) return 'zoner';
  if (personagemEspadachim(personagem)) return 'espadachim';
  if (personagemRushdown(personagem)) return 'rushdown';
  if (personagemLeveOuFragil(personagem)) return 'leve';
  return 'all-rounder';
}

String planoKoPorPersonagem(String personagem) {
  final String nome = normalizarTexto(personagem);

  if (nome.contains('cloud')) {
    return 'F-tilt, back air na lateral e Limit Cross Slash quando tiver limit';
  }
  if (nome.contains('hero')) {
    return 'F-tilt perto da ledge, magia de pressão e finalização segura depois de forçar shield/ledge';
  }
  if (nome.contains('terry')) {
    return 'Buster Wolf, Power Geyser e confirms seguros em vez de se comprometer fora do palco';
  }
  if (nome.contains('kazuya')) {
    return 'punish forte, confirm pesado e pressão de ledge sem overcommit';
  }
  if (nome.contains('ryu') || nome.contains('ken')) {
    return 'confirm de tilt/close hit, Shoryuken e pressão segura de shield';
  }
  if (nome.contains('mario')) {
    return 'back throw perto da ledge, up smash e pressão de ledgetrap';
  }
  if (nome.contains('luigi')) {
    return 'grab confirm, up B punish e ledgetrap simples em vez de chase arriscado';
  }
  if (nome.contains('peach') || nome.contains('daisy')) {
    return 'pressão de float, back air/forward air e punish depois de forçar shield';
  }
  if (nome.contains('yoshi')) {
    return 'up air/forward air em vantagem, pressão aérea e ledgetrap com egg';
  }
  if (nome.contains('kirby')) {
    return 'edgeguard controlado, back air e punish perto da ledge';
  }
  if (nome.contains('fox')) {
    return 'up smash de punish, back air na lateral e ledgetrap rápido';
  }
  if (nome.contains('falco')) {
    return 'juggle com up air, back air e punish de landing';
  }
  if (nome.contains('pikachu') || nome.contains('pichu')) {
    return 'edgeguard seguro, thunder quando preparado e pressão fora do palco só com vantagem';
  }
  if (nome.contains('ness')) {
    return 'back throw na ledge, PK Fire para forçar reação e ledgetrap';
  }
  if (nome.contains('lucas')) {
    return 'back throw, zair/PK pressure e edgeguard controlado';
  }
  if (nome.contains('captain falcon')) {
    return 'knee confirm, stomp quando houver leitura clara e back air na lateral';
  }
  if (nome.contains('jigglypuff')) {
    return 'edgeguard, rest punish quando garantido e back air wall perto da ledge';
  }
  if (nome.contains('bowser')) {
    return 'side B, back air e pressão de ledge sem se expor demais';
  }
  if (nome.contains('donkey kong')) {
    return 'grab/cargo perto da ledge, back air e punish pesado quando o adversário errar';
  }
  if (nome.contains('king k') || nome.contains('k rool')) {
    return 'crown/cannon para forçar reação, back air e ledgetrap pesado';
  }
  if (nome.contains('king dedede')) {
    return 'gordo para ledgetrap, back air e punish quando o adversário respeitar a ledge';
  }
  if (nome.contains('ganondorf')) {
    return 'punish forte, ledgetrap simples e leitura de roll/landing em vez de chase longo';
  }
  if (nome.contains('incineroar')) {
    return 'Alolan Whip/side B, punish de shield e ledgetrap depois de condicionar defesa';
  }
  if (nome.contains('ridley')) {
    return 'back air, ledgetrap e punish de recovery/landing com alcance';
  }
  if (nome.contains('ice climbers')) {
    return 'grab/confirm quando os dois estiverem juntos e ledgetrap sem separar demais';
  }
  if (nome.contains('sheik')) {
    return 'needle confirm, bouncing fish e edgeguard seguro depois de acumular dano';
  }
  if (nome.contains('zelda')) {
    return 'phantom para ledgetrap, lightning kick espaçado e punish de aproximação';
  }
  if (nome.contains('dr mario')) {
    return 'back throw, up B punish e ledgetrap sem ir longe demais offstage';
  }
  if (nome.contains('marth')) {
    return 'tipper bem espaçado, F-tilt/forward smash na lateral e edgeguard só com vantagem clara';
  }
  if (nome.contains('lucina')) {
    return 'aerial espaçado, F-tilt/side B na lateral e edgeguard controlado';
  }
  if (nome.contains('roy') || nome.contains('chrom')) {
    return 'jab confirm, pressão de ledge e golpe forte de perto';
  }
  if (nome.contains('ike')) {
    return 'back air, neutral air confirm e ledgetrap com alcance';
  }
  if (nome.contains('corrin')) {
    return 'pin/side B, back air e controle de alcance na ledge';
  }
  if (nome.contains('byleth')) {
    return 'aerial espaçado, up air/forward air e ledgetrap com alcance';
  }
  if (nome.contains('pyra') || nome.contains('mythra')) {
    return 'Pyra para KO lateral/up air e Mythra para ganhar neutral antes de trocar';
  }
  if (nome.contains('shulk')) {
    return 'Monado Smash/Jump conforme situação, aerial espaçado e ledgetrap com alcance';
  }
  if (nome.contains('meta knight')) {
    return 'edgeguard, ladder quando encaixar e back air perto da ledge';
  }
  if (nome.contains('pit')) {
    return 'edgeguard seguro, back air e ledgetrap com arco para cobrir recuperação';
  }
  if (nome.contains('zero suit')) {
    return 'flip kick quando preparado, back air e punish de landing';
  }
  if (nome.contains('wario')) {
    return 'Waft confirm, back air e ledgetrap enquanto espera recurso';
  }
  if (nome.contains('snake')) {
    return 'controle de granada, C4, up tilt e ledgetrap explosivo';
  }
  if (nome.contains('pokemon trainer')) {
    return 'Ivysaur up air/down air, Charizard back air e Squirtle para ganhar neutral';
  }
  if (nome.contains('diddy')) {
    return 'banana confirm, ledgetrap e punish de escorregão/roll';
  }
  if (nome.contains('sonic')) {
    return 'whiff punish, back air, edgeguard seguro e controle de tempo';
  }
  if (nome.contains('olimar')) {
    return 'acúmulo com pikmin, purple/strong hit na lateral e anti-air quando o adversário força entrada';
  }
  if (nome.contains('lucario')) {
    return 'Aura Sphere, back air e finalização com aura sem se expor antes da hora';
  }
  if (nome.contains('r.o.b') || nome.contains('rob')) {
    return 'gyro ledgetrap, side B punish e controle de zona antes da kill';
  }
  if (nome.contains('wolf')) {
    return 'back air, down smash na ledge e laser para forçar aproximação';
  }
  if (nome.contains('villager') || nome.contains('isabelle')) {
    return 'ledgetrap com árvore/armadilha, slingshot e punish quando o adversário tenta entrar';
  }
  if (nome.contains('mega man')) {
    return 'lemon/metal blade para condicionar, back air/up tilt e ledgetrap com projéteis';
  }
  if (nome.contains('wii fit')) {
    return 'Deep Breathing, back air e pressão de ledge com bola/sol';
  }
  if (nome.contains('rosalina')) {
    return 'controle com Luma, up air e ledgetrap mantendo distância segura';
  }
  if (nome.contains('little mac')) {
    return 'smash/punish no chão, KO Punch quando disponível e evitar perseguição fora do palco';
  }
  if (nome.contains('greninja')) {
    return 'dash attack/up smash confirm, back air e punish rápido de landing';
  }
  if (nome.contains('palutena')) {
    return 'back air, nair para vantagem e ledgetrap com explosive flame/autoreticle';
  }
  if (nome.contains('pac')) {
    return 'bonus fruit/hydrant para condicionar, bell confirm e ledgetrap criativo';
  }
  if (nome.contains('robin')) {
    return 'Arcfire confirm, Levin aerial e controle de recurso antes da kill';
  }
  if (nome.contains('bowser jr')) {
    return 'Mechakoopa ledgetrap, side B punish e aerial forte na lateral';
  }
  if (nome.contains('duck hunt')) {
    return 'can/shot para controle, ledgetrap e punish quando o adversário salta';
  }
  if (nome.contains('bayonetta')) {
    return 'ladder/witch twist quando seguro, back air e ledgetrap sem overextend';
  }
  if (nome.contains('inkling')) {
    return 'roller punish, back air e ledgetrap depois de pintar/acumular dano';
  }
  if (nome.contains('simon') || nome.contains('richter')) {
    return 'holy water confirm, whip na ledge e controle de espaço com projéteis';
  }
  if (nome.contains('piranha')) {
    return 'Ptooie, ledgetrap e punish quando o adversário respeitar a bola';
  }
  if (nome.contains('joker')) {
    return 'back air na lateral, ledgetrap e pressão com Arsene quando disponível';
  }
  if (nome.contains('banjo')) {
    return 'Wonderwing como punish, grenade/egg para condicionar e ledgetrap';
  }
  if (nome.contains('min min')) {
    return 'controle de braços na lateral, ledgetrap à distância e anti-air antes do adversário entrar';
  }
  if (nome.contains('steve')) {
    return 'minecart/anvil, ledgetrap com bloco e punish após forçar recurso';
  }
  if (nome.contains('sephiroth')) {
    return 'back air/F-tilt espaçado e pressão de ledge com alcance';
  }
  if (nome.contains('sora')) {
    return 'back air, F-smash bem espaçado e pressão de ledge com magia';
  }
  if (nome.contains('mii brawler')) {
    return 'confirm físico, up B/side B conforme kit e ledgetrap simples';
  }
  if (nome.contains('mii sword')) {
    return 'aerial espaçado, tornado/side B conforme kit e ledgetrap com alcance';
  }
  if (nome.contains('mii gunner')) {
    return 'projéteis para forçar pulo, ledgetrap e punish quando o adversário entra';
  }

  if (personagemZoner(personagem)) {
    return 'controle de espaço, ledgetrap com projétil e punish quando o adversário força entrada';
  }
  if (personagemEspadachim(personagem)) {
    return 'aerial espaçado, F-tilt/ledgetrap na lateral e punish sem se expor fora do palco';
  }
  if (personagemPesado(personagem)) {
    return 'punish forte, grab/pressão de ledge e KO lateral sem chase arriscado';
  }
  if (personagemRushdown(personagem)) {
    return 'whiff punish, confirm rápido e pressão de ledge depois de ganhar neutral';
  }

  return 'KO lateral seguro, ledgetrap e punish depois de forçar o adversário para a borda';
}

String planoNeutralPorPersonagem(String personagemAtual, String adversario) {
  final String meuTipo = arquetipoPersonagem(personagemAtual);
  final String tipoAdversario = arquetipoPersonagem(adversario);

  if (tipoAdversario == 'pesado') {
    return 'Plano de matchup: contra personagem pesado, não precisa resolver rápido. Ganhe no acúmulo de dano, force ledge e procure KO seguro; pesado pune muito quando você erra uma kill arriscada.';
  }

  if (tipoAdversario == 'zoner') {
    return 'Plano de matchup: contra zoner, avance por partes. Tire espaço, use shield/parry com calma e só entre quando o projétil estiver gasto ou previsível.';
  }

  if (tipoAdversario == 'rushdown') {
    return 'Plano de matchup: contra rushdown, não aceite trocar botão toda hora. Segure centro, puna aproximação ruim e transforme defesa boa em punish simples.';
  }

  if (tipoAdversario == 'espadachim' && meuTipo != 'zoner') {
    return 'Plano de matchup: contra espadachim, respeite alcance. Tente whiff punish e ledgetrap em vez de disputar hitbox frontal sem vantagem.';
  }

  if (personagemRecoveryExploravel(adversario)) {
    return 'Plano de matchup: o recovery adversário é explorável. Faça edgeguard seguro primeiro; se ele gastar recurso cedo, aí sim procure uma finalização fora do palco.';
  }

  return 'Plano de matchup: jogue para ganhar posição antes da kill. Quando o adversário estiver na ledge, escolha uma finalização estável em vez de procurar highlight toda hora.';
}

String planoPorMapa(String personagemAtual, String adversario, String mapa) {
  if (mapa == 'Todos' || mapa.trim().isEmpty || mapa == 'Sem dados') {
    return 'Plano de mapa: escolha o mapa olhando seu plano de KO. Se seu personagem mata lateral, prefira mapas com ledge/lateral forte; se mata vertical, plataformas ajudam mais.';
  }

  if (mapaTemLateralCurta(mapa)) {
    return 'Plano de mapa: $mapa recompensa KO lateral e ledgetrap. Com $personagemAtual, tente empurrar $adversario para a borda e matar sem precisar sair tanto do palco.';
  }

  if (mapaFavoreceVertical(mapa)) {
    return 'Plano de mapa: $mapa favorece plataforma, juggle e anti-air. Transforme vantagem em pressão vertical antes de procurar a kill final.';
  }

  if (mapaPlano(mapa)) {
    return 'Plano de mapa: $mapa dá menos plataforma para escapar. Controle chão, force reação previsível e puna landings/rolls.';
  }

  return 'Plano de mapa: use o espaço do mapa para controlar ritmo. Se o adversário recuar muito, ganhe centro antes de buscar kill.';
}

String planoDefensivoPorMorte(String personagemAtual, String morteMaisComum) {
  switch (morteMaisComum) {
    case 'SD':
      return 'Defesa: você está perdendo stock sozinho nesse recorte. Reduza perseguições fora do palco e priorize voltar vivo antes de tentar finalizar.';
    case 'Recovery errado':
      return 'Defesa: varie recovery com $personagemAtual. Alterne altura, timing e rota; voltar sempre igual facilita edgeguard.';
    case 'Panic option':
      return 'Defesa: se a pressão apertar, segure mais shield/escape para centro. Panic option vira kill fácil quando o adversário espera sua reação.';
    case 'Punish sofrido':
      return 'Defesa: revise quais golpes você está usando sem segurança. Menos botão no automático e mais whiff punish.';
    case 'Edgeguard sofrido':
      return 'Defesa: evite gastar recurso cedo fora do palco. Guarde jump/recovery quando possível e varie o timing da volta.';
    case 'Ledgetrap sofrido':
      return 'Defesa: na ledge, varie entre esperar, pular, roll e ataque. Se repetir saída, o adversário transforma isso em kill.';
    case 'Morreu cedo':
      return 'Defesa: jogue mais limpo em porcentagem média. Evite trade ruim e revise DI/sobrevivência nos golpes que estão matando cedo.';
    case 'Read do adversário':
      return 'Defesa: o adversário está lendo hábito. Troque o padrão depois de uma ou duas repetições e não responda pressão sempre igual.';
    default:
      return 'Defesa: procure identificar se a morte vem de pressa, ledge ou recovery. Corrigir um padrão defensivo costuma render mais que buscar KO novo.';
  }
}

String gerarDicaTecnicaKoGeral({
  required String personagemAtual,
  required String adversario,
  required String mapa,
  required String killBuscada,
}) {
  final bool temAdversario =
      adversario.trim().isNotEmpty && adversario != 'Sem dados';
  final bool temMapa = mapa.trim().isNotEmpty && mapa != 'Sem dados';
  final bool buscandoSpike = contemAlgum(killBuscada, [
    'Spike',
    'Meteor',
    'Meteoro',
    'Dunk',
    'Offstage',
  ]);
  final bool pesado = personagemPesado(adversario);
  final String plano = planoKoPorPersonagem(personagemAtual);

  final String alvo = temAdversario ? 'contra $adversario' : 'nesse recorte';
  final String local = temMapa ? 'em $mapa' : 'no mapa escolhido';
  final String killTexto =
      killBuscada == 'Sem dados' || killBuscada == 'Não matou'
      ? 'uma kill arriscada'
      : killBuscada;

  if (buscandoSpike && temMapa && mapaTemLateralCurta(mapa)) {
    return 'Dica de KO: com $personagemAtual $alvo $local, se você está buscando muito $killTexto, pode compensar mais jogar para $plano. Esse mapa favorece KO lateral/ledgetrap, então você não precisa se arriscar tanto fora do palco.';
  }

  if (buscandoSpike && pesado) {
    return 'Dica de KO: $adversario é pesado, então forçar spike toda hora pode virar risco desnecessário. Com $personagemAtual, tente primeiro preparar $plano e use spike só quando o recovery do adversário estiver previsível.';
  }

  if (temMapa && mapaFavoreceVertical(mapa)) {
    return 'Dica de KO: $local favorece pressão vertical e controle de plataforma. Com $personagemAtual $alvo, tente transformar vantagem em juggle/anti-air antes de buscar uma finalização arriscada.';
  }

  if (temMapa && mapaTemLateralCurta(mapa)) {
    return 'Dica de KO: $local costuma recompensar controle de lateral. Com $personagemAtual $alvo, jogue para empurrar o adversário para a ledge e procurar $plano.';
  }

  return 'Dica de KO: com $personagemAtual $alvo, o plano mais seguro tende a ser preparar $plano. Use kills arriscadas só quando você já tiver vantagem clara.';
}

List<String> gerarInsightsAvancados(
  List<PartidaRegistrada> partidas, {
  required String personagemAtual,
  String escopo = 'Geral',
  String alvo = 'Todos',
  String mapa = 'Todos',
}) {
  String contexto() {
    final List<String> partes = [personagemAtual];

    if (escopo == 'Personagem' && alvo != 'Todos') {
      partes.add('contra $alvo');
    } else if (escopo == 'Player' && alvo != 'Todos') {
      partes.add('contra o player $alvo');
    }

    if (mapa != 'Todos') {
      partes.add('em $mapa');
    }

    return partes.join(' ');
  }

  final List<String> dicas = [];
  if (partidas.length < 3) {
    dicas.add(
      'Base pequena: ainda há poucas partidas nesse filtro. Use as dicas abaixo como plano geral para ${contexto()} e registre mais jogos para refinar.',
    );
  }
  final String killBuscada = encontrarMaisFrequente(
    partidas.map((partida) => partida.formaDeKill).toList(),
  );
  final String adversarioReferencia = escopo == 'Personagem' && alvo != 'Todos'
      ? alvo
      : encontrarMaisFrequente(
          partidas.map((partida) => partida.personagemAdversario).toList(),
        );
  final String mapaReferencia = mapa != 'Todos'
      ? mapa
      : encontrarMaisFrequente(
          partidas.map((partida) => partida.stage).toList(),
        );

  dicas.add(
    gerarDicaTecnicaKoGeral(
      personagemAtual: personagemAtual,
      adversario: adversarioReferencia,
      mapa: mapaReferencia,
      killBuscada: killBuscada,
    ),
  );

  dicas.add(planoNeutralPorPersonagem(personagemAtual, adversarioReferencia));
  dicas.add(
    planoPorMapa(personagemAtual, adversarioReferencia, mapaReferencia),
  );

  final DateTime agora = DateTime.now();
  final DateTime mesAnterior = mesAnteriorDe(agora);
  final List<PartidaRegistrada> partidasMesAtual = partidas
      .where((partida) => mesmoMesAno(partida.data, agora))
      .toList();
  final List<PartidaRegistrada> partidasMesAnterior = partidas
      .where((partida) => mesmoMesAno(partida.data, mesAnterior))
      .toList();

  if (partidasMesAtual.isNotEmpty && partidasMesAnterior.isNotEmpty) {
    final int saldoAtual = partidasMesAtual.fold(
      0,
      (soma, partida) => soma + partida.pdlGerado,
    );
    final int saldoAnterior = partidasMesAnterior.fold(
      0,
      (soma, partida) => soma + partida.pdlGerado,
    );
    final int diferenca = saldoAtual - saldoAnterior;

    if (diferenca > 0) {
      dicas.add(
        'Você está rendendo melhor agora: neste filtro, seu saldo do mês está ${formatarSaldo(diferenca)} PDL acima do mês anterior.',
      );
    } else if (diferenca < 0) {
      dicas.add(
        'Cuidado com este recorte: seu saldo do mês está ${formatarSaldo(diferenca)} PDL abaixo do mês anterior. Vale revisar as derrotas recentes.',
      );
    }
  }

  final List<AnaliseComparativaItem> porMapa = gerarComparativoPorCampo(
    partidas,
    (partida) => partida.stage,
  ).where((item) => item.total >= 2).toList();

  if (porMapa.isNotEmpty) {
    final List<AnaliseComparativaItem> mapasOrdenados = [...porMapa]
      ..sort((a, b) => b.winrate.compareTo(a.winrate));
    final AnaliseComparativaItem melhorMapa = mapasOrdenados.first;
    dicas.add(
      'Mapa forte com $personagemAtual: ${melhorMapa.nome} aparece com ${melhorMapa.winrate.toStringAsFixed(1)}% de winrate. Se puder escolher stage, considere esse mapa.',
    );
  }

  final List<AnaliseComparativaItem> porMatchup = gerarComparativoPorCampo(
    partidas,
    (partida) => partida.personagemAdversario,
  ).where((item) => item.total >= 2).toList();

  if (porMatchup.isNotEmpty) {
    final List<AnaliseComparativaItem> matchupsOrdenados = [...porMatchup]
      ..sort((a, b) => a.winrate.compareTo(b.winrate));
    final AnaliseComparativaItem matchupProblema = matchupsOrdenados.first;
    dicas.add(
      'Matchup para revisar com $personagemAtual: contra ${matchupProblema.nome}, seu winrate está em ${matchupProblema.winrate.toStringAsFixed(1)}%. Veja como você está morrendo nesse confronto.',
    );
  }

  final Map<String, int> mortesPorMapa = {};
  final Map<String, String> labelMortesPorMapa = {};
  final String morteMaisComum = encontrarMaisFrequente(
    partidas.map((partida) => partida.formaDeMorte).toList(),
  );

  if (morteMaisComum != 'Sem dados' && morteMaisComum != 'Não morreu') {
    dicas.add(planoDefensivoPorMorte(personagemAtual, morteMaisComum));
  }

  for (final partida in partidas) {
    final String morte = partida.formaDeMorte.trim();
    final String stage = partida.stage.trim();
    if (morte.isEmpty || morte == 'Não morreu' || morte == 'Sem dados') {
      continue;
    }
    if (stage.isEmpty) {
      continue;
    }

    final String chave = '${normalizarTexto(stage)}|${normalizarTexto(morte)}';
    mortesPorMapa[chave] = (mortesPorMapa[chave] ?? 0) + 1;
    labelMortesPorMapa.putIfAbsent(chave, () => '$stage|$morte');
  }

  if (mortesPorMapa.isNotEmpty) {
    final entry = mortesPorMapa.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    );
    final List<String> partes = (labelMortesPorMapa[entry.key] ?? '').split(
      '|',
    );
    if (entry.value >= 2 && partes.length == 2) {
      dicas.add(planoDefensivoPorMorte(personagemAtual, partes[1]));
    }
  }

  if (dicas.isEmpty) {
    dicas.add(
      'Ainda não há padrão forte para ${contexto()}. Continue registrando mapa, kill e morte para o LabTracker gerar dicas mais certeiras.',
    );
  }

  final List<String> dicasUnicas = [];
  for (final dica in dicas) {
    if (!dicasUnicas.contains(dica)) {
      dicasUnicas.add(dica);
    }
  }

  return dicasUnicas.take(6).toList();
}
