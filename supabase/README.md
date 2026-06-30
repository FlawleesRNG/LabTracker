# Supabase

Esta pasta prepara a base remota futura do LabTracker. Nesta etapa o app usa
Supabase apenas para Auth; sync de partidas ainda nao foi implementado.

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

## Proxima etapa

Implementar o botao manual "Sincronizar agora":

1. Ler `syncQueue` local.
2. Enviar criacoes/edicoes/deletes para Supabase.
3. Marcar itens como `done` ou `error`.
4. Baixar dados remotos.
5. Resolver conflitos com regra offline-first.
