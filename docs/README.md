# Documentação Do LabTracker

Esta pasta concentra a documentação do LabTracker. A ideia é manter a raiz do
projeto simples e deixar os detalhes aqui dentro.

## Índice

- [Arquitetura](architecture.md): como o código está dividido.
- [Fluxos por jogo](game-flows.md): diferenças entre Smash, Street Fighter,
  Invincible VS e demais jogos.
- [Dados e backup](data-and-backup.md): onde os dados ficam e como são salvos.
- [Desenvolvimento](development.md): comandos, padrões e cuidados ao alterar o app.
- [Build e executável](build-and-release.md): como gerar builds, incluindo Windows.
- [Google Login](google-login.md): configuração externa necessária para Android/iOS.

## Estado Atual

O app foi refatorado para sair de um `main.dart` gigante e passar a usar arquivos
organizados em `lib/src/`, conectados via `part`.

Os fluxos mais específicos hoje são:

- `Invincible VS`: montagem de time 3v3, registro por time e estatísticas de composição.
- `Street Fighter 6`: personagem individual, registro por rounds e estatísticas de placar.
- Demais jogos individuais: personagem principal, adversário, stage/mapa, PDL e histórico.

## Convenções Da Documentação

- Use PT-BR nos textos do projeto.
- Prefira nomes de arquivos em kebab-case, como `game-flows.md`.
- Atualize esta pasta quando criar um fluxo novo, mudar persistência ou alterar build.
