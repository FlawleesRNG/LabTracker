# Fluxos Por Jogo

O LabTracker usa uma base comum, mas cada jogo pode ter adaptacoes proprias de
registro, rank, historico e estatisticas.

## Fluxo Generico De Personagem Individual

Usado por jogos que ainda nao precisam de registro especifico.

Caracteristicas:

- selecao de personagem principal;
- personagem adversario;
- nick adversario;
- resultado;
- stage/mapa;
- dados de PDL;
- observacoes;
- data da partida;
- historico, filtros e estatisticas.

Tela principal de registro:

- `RegistrarPartidaPage` em `lib/src/screens/match_registration.dart`

## Super Smash Bros. Ultimate

Smash usa personagem base para historico, rank e PDL. A preferencia de capa
male/female e apenas visual.

Caracteristicas:

- personagem principal;
- personagem adversario;
- stage;
- stocks;
- porcentagem final;
- forma de kill e forma de morte;
- preferencia visual de capa em personagens com variacao male/female.

Regra importante:

- salvar sempre `Byleth`, `Corrin`, `Robin`, etc.
- nunca salvar como `Byleth Female` ou criar personagem duplicado.

## Street Fighter 6

Street Fighter usa personagem individual, mas o registro e baseado em rounds.

Caracteristicas:

- personagem principal;
- personagem adversario;
- jogador adversario;
- Round 1, Round 2 e Round 3 quando necessario;
- resultado final automatico;
- placares `2x0`, `2x1`, `0x2`, `1x2`;
- estatisticas de partidas e rounds;
- data da partida.

Telas/classes principais:

- `RegistrarPartidaStreetFighterPage`
- `EstatisticasStreetFighterPage`

Campos salvos em `PartidaRegistrada`:

- `round1Resultado`
- `round2Resultado`
- `round3Resultado`
- `placarRounds`

## Tekken 8

Tekken 8 usa o modelo `3D Fighter`.

Caracteristicas:

- personagem principal;
- personagem adversario;
- stage;
- placar melhor de 5 rounds;
- leitura de parede, Heat, Rage Art, whiff punish e situacao principal;
- rank e PDL proprios do jogo.

Telas/classes principais:

- `RegistrarPartidaTekken8Page`
- `EstatisticasTekken8Page`

## Mortal Kombat 1

Mortal Kombat 1 usa o modelo `2D Fighter / Assist Fighter`.

Caracteristicas:

- personagem principal;
- personagem adversario;
- Kameo adversario;
- placar;
- Fatal Blow, punish, zoneamento, armor e leitura de derrota;
- rank e PDL proprios do jogo.

Telas/classes principais:

- `RegistrarPartidaMortalKombat1Page`
- `EstatisticasMortalKombat1Page`

## Guilty Gear -Strive-

Guilty Gear usa o modelo `2D Fighter / Anime Fighter`.

Caracteristicas:

- personagem principal;
- personagem adversario;
- placar melhor de 3;
- Roman Cancel, Burst, wall break, neutral e defesa;
- rank e PDL proprios do jogo.

Telas/classes principais:

- `RegistrarPartidaGuiltyGearPage`
- `EstatisticasGuiltyGearPage`

## Fatal Fury

Fatal Fury usa o modelo `2D Fighter / SNK Fighter`.

Caracteristicas:

- personagem principal;
- personagem adversario;
- stage;
- placar;
- SPG, REV, feint, lane, punish e situacao principal;
- rank e PDL proprios do jogo.

Telas/classes principais:

- `RegistrarPartidaFatalFuryPage`
- `EstatisticasFatalFuryPage`

## Rivals of Aether II

Rivals II usa o modelo `Platform Fighter`, mas nao recebe funcoes exclusivas do
Smash.

Caracteristicas:

- personagem principal;
- personagem adversario;
- stage;
- stocks;
- porcentagem final;
- recovery, edgeguard, ledge trap e parry;
- rank e PDL proprios do jogo.

Telas/classes principais:

- `RegistrarPartidaRivalsPage`
- `EstatisticasRivalsPage`

## The King of Fighters XV

KOF XV usa time por ordem.

Caracteristicas:

- Point, Mid e Anchor;
- time adversario;
- placar;
- personagem destaque;
- ordem e composicao fazem parte do historico/rank.

Telas/classes principais:

- `RegistrarPartidaKofXVPage`
- `EstatisticasKofXVPage`

## 2XKO

2XKO usa dupla 2v2.

Caracteristicas:

- Point/Main;
- Assist/Second;
- dupla adversaria;
- tag, assist, comeback, corner pressure e punish;
- historico, rank e estatisticas por composicao.

Telas/classes principais:

- `MontarTime2XKOPage`
- `RegistrarPartida2XKOPage`
- `Estatisticas2XKOPage`

## Invincible VS

Invincible VS usa time 3v3, nao personagem unico.

Caracteristicas:

- montagem de Time Principal;
- tres slots para meu time;
- tres slots para time adversario;
- registro por composicao;
- LP em vez de PDL;
- rank proprio;
- estatisticas de time, composicao e personagens do trio.

Telas/classes principais:

- `MontarTimeInvinciblePage`
- `RegistrarPartidaInvinciblePage`
- `EstatisticasInvinciblePage`
- `TimePrincipalInvincible`

Campos salvos em `PartidaRegistrada`:

- `meuTimeSlot1`
- `meuTimeSlot2`
- `meuTimeSlot3`
- `timeAdversarioSlot1`
- `timeAdversarioSlot2`
- `timeAdversarioSlot3`
- `personagemDestaque`
- `primeiroDerrotado`
- `personagemInimigoProblema`
- `condicaoVitoria`
- `motivoDerrota`

## Home

A Home muda de acordo com o jogo:

- Invincible VS mostra o time atual.
- 2XKO mostra a dupla atual.
- KOF XV mostra a ordem do time.
- Street Fighter 6 mostra o personagem atual.
- Demais jogos mostram o personagem atual no fluxo individual.

Tambem existe botao Home para voltar para a biblioteca de jogos.

## Historico

O historico usa filtros diferentes por tipo de jogo:

- jogos genericos: player, personagem adversario, stage, kill e morte;
- Street Fighter 6: player, personagem adversario e placar;
- Tekken 8, MK1, Guilty, Fatal Fury e Rivals II: filtros e detalhes proprios;
- 2XKO e KOF XV: filtros por composicao/time;
- Invincible VS: players, times, personagens do time e analise.

## Jogos Arquivados

`Dragon Ball FighterZ` esta arquivado: a base pode ser reaproveitada depois, mas
ele nao fica na biblioteca ativa.

## Ao Adicionar Um Jogo Novo

1. Adicione o roster em `game_data.dart` ou no arquivo de config extraido.
2. Adicione imagens remotas e assets offline quando possivel.
3. Mapeie o `GameRegisterType`.
4. Decida se ele usa fluxo generico, rounds, 3D, tag, time ou ordem.
5. Se precisar de fluxo proprio, crie tela especifica no arquivo de registro.
6. Atualize esta documentacao.
