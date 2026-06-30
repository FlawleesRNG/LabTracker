# Supabase

Esta pasta prepara a base remota do LabTracker para Auth e sincronizacao
offline-first com Supabase.

## Criar projeto

1. Crie um projeto no Supabase.
2. Abra `SQL Editor`.
3. Rode `schema.sql`.
4. Rode `rls_policies.sql`.
5. Em `Authentication`, habilite login por e-mail/senha.

O app nao usa OTP, magic link ou login social nesta etapa.

## Variaveis do Flutter

Use somente URL do projeto e chave publica publishable/anon.

Nunca use `service_role` no app Flutter.

Rodar local:

```bash
flutter run --dart-define=SUPABASE_URL=URL_DO_PROJETO --dart-define=SUPABASE_ANON_KEY=CHAVE_PUBLICA
```

Build Android:

```bash
flutter build apk --release --dart-define=SUPABASE_URL=URL_DO_PROJETO --dart-define=SUPABASE_ANON_KEY=CHAVE_PUBLICA
```

Build Windows:

```bash
flutter build windows --release --dart-define=SUPABASE_URL=URL_DO_PROJETO --dart-define=SUPABASE_ANON_KEY=CHAVE_PUBLICA
```

## RLS

Todas as tabelas com `user_id` usam Row Level Security. Cada usuario so pode
ler, inserir, atualizar ou apagar linhas onde:

```sql
auth.uid() = user_id
```

## Sync

O app sempre salva local primeiro. Depois ele tenta sincronizar em segundo
plano quando for seguro:

- ao abrir o app;
- apos login;
- apos salvar/editar/excluir dados locais;
- quando a conexao volta;
- quando o app volta ao primeiro plano;
- em intervalo leve enquanto aberto.

O botao "Sincronizar agora" continua disponivel na tela Conta e Sync. A opcao
"Sincronizacao automatica" vem ativada por padrao e pode ser desligada pelo
usuario sem afetar o uso offline nem o botao manual.

Fluxo atual:

1. Confirmar sessao Supabase ativa.
2. Registrar/atualizar o `device_id`.
3. Confirmar conectividade provavel via `connectivity_plus`.
4. Enviar itens pendentes de `syncQueue`.
5. Enviar snapshots locais com dados reais.
6. Baixar dados remotos.
7. Resolver conflitos por `updated_at`: o mais recente vence.
8. Manter deletes como soft delete por `deleted_at`.
9. Atualizar `lastSyncAt`, pendencias e erros locais.

Se o projeto Supabase ja existia antes desta etapa, confira se
`sync_events.entity_id` esta como `text`. Se ainda estiver como `uuid`, rode:

```sql
alter table public.sync_events
  alter column entity_id type text using entity_id::text;
```
