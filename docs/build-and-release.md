# Build E Executável

Este guia cobre builds locais para teste.

## Windows

Gerar build release:

```bash
flutter build windows --release
```

O executável fica em:

```text
build/windows/x64/runner/Release/
```

O arquivo principal é o `.exe` gerado pelo Flutter. A pasta inteira deve ficar
junto do executável, porque DLLs e arquivos de runtime são necessários.

## Android

Gerar APK:

```bash
flutter build apk --release
```

Gerar App Bundle:

```bash
flutter build appbundle --release
```

## Web

```bash
flutter build web --release
```

## Antes De Gerar Build

Rode:

```bash
flutter pub get
dart format lib
dart analyze lib/main.dart
flutter test
```

## Observações

- O login Google só funciona em plataformas suportadas pelo plugin, como Android
  e iOS.
- No Windows, o app cai no fluxo de login por nick.
- Dados e backups continuam locais.
