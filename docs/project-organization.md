# Organizacao Do Projeto

Este documento e o mapa de manutencao do LabTracker. A ideia e manter o app
funcionando primeiro, e ir quebrando os arquivos grandes em partes menores sem
misturar rank, historico, registro ou identidade dos jogos.

## Estado Atual

O projeto ja saiu de um `main.dart` gigante, mas ainda usa `part` files. Isso
quer dizer que mover arquivos sem cuidado pode quebrar caminhos e referencias
globais. Por isso, a organizacao deve acontecer em etapas pequenas.

Arquivos que ainda concentram muita responsabilidade:

- `lib/src/screens/match_registration.dart`: registros de todos os jogos.
- `lib/src/screens/stats_pages.dart`: estatisticas e coach de varios jogos.
- `lib/src/screens/history.dart`: historico, filtros e detalhes.
- `lib/src/data/game_data.dart`: rosters, imagens, categorias e opcoes.
- `lib/src/core/game_logic.dart`: regras de rank, PDL e normalizacao.
- `lib/src/screens/home_page.dart`: home, atalhos e partes de fluxo por jogo.

## Base Criada

Novos pontos de organizacao:

```text
lib/src/core/theme/design_tokens.dart
lib/src/core/responsive/responsive.dart
lib/src/core/supabase/supabase_config.dart
lib/src/core/supabase/auth_service.dart
lib/src/data/services/device_service.dart
lib/src/data/repositories/local_sync_repository.dart
lib/src/features/auth/auth_screens.dart
lib/src/shared/widgets/layout_widgets.dart
```

`design_tokens.dart`

Centraliza medidas de UI: espaco, raio, largura maxima, alvo minimo de toque e
duracoes. Novos widgets devem preferir esses tokens em vez de numeros soltos.

`responsive.dart`

Centraliza breakpoints:

- mobile: menor que `600`
- tablet: `600` ate menor que `1024`
- desktop: `1024` ou mais

Tambem fornece `ResponsiveContainer` e `ResponsiveGrid` para novas telas e para
as migracoes das telas existentes.

`layout_widgets.dart`

Cria componentes reutilizaveis para paginas:

- `AppPageScaffold`
- `AppPageHeader`
- `AppSectionTitle`
- `AppSurfaceCard`
- `AppEmptyState`

`device_service.dart`

Gera e guarda o `deviceId` local usado pelos metadados offline-first.

`local_sync_repository.dart`

Prepara entidades locais para sincronizacao futura: gera ids locais, marca
`pendingSync`, cria tombstones de delete e atualiza a `syncQueue`.

`core/supabase/`

Inicializa Supabase Auth por `--dart-define` e encapsula login/cadastro/logout
sem espalhar `Supabase.instance.client.auth` pelas telas.

`features/auth/auth_screens.dart`

Tela opcional de Conta e Sync: login/cadastro, logout, status local e placeholder
para sync manual futuro.

## Estrutura Alvo

Estrutura desejada para as proximas refatoracoes:

```text
lib/
  main.dart
  src/
    app/
    core/
      game_logic/
      navigation/
      responsive/
      stats/
      theme/
      utils/
    data/
      local/
      repositories/
      services/
    models/
      game/
      match/
      profile/
      rank/
      sync/
    config/
      games/
      image_sources/
      ranks/
      register_types/
    features/
      auth/
      backup/
      character_selection/
      coach/
      game_selection/
      history/
      home/
      match_register/
      profile/
      settings/
      stats/
      sync/
      team_builder/
    shared/
      widgets/
        buttons/
        cards/
        dialogs/
        inputs/
        layout/
```

## Ordem Segura De Migracao

1. Criar componentes compartilhados antes de mover telas.
2. Extrair configs puras de `game_data.dart`: rosters, logos, imagens,
   categorias, campos de registro e opcoes.
3. Separar repositories por dominio quando a base offline-first crescer:
   partidas, perfil, preferencias, favoritos e progresso.
4. Separar `match_registration.dart` por tipo de jogo: platform, 2D, 3D, tag
   2v2, team order, team 3v3 e SNK.
5. Separar `stats_pages.dart` por jogo ou por tipo de registro.
6. Separar `history.dart` em filtros, cards, detalhes e helpers.
7. So depois mover telas para `features/`.

Depois de cada etapa grande, rodar:

```bash
flutter pub get
dart format lib
dart analyze lib/main.dart
flutter analyze
```

## Regras Que Nao Podem Quebrar

- Smash continua salvando personagem base; capa male/female e apenas visual.
- Invincible VS tem historico/rank por time 3v3.
- 2XKO tem historico/rank por dupla Point + Assist.
- KOF XV respeita ordem Point, Mid e Anchor.
- Tekken 8, Mortal Kombat 1, Guilty Gear, Fatal Fury e Street usam identidade
  propria de registro/rank.
- Rivals II usa modelo Platform Fighter, mas nao recebe funcoes exclusivas do
  Smash.
- Imagens seguem a cadeia: URL remota -> asset offline -> fallback visual.
- Dados antigos precisam continuar abrindo.
- Salvamento local vem antes de qualquer sync remoto.
- A fila local de sync nao pode impedir registro, edicao ou exclusao offline.
- Supabase Auth e opcional e nao pode bloquear o app sem internet.
- A chave `service_role` nunca entra no Flutter.

## Checklist Visual

Em toda tela nova ou migrada:

- usar `SafeArea`;
- manter conteudo rolavel quando houver muitos campos;
- usar `ResponsiveContainer` em paginas;
- usar `ResponsiveGrid` em grids novos;
- manter botoes com alvo minimo de `48x48`;
- no mobile, preferir icones compactos na AppBar;
- evitar texto estourando dentro de cards, botoes e filtros;
- testar teclado em campos de texto no celular;
- confirmar que nao aparece overflow amarelo/preto.
