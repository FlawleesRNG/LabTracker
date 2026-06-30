# Dados, Persistencia E Backup

O LabTracker salva os dados localmente primeiro. Quando Supabase esta
configurado e o usuario esta logado, o app sincroniza em segundo plano sem
bloquear o uso offline.

## Arquivo Principal

O arquivo de dados e:

```text
labtracker_data.json
```

Ele e salvo no diretorio de documentos da aplicacao usando `path_provider`.

## Dados Salvos

O pacote principal de persistencia contem:

- perfil do jogador;
- jogo atual;
- personagem atual para jogos individuais;
- time principal do Invincible VS;
- dupla principal do 2XKO;
- rosters com PDL/rank recalculado;
- historico de partidas;
- preferencias visuais do Smash quando aplicavel.
- `deviceId` local do aparelho.
- `syncRecords` com metadados offline-first de perfil, progresso,
  preferencias, favoritos e selecoes.
- `syncQueue` com operacoes pendentes para sync manual/automatico.
- `partidasExcluidasParaSync` com tombstones de partidas apagadas localmente.
- `currentUserId` quando houver sessao Supabase ativa.

Metodos centrais:

- `gerarDadosPersistidos()`
- `_aplicarDadosMap()`
- `carregarDados()`
- `salvarDados()`

## SharedPreferences

`SharedPreferences` ainda e usado como fallback/migracao para alguns dados, como
preferencias visuais e listas simples. O arquivo JSON continua sendo a fonte
principal dos dados do app.

Tambem fica em `SharedPreferences` o `labtrackerDeviceId`, que identifica o
aparelho localmente antes de qualquer login remoto.

## Offline-first

Regra oficial:

```text
salvar local -> atualizar rank/PDL local -> marcar sync pendente
```

O app nao depende de internet para salvar partida, perfil, rank, historico ou
preferencias.

Partidas novas recebem:

- `id` local estavel;
- `deviceId`;
- `createdAt`;
- `updatedAt`;
- `syncStatus: pendingSync`;
- item correspondente em `syncQueue`.

Edicoes viram operacao `update` na fila. Exclusoes viram operacao `delete` e a
partida apagada fica preservada em `partidasExcluidasParaSync`, fora do
historico ativo, para nao quebrar estatisticas nem rank.

Quando ha sessao Supabase ativa, a fila pode ser enviada pelo botao
"Sincronizar agora" ou pelo sync automatico. Se a rede falhar, os itens ficam
pendentes/erro localmente e sao tentados novamente depois.

## Supabase Auth

Quando `SUPABASE_URL` e `SUPABASE_ANON_KEY` estao configurados por
`--dart-define`, a tela `Conta e Sync` permite login/cadastro por e-mail e
senha.

Fluxos ativos nesta etapa:

- login com e-mail e senha;
- cadastro com nick, e-mail, senha e confirmacao;
- checkbox visual "Manter conectado neste dispositivo", marcado por padrao;
- logout manual.

Fluxos nao implementados nesta etapa:

- OTP;
- magic link;
- login social;
- login Google/Discord via Supabase;
- recuperacao real de senha.

Se o usuario estiver logado, novos registros locais passam a receber `userId`.
Dados antigos sem `userId` continuam funcionando. Nao ha migracao automatica
agressiva nesta etapa.

Sem as variaveis do Supabase, o app abre normalmente em modo local.

## Supabase Sync

O sync usa as tabelas em `supabase/schema.sql` e as policies em
`supabase/rls_policies.sql`. Cada operacao respeita `auth.uid() = user_id`.

Fluxo atual:

- registrar/editar/excluir sempre salva local primeiro;
- a fila `syncQueue` registra `create`, `update` ou `delete`;
- deletes usam `deletedAt` como soft delete;
- conflitos usam `updatedAt`: o registro mais recente vence;
- o sync automatico pode rodar ao abrir o app, apos login, apos salvar dados,
  quando a conexao volta, ao retornar ao primeiro plano e em intervalo leve;
- a opcao `autoSyncEnabled` fica em `SharedPreferences` e tambem no snapshot de
  preferencias remoto;
- o botao manual continua disponivel mesmo com sync automatico desligado.

## Backup Local

O backup e exportado em JSON para:

```text
Documents/LabTracker_Backups
```

Na tela de configuracoes, o usuario pode:

- exportar backup;
- importar o backup mais recente;
- ver o caminho da pasta de backup.

## Compatibilidade

Ao alterar `PartidaRegistrada`, mantenha valores padrao nos campos novos. Isso
evita quebrar backups antigos.

Exemplo:

```dart
this.round1Resultado = '',
this.round2Resultado = '',
this.round3Resultado = '',
this.placarRounds = '',
```

Tambem existe normalizacao para textos antigos que podem ter sido salvos com
acentos quebrados:

- `corrigirTextoLegado()`
- `resultadoEhVitoria()`
- `resultadoEhDerrota()`

## Regras Praticas

- Nunca remova campos antigos sem migracao.
- Prefira adicionar campos opcionais com valor padrao.
- Quando criar um fluxo por jogo, salve dados especificos em campos proprios.
- Historico de time/dupla nao deve se misturar com historico de personagem.
- Tombstones de exclusao nao devem entrar em estatisticas/rank.
- A fila de sync nunca deve bloquear o salvamento local.
- Depois de mudar persistencia, teste carregar historico antigo.
