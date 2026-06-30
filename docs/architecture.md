# Arquitetura

O LabTracker e um app Flutter em Dart. O arquivo
[`lib/main.dart`](../lib/main.dart) e o ponto de entrada e lista os `part`
files usados pelo app.

## Estrutura Atual

```text
lib/
  main.dart
  src/
    app/
    core/
      responsive/
      supabase/
      theme/
    data/
      repositories/
      services/
    features/
      auth/
    models/
    screens/
    shared/
      widgets/
    widgets/
```

## Pastas

`lib/src/app/`

Inicializacao do app, tema principal, marca visual, login Google e persistencia
local compartilhada.

`lib/src/models/`

Modelos principais do dominio:

- `Character`
- `PlayerProfile`
- `PartidaRegistrada`
- `TimePrincipalInvincible`
- `TimePrincipal2XKO`
- resumos de estatisticas
- tipos de registro de jogo

`lib/src/data/`

Dados estaticos:

- rosters
- imagens de personagens
- logos dos jogos
- assets offline
- stages
- opcoes de registro por jogo
- categorias e subtitulos

Servicos e repositories locais:

- `data/services/device_service.dart`: gera e guarda `deviceId` local.
- `data/services/sync_service.dart`: executa sync manual/automatico com
  Supabase sem bloquear o uso offline.
- `data/repositories/local_sync_repository.dart`: prepara metadados
  offline-first e mantem a fila local de sync.

`lib/src/core/`

Regras e helpers:

- calculo de rank
- calculo de PDL/LP
- normalizacao de textos legados
- filtros e rankings de frequencia
- helpers de estatisticas e graficos
- tokens de tema em `core/theme/`
- breakpoints e containers responsivos em `core/responsive/`
- configuracao/Auth do Supabase em `core/supabase/`

`lib/src/screens/`

Telas atuais:

- onboarding e login inicial
- selecao de jogos/personagens
- montagem de times
- home
- registro de partidas
- historico e detalhes
- estatisticas e coach
- perfil e configuracoes

`lib/src/features/auth/`

Telas opcionais de conta:

- `AuthGate` inicial: decide entre entrar direto, mostrar acesso por
  login/cadastro ou liberar uso offline;
- login/cadastro por e-mail e senha via Supabase Auth;
- cadastro separado com nick e confirmacao de senha;
- status local/logado;
- logout;
- botao "Sincronizar agora";
- opcao "Sincronizacao automatica", ativada por padrao.

`lib/src/widgets/`

Componentes existentes reaproveitaveis:

- avatar de personagem
- campo pesquisavel
- imagem com fallback
- cards de analise
- graficos
- seletor de data
- linhas de estatistica

`lib/src/shared/widgets/`

Componentes novos e mais genericos para telas futuras ou migracoes seguras:

- `AppPageScaffold`
- `AppPageHeader`
- `AppSectionTitle`
- `AppSurfaceCard`
- `AppEmptyState`
- widgets que usam os helpers responsivos

## Regra De Organizacao

Ao adicionar um recurso novo:

1. Coloque dados fixos em `data/` ou em config extraida.
2. Coloque regra de negocio em `core/`.
3. Coloque estado/tela em `screens/` enquanto a migracao para `features/` nao
   estiver completa.
4. Coloque UI reaproveitavel antiga em `widgets/`.
5. Coloque UI nova generica em `shared/widgets/`.
6. So altere `main.dart` para incluir um novo `part`.

## Cuidados

- Evite recolocar logica grande em `main.dart`.
- Mantenha fluxos especificos por jogo condicionais.
- Nao misture dados de time com jogos de personagem individual.
- Preserve compatibilidade com backups antigos sempre que mudar
  `PartidaRegistrada`.
- Salve sempre local primeiro; sync manual/automatico nunca pode bloquear
  registro, historico, perfil, rank ou preferencias.
- Nunca usar `service_role` no Flutter. Use somente a chave publica
  publishable/anon via `--dart-define`.
- Nao mover telas grandes para `features/` sem antes extrair configs/helpers e
  rodar `flutter analyze`.
