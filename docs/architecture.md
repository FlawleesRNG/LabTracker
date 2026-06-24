# Arquitetura

O LabTracker é um app Flutter em Dart. O arquivo [lib/main.dart](../lib/main.dart)
fica como ponto de entrada e lista os `part` files usados pelo app.

## Estrutura Principal

```text
lib/
  main.dart
  src/
    app/
    core/
    data/
    models/
    screens/
    widgets/
```

## Pastas

`lib/src/app/`

Contém a inicialização do app, tema, marca visual e serviço de login Google.

`lib/src/models/`

Modelos principais do domínio:

- `Character`
- `PlayerProfile`
- `PartidaRegistrada`
- `TimePrincipalInvincible`
- resumos de estatísticas

`lib/src/data/`

Dados estáticos:

- rosters
- imagens de personagens
- logos dos jogos
- stages
- opções de kill/morte
- opções específicas do Invincible VS

`lib/src/core/`

Regras e helpers:

- cálculo de rank
- cálculo de PDL/LP
- normalização de textos legados
- filtros e rankings de frequência
- helpers de estatísticas e gráficos

`lib/src/screens/`

Telas do app:

- onboarding e login inicial
- seleção de jogos/personagens
- home
- registro de partidas
- histórico e detalhes
- estatísticas
- perfil e configurações

`lib/src/widgets/`

Componentes reaproveitáveis:

- avatar de personagem
- campos pesquisáveis
- cards de análise
- gráficos
- seletor de data
- linhas de estatística

## Regra De Organização

Ao adicionar um recurso novo:

1. Coloque dados fixos em `data/`.
2. Coloque regra de negócio em `core/`.
3. Coloque estado/tela em `screens/`.
4. Coloque UI reaproveitável em `widgets/`.
5. Só altere `main.dart` para incluir um novo `part`.

## Cuidados

- Evite recolocar lógica grande em `main.dart`.
- Mantenha fluxos específicos por jogo condicionais.
- Não misture dados de time com jogos de personagem individual.
- Preserve compatibilidade com backups antigos sempre que mudar `PartidaRegistrada`.
