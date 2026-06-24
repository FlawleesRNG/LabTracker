# Guia De Desenvolvimento

## Requisitos

- Flutter instalado.
- Dart SDK compatível com o projeto.
- Dependências do `pubspec.yaml` instaladas.

## Instalação

```bash
flutter pub get
```

## Rodar

```bash
flutter run
```

Para uma plataforma específica:

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
```

## Testes

```bash
flutter test
```

## Estrutura De Alteração Recomendada

Para mudar um fluxo:

1. Leia o fluxo atual em `lib/src/screens/`.
2. Veja os dados envolvidos em `lib/src/models/models.dart`.
3. Veja regras em `lib/src/core/`.
4. Faça alteração pequena e condicional por jogo.
5. Rode `dart format`.
6. Rode `dart analyze lib/main.dart`.

## Padrões De UI

- Textos em PT-BR.
- Tema escuro com destaque âmbar/laranja.
- Cards e listas consistentes.
- Botão de voltar quando a tela não tiver navegação óbvia.
- Seletor de data padrão para registros/edições de partida.
- Cards de personagem devem usar `CharacterAvatar` sempre que possível.

## Padrões Por Jogo

- Jogos individuais usam personagem principal.
- Street Fighter 6 usa rounds.
- Invincible VS usa time 3v3.
- Não misture campos de time em jogos individuais.
- Não force rounds em jogos que ainda usam o fluxo genérico.

## Checklist Antes De Fechar Uma Mudança

- O app compila no analyzer.
- Os textos aparecem em PT-BR.
- A data da partida pode ser escolhida quando houver registro/edição.
- O histórico ainda abre partidas antigas.
- O fluxo de Invincible VS continua por time.
- O fluxo de Street Fighter 6 continua por rounds.
- Os outros jogos continuam no fluxo individual padrão.
