# Documentacao Do LabTracker

Esta pasta concentra a documentacao do LabTracker. A raiz do projeto deve ficar
simples; detalhes de arquitetura, fluxo, build e manutencao ficam aqui.

## Indice

- [Arquitetura](architecture.md): como o codigo esta dividido.
- [Organizacao do projeto](project-organization.md): estrutura alvo,
  componentes base e plano seguro de migracao.
- [Fluxos por jogo](game-flows.md): diferencas entre os jogos e seus registros.
- [Dados e backup](data-and-backup.md): onde os dados ficam e como sao salvos.
- [Desenvolvimento](development.md): comandos, padroes e cuidados ao alterar o app.
- [Build e executavel](build-and-release.md): como gerar builds, incluindo Windows.
- [Google Login](google-login.md): configuracao externa necessaria para Android/iOS.
- [Supabase](../supabase/README.md): Auth, schema e RLS para sync futuro.

## Estado Atual

O app usa `lib/main.dart` como ponto de entrada e conecta os arquivos de
`lib/src/` via `part`.

Fluxos especificos importantes:

- `Invincible VS`: time 3v3, registro por time e estatisticas de composicao.
- `2XKO`: dupla Point + Assist, registro por composicao.
- `KOF XV`: ordem Point, Mid e Anchor.
- `Street Fighter 6`: rounds e placar.
- `Tekken 8`: 3D Fighter com Heat, parede e whiff punish.
- `Mortal Kombat 1`: 2D Assist Fighter com Kameo.
- `Guilty Gear -Strive-`: Anime Fighter.
- `Fatal Fury`: SNK Fighter.
- `Rivals of Aether II`: Platform Fighter sem funcoes exclusivas do Smash.
- `Smash`: capa male/female visual, sem separar historico/rank/PDL.
- `Supabase Auth`: login opcional; dados locais continuam sendo a fonte diaria.

## Convencoes

- Textos do app em PT-BR.
- Nomes de arquivos em kebab-case para docs.
- Codigo em ingles quando esse ja for o padrao local.
- Atualize esta pasta quando criar fluxo novo, mudar persistencia, imagens,
  rank, build ou estrutura de pastas.
