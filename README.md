# LabTracker

LabTracker e um app Flutter para acompanhar treino competitivo em jogos de luta:
registro de partidas, PDL/LP, ranks, historico, estatisticas, filtros e leitura
de padroes por personagem, time ou matchup.

Versao atual: `1.0.0-alpha+1`.

## O Que O App Faz

- Perfil local do jogador.
- Biblioteca de jogos.
- Selecao de personagem principal para jogos individuais.
- Montagem de time para jogos com time/dupla.
- Registro de partidas com dados proprios por jogo.
- Historico com filtros.
- Estatisticas, graficos e leitura de padroes.
- Backup local em JSON.
- Login Google em mobile, com fallback por nick em desktop.
- Conta Supabase opcional com sync manual e automatico offline-first.

## Jogos Suportados

- Super Smash Bros. Ultimate
- Street Fighter 6
- Mortal Kombat 1
- Avatar Legends: The Fighting Game
- Guilty Gear -Strive-
- The King of Fighters XV
- Invincible VS
- Tekken 8
- 2XKO
- Rivals of Aether II
- Fatal Fury

`Dragon Ball FighterZ` esta arquivado no codigo para reaproveitamento futuro,
mas nao aparece na biblioteca ativa.

## Documentacao

A documentacao principal fica em [docs/](docs/README.md).

- [Visao geral da documentacao](docs/README.md)
- [Arquitetura do projeto](docs/architecture.md)
- [Organizacao do projeto](docs/project-organization.md)
- [Fluxos por jogo](docs/game-flows.md)
- [Dados, backup e persistencia](docs/data-and-backup.md)
- [Guia de desenvolvimento](docs/development.md)
- [Build e executavel](docs/build-and-release.md)
- [Configuracao do Google Login](docs/google-login.md)
- [Supabase](supabase/README.md)

## Rodar Localmente

```bash
flutter pub get
flutter run
```

Para checar o codigo:

```bash
dart analyze lib/main.dart
dart format lib
```

## Observacao

Esta e uma versao alpha. Bugs podem acontecer, e alguns fluxos ainda estao
sendo padronizados por jogo.
