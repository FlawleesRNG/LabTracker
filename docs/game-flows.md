# Fluxos Por Jogo

O LabTracker usa uma base comum, mas cada jogo pode ter adaptações próprias.

## Fluxo Genérico De Personagem Individual

Usado por:

- Super Smash Bros. Ultimate
- Mortal Kombat 1
- Avatar Legends: The Fighting Game
- Guilty Gear -Strive-
- The King of Fighters XV
- Dragon Ball FighterZ
- Fatal Fury

Características:

- seleção de personagem principal;
- personagem adversário;
- player adversário;
- resultado;
- stage/mapa;
- dados de PDL;
- observações;
- data da partida;
- histórico, filtros e estatísticas.

Tela principal de registro:

- `RegistrarPartidaPage` em `lib/src/screens/match_registration.dart`

## Street Fighter 6

Street Fighter usa personagem individual, mas o registro é baseado em rounds.

Características:

- personagem principal;
- personagem adversário;
- jogador adversário;
- Round 1, Round 2 e Round 3 quando necessário;
- resultado final automático;
- placares `2x0`, `2x1`, `0x2`, `1x2`;
- estatísticas de partidas e rounds;
- data da partida.

Telas/classes principais:

- `RegistrarPartidaStreetFighterPage`
- `EstatisticasStreetFighterPage`

Campos salvos em `PartidaRegistrada`:

- `round1Resultado`
- `round2Resultado`
- `round3Resultado`
- `placarRounds`

## Invincible VS

Invincible VS usa time 3v3, não personagem único.

Características:

- montagem de Time Principal;
- três slots para meu time;
- três slots para time adversário;
- registro por composição;
- LP em vez de PDL;
- rank próprio;
- estatísticas de time, composição e personagens do trio.

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

- Invincible VS mostra `Time Atual`.
- Street Fighter 6 mostra `Personagem Atual`.
- Demais jogos mostram o personagem atual no fluxo individual padrão.

Também existe um botão para voltar à biblioteca de jogos.

## Histórico

O histórico usa filtros diferentes por tipo de jogo:

- jogos genéricos: player, personagem adversário, stage, kill e morte;
- Street Fighter 6: player, personagem adversário e placar;
- Invincible VS: players, times, personagens do time e análise.

## Ao Adicionar Um Jogo Novo

1. Adicione o roster em `game_data.dart`.
2. Adicione imagens e logo quando possível.
3. Decida se ele usa fluxo genérico, rounds ou time.
4. Se precisar de fluxo próprio, crie tela específica no arquivo de registro.
5. Atualize esta documentação.
