part of '../../../main.dart';

class AuthUnavailableException implements Exception {
  final String message;

  const AuthUnavailableException(this.message);

  @override
  String toString() => message;
}

abstract final class AuthService {
  static const String prefsKeyCurrentUserId = 'supabaseCurrentUserId';
  static const String prefsKeyCurrentUserEmail = 'supabaseCurrentUserEmail';
  static const String prefsKeyCurrentUserNick = 'supabaseCurrentUserNick';

  static SupabaseClient get _client {
    final SupabaseClient? client = SupabaseClientProvider.client;
    if (client == null) {
      throw const AuthUnavailableException(
        'Supabase nao esta configurado. Use o app localmente ou configure SUPABASE_URL e SUPABASE_ANON_KEY.',
      );
    }
    return client;
  }

  static bool get isConfigured => SupabaseConfig.hasCredentials;
  static bool get isAvailable => SupabaseConfig.available;

  static User? get currentUser {
    final SupabaseClient? client = SupabaseClientProvider.client;
    return client?.auth.currentUser;
  }

  static String? get currentUserId => currentUser?.id;
  static String? get currentUserEmail => currentUser?.email;
  static String? get currentUserNick {
    final dynamic nickname = currentUser?.userMetadata?['nickname'];
    if (nickname == null || nickname.toString().trim().isEmpty) return null;
    return nickname.toString().trim();
  }

  static bool get isLoggedIn => currentUserId != null;

  static Stream<AuthState> get authStateChanges {
    final SupabaseClient? client = SupabaseClientProvider.client;
    return client?.auth.onAuthStateChange ?? const Stream<AuthState>.empty();
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final AuthResponse response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    await persistCurrentUser();
    return response;
  }

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String nick,
  }) async {
    final AuthResponse response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'nickname': nick.trim()},
    );
    await persistCurrentUser();
    return response;
  }

  static Future<void> signOut() async {
    final SupabaseClient? client = SupabaseClientProvider.client;
    if (client != null) {
      await client.auth.signOut();
    }
    await clearStoredUser();
  }

  static Future<void> persistCurrentUser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final User? user = currentUser;

    if (user == null) return;

    await prefs.setString(prefsKeyCurrentUserId, user.id);
    if ((user.email ?? '').trim().isNotEmpty) {
      await prefs.setString(prefsKeyCurrentUserEmail, user.email!.trim());
    }
    final String? nick = currentUserNick;
    if ((nick ?? '').trim().isNotEmpty) {
      await prefs.setString(prefsKeyCurrentUserNick, nick!.trim());
    }
  }

  static Future<void> clearStoredUser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(prefsKeyCurrentUserId);
    await prefs.remove(prefsKeyCurrentUserEmail);
    await prefs.remove(prefsKeyCurrentUserNick);
  }

  static Future<String?> loadStoredUserId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(prefsKeyCurrentUserId);
  }

  static Future<String?> loadStoredUserEmail() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(prefsKeyCurrentUserEmail);
  }

  static Future<String?> loadStoredUserNick() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(prefsKeyCurrentUserNick);
  }

  static Future<String?> resolveCurrentUserId() async {
    if (currentUserId != null) {
      await persistCurrentUser();
      return currentUserId;
    }

    return loadStoredUserId();
  }

  static Future<String?> attachLocalDataToCurrentUser() async {
    final String? userId = await resolveCurrentUserId();
    if (userId == null || userId.trim().isEmpty) return null;

    // Sync completo fica para a proxima etapa. Por enquanto, persistimos o
    // usuario atual para que novos dados locais recebam userId.
    await persistCurrentUser();
    return userId;
  }

  static String friendlyError(Object error) {
    if (error is AuthException) {
      return error.message;
    }

    if (error is AuthUnavailableException) {
      return error.message;
    }

    return 'Nao foi possivel concluir a acao agora. Confira sua conexao e tente novamente.';
  }
}
