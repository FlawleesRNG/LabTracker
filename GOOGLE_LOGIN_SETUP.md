# Login com Google — Configuração (Android / iOS)

O código do login já está pronto (`GoogleAuthService` em `lib/main.dart`, usando
`google_sign_in` 7.x). Falta **a parte externa**: criar as credenciais OAuth no
Google Cloud. Isso só você consegue fazer (envolve sua conta Google).

> O login **só identifica o jogador** (nome, e‑mail e foto). Os dados do app
> continuam salvos localmente no aparelho — não há sincronização em nuvem.

> No **Windows desktop o login Google não existe** (limitação da plataforma):
> a tela mostra automaticamente a opção "Entrar com um nick". O Google funciona
> no **app mobile (Android/iOS)**.

---

## 1. Google Cloud Console (uma vez)

1. Acesse <https://console.cloud.google.com/> e crie/selecione um projeto.
2. **APIs & Services → OAuth consent screen**: configure (External), adicione
   seu e‑mail como usuário de teste.
3. **APIs & Services → Credentials → Create credentials → OAuth client ID.**

Crie os clients abaixo conforme a plataforma.

---

## 2. Android

A API nova (`google_sign_in` 7.x) usa o **Credential Manager**, que precisa de um
**Web client ID** como `serverClientId`.

1. Crie um **OAuth client ID do tipo "Web application"** → copie o **Client ID**
   (algo como `123...apps.googleusercontent.com`).
2. Cole esse valor em `lib/main.dart`:
   ```dart
   class GoogleAuthService {
     static const String? serverClientId = 'SEU_WEB_CLIENT_ID.apps.googleusercontent.com';
   ```
3. Crie também um **OAuth client ID do tipo "Android"**:
   - **Package name:** `com.labtracker`
   - **SHA‑1** da sua keystore. Para a debug:
     ```bash
     keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android
     ```
     (para release, use o SHA‑1 da sua keystore de produção)

> O `applicationId` já está definido como `com.labtracker` em
> `android/app/build.gradle.kts`. Use exatamente esse valor no formulário.

---

## 3. iOS

1. Crie um **OAuth client ID do tipo "iOS"** com o seu **Bundle ID**.
2. Copie o **iOS client ID** e o **REVERSED_CLIENT_ID** (o client ID invertido).
3. Em `ios/Runner/Info.plist`, adicione:
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

---

## 4. Testar

```bash
flutter pub get
flutter run -d android   # ou -d ios
```

Toque em **"Entrar com Google"**. Se aparecer erro de configuração, geralmente é
SHA‑1/package name divergente (Android) ou `serverClientId` ausente.
