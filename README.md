# LabTracker

LabTracker é um app Flutter para acompanhar treino competitivo em jogos de luta:
registro de partidas, PDL/LP, ranks, histórico, estatísticas, filtros e leitura
de padrões por personagem, time ou matchup.

Versão atual: `1.0.0-alpha+1`.

## O Que O App Faz

- Perfil local do jogador.
- Biblioteca de jogos.
- Seleção de personagem principal para jogos individuais.
- Montagem de time principal para `Invincible VS`.
- Registro de partidas com dados próprios por jogo.
- Histórico com filtros.
- Estatísticas, gráficos e leitura de padrões.
- Backup local em JSON.
- Login Google em mobile, com fallback por nick em desktop.

## Jogos Suportados

- Super Smash Bros. Ultimate
- Street Fighter 6
- Mortal Kombat 1
- Avatar Legends: The Fighting Game
- Guilty Gear -Strive-
- The King of Fighters XV
- Invincible VS
- Dragon Ball FighterZ
- Fatal Fury

## Documentação

A documentação principal fica em [docs/](docs/README.md).

- [Visão geral da documentação](docs/README.md)
- [Arquitetura do projeto](docs/architecture.md)
- [Fluxos por jogo](docs/game-flows.md)
- [Dados, backup e persistência](docs/data-and-backup.md)
- [Guia de desenvolvimento](docs/development.md)
- [Build e executável](docs/build-and-release.md)
- [Configuração do Google Login](docs/google-login.md)

## Rodar Localmente

```bash
flutter pub get
flutter run
```

Para checar o código:

```bash
dart analyze lib/main.dart
dart format lib
```

## Observação

Esta é uma versão alpha. Bugs podem acontecer, e alguns fluxos ainda estão sendo
padronizados por jogo.
