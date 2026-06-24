# Dados, Persistência E Backup

O LabTracker salva os dados localmente. Não há sincronização em nuvem no fluxo
atual.

## Arquivo Principal

O arquivo de dados é:

```text
labtracker_data.json
```

Ele é salvo no diretório de documentos da aplicação usando `path_provider`.

## Dados Salvos

O pacote principal de persistência contém:

- perfil do jogador;
- jogo atual;
- personagem atual;
- time principal do Invincible VS;
- rosters com PDL/rank recalculado;
- histórico de partidas.

O método central fica em `HomePage`:

- `gerarDadosPersistidos()`
- `_aplicarDadosMap()`
- `carregarDados()`
- `salvarDados()`

## SharedPreferences

`SharedPreferences` ainda é usado como fallback/migração para alguns dados, mas
o arquivo JSON é a fonte principal.

## Backup Local

O backup é exportado em JSON para:

```text
Documents/LabTracker_Backups
```

Na tela de configurações, o usuário pode:

- exportar backup;
- importar o backup mais recente;
- ver o caminho da pasta de backup.

## Compatibilidade

Ao alterar `PartidaRegistrada`, mantenha valores padrão nos campos novos. Isso
evita quebrar backups antigos.

Exemplo:

```dart
this.round1Resultado = '',
this.round2Resultado = '',
this.round3Resultado = '',
this.placarRounds = '',
```

Também existe normalização para textos antigos que podem ter sido salvos com
acentos quebrados:

- `corrigirTextoLegado()`
- `resultadoEhVitoria()`
- `resultadoEhDerrota()`

## Regras Práticas

- Nunca remova campos antigos sem migração.
- Prefira adicionar campos opcionais com valor padrão.
- Quando criar um fluxo por jogo, salve dados específicos em campos próprios.
- Depois de mudar persistência, teste carregar histórico antigo.
