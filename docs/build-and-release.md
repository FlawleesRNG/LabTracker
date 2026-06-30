# Build E Executavel

Este guia cobre builds locais para teste.

## Windows

Gerar build release:

```bash
flutter build windows --release
```

O executavel fica em:

```text
build/windows/x64/runner/Release/
```

A pasta inteira deve ficar junto do `.exe`, porque DLLs e arquivos de runtime do
Flutter sao necessarios.

Se o build falhar porque `labtracker.exe` esta aberto, feche o app. Se precisar
forcar:

```powershell
taskkill /F /IM labtracker.exe
```

Depois rode:

```bash
flutter clean
flutter pub get
flutter build windows --release
```

## Android

Gerar APK:

```bash
flutter build apk --release
```

Gerar App Bundle:

```bash
flutter build appbundle --release
```

O APK release fica em:

```text
build/app/outputs/flutter-apk/app-release.apk
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
flutter analyze
flutter test
```

## Build Com Supabase Auth

Use apenas a chave publica publishable/anon:

```bash
flutter build apk --release --dart-define=SUPABASE_URL=URL_DO_PROJETO --dart-define=SUPABASE_ANON_KEY=CHAVE_PUBLICA
flutter build windows --release --dart-define=SUPABASE_URL=URL_DO_PROJETO --dart-define=SUPABASE_ANON_KEY=CHAVE_PUBLICA
```

Sem esses defines, o app continua funcionando localmente e a tela de conta mostra
que Supabase nao esta configurado.

## Observacoes

- O login Google so funciona em plataformas suportadas pelo plugin, como Android
  e iOS.
- No Windows, o app cai no fluxo de login por nick.
- Dados e backups continuam locais.
