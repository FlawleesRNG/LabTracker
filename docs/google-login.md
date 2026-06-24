# Login Com Google

O código do login já está pronto em `GoogleAuthService`, usando
`google_sign_in` 7.x. Ainda é necessário configurar credenciais OAuth no Google
Cloud para Android/iOS.

O login identifica o jogador com nome, e-mail e foto. Os dados do app continuam
salvos localmente no aparelho; não há sincronização em nuvem.

No Windows desktop, o login Google não existe por limitação da plataforma. O app
mostra automaticamente a opção de entrar com um nick.

## 1. Google Cloud Console

1. Acesse <https://console.cloud.google.com/>.
2. Crie ou selecione um projeto.
3. Vá em `APIs & Services > OAuth consent screen`.
4. Configure como `External`.
5. Adicione seu e-mail como usuário de teste.
6. Vá em `APIs & Services > Credentials > Create credentials > OAuth client ID`.

## 2. Android

A API nova do `google_sign_in` usa o Credential Manager e precisa de um Web
Client ID como `serverClientId`.

1. Crie um OAuth Client ID do tipo `Web application`.
2. Copie o Client ID.
3. Cole esse valor no `serverClientId` em `GoogleAuthService`.
4. Crie também um OAuth Client ID do tipo `Android`.

Configuração Android:

- Package name: `com.labtracker`
- SHA-1: SHA-1 da keystore usada no build

Para a keystore debug:

```bash
keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android
```

O `applicationId` já está definido como `com.labtracker` em
`android/app/build.gradle.kts`.

## 3. iOS

1. Crie um OAuth Client ID do tipo `iOS`.
2. Use o Bundle ID do app.
3. Copie o iOS Client ID e o `REVERSED_CLIENT_ID`.
4. Configure o `ios/Runner/Info.plist`.

Exemplo:

```xml
<key>GIDClientID</key>
<string>SEU_IOS_CLIENT_ID.apps.googleusercontent.com</string>

<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.SEU_REVERSED_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

## 4. Testar

```bash
flutter pub get
flutter run -d android
```

Ou:

```bash
flutter run -d ios
```

Se aparecer erro de configuração, os motivos mais comuns são:

- SHA-1 divergente;
- package name divergente;
- `serverClientId` ausente ou incorreto;
- Bundle ID incorreto no iOS.
