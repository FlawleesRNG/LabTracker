# Guia De Desenvolvimento

## Requisitos

- Flutter instalado.
- Dart SDK compativel com o projeto.
- Dependencias do `pubspec.yaml` instaladas.

## Instalacao

```bash
flutter pub get
```

## Rodar

```bash
flutter run
```

Para uma plataforma especifica:

```bash
flutter run -d windows
flutter run -d android
flutter run -d chrome
```

## Formatar

```bash
dart format lib
```

## Analisar

```bash
dart analyze lib/main.dart
flutter analyze
```

## Testes

```bash
flutter test
```

## Estrutura De Alteracao Recomendada

Para mudar um fluxo:

1. Leia o fluxo atual em `lib/src/screens/`.
2. Veja os dados envolvidos em `lib/src/models/models.dart`.
3. Veja rosters, imagens e opcoes em `lib/src/data/game_data.dart`.
4. Veja regras em `lib/src/core/`.
5. Faca alteracao pequena e condicional por jogo.
6. Rode `dart format`.
7. Rode `dart analyze lib/main.dart`.
8. Rode `flutter analyze` quando a mudanca tocar fluxo grande.

## Offline-first

- Sempre salvar local antes de qualquer tentativa de sync.
- Nunca exigir internet para registrar partida, editar perfil, atualizar rank ou
  salvar preferencias.
- Login Supabase e opcional; o app precisa continuar local se as variaveis nao
  estiverem configuradas.
- Partidas devem manter `id`, `deviceId`, timestamps e `syncStatus`.
- Toda criacao/edicao/exclusao de partida deve atualizar `syncQueue`.
- Exclusoes devem preservar tombstone em `partidasExcluidasParaSync` quando
  houver sync pendente.
- Sync manual e automatico reaproveitam `SyncService.syncNow()` e nao devem
  duplicar logica de upload/download nas telas.

## Supabase

- Configure por `--dart-define=SUPABASE_URL=...`.
- Configure por `--dart-define=SUPABASE_ANON_KEY=...`.
- Nunca colocar `service_role` no codigo, no app ou no repositorio.
- SQL e policies ficam em `supabase/`.
- A abertura passa por `AuthGate`: sessao ativa entra direto, sem sessao mostra
  Entrar/Criar conta/Continuar offline.
- Auth atual usa apenas e-mail e senha.
- Cadastro atual coleta nick, e-mail, senha e confirmacao de senha.
- Sync atual cobre fila local, snapshots de perfil/progresso/preferencias,
  favoritos e soft delete.
- O sync automatico pode ser desligado em Conta e Sync; o botao manual continua
  funcionando.
- OTP, magic link e login social ficam para uma etapa futura.

## Padroes De UI

- Textos em PT-BR.
- Tema escuro com destaque ambar/laranja.
- Cards e listas consistentes.
- Botao de voltar quando a tela nao tiver navegacao obvia.
- Botao Home como acao separada para voltar para a selecao de jogos.
- Seletor de data padrao para registros/edicoes de partida.
- Cards de personagem devem usar `CharacterAvatar` sempre que possivel.
- Telas novas devem usar tokens de `core/theme/design_tokens.dart`.
- Telas novas ou migradas devem usar helpers de `core/responsive/`.
- Componentes reaproveitaveis novos devem ir para `shared/widgets/` quando forem
  genericos para varias features.

## Responsividade

- Mobile: menor que `600`.
- Tablet: `600` ate menor que `1024`.
- Desktop: `1024` ou mais.
- Botoes de icone precisam manter alvo minimo de `48x48`.
- Use `SafeArea` em telas internas e bottom sheets.
- Use scroll quando houver formulario, historico longo ou filtros.
- No mobile, prefira icones compactos na AppBar para evitar overflow.
- Em desktop, use largura maxima para o conteudo nao ficar esticado.

## Padroes Por Jogo

- Jogos individuais usam personagem principal.
- Street Fighter 6 usa rounds.
- Invincible VS usa time 3v3.
- 2XKO usa dupla Point + Assist.
- KOF XV usa ordem Point, Mid e Anchor.
- Rivals II usa modelo Platform Fighter sem funcoes exclusivas do Smash.
- Tekken 8 usa modelo 3D Fighter.
- Mortal Kombat 1 usa Kameo.
- Nao misture campos de time em jogos individuais.
- Nao force rounds em jogos que ainda usam outro modelo.

## Checklist Antes De Fechar Uma Mudanca

- O app compila no analyzer.
- Os textos aparecem em PT-BR.
- A data da partida pode ser escolhida quando houver registro/edicao.
- O historico ainda abre partidas antigas.
- O fluxo de Invincible VS continua por time.
- O fluxo de 2XKO continua por dupla.
- O fluxo de KOF XV continua por ordem.
- O fluxo de Street Fighter 6 continua por rounds.
- A capa visual male/female do Smash nao cria personagem duplicado.
- Imagens continuam usando fallback remoto, offline e visual.
- Novas partidas entram como `pendingSync`.
- Edicoes e exclusoes criam item em `syncQueue`.
- Login/logout Supabase nao bloqueia uso local.
- Os outros jogos continuam no fluxo esperado.
