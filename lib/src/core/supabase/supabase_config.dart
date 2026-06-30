part of '../../../main.dart';

abstract final class SupabaseConfig {
  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool initialized = false;
  static String initializationError = '';

  static bool get hasCredentials {
    return url.trim().isNotEmpty && anonKey.trim().isNotEmpty;
  }

  static bool get available {
    return hasCredentials && initialized && initializationError.isEmpty;
  }
}

abstract final class SupabaseBootstrap {
  static Future<void> initialize() async {
    if (!SupabaseConfig.hasCredentials) return;

    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.anonKey,
      );
      SupabaseConfig.initialized = true;
      SupabaseConfig.initializationError = '';
    } catch (error) {
      SupabaseConfig.initialized = false;
      SupabaseConfig.initializationError = error.toString();
    }
  }
}

abstract final class SupabaseClientProvider {
  static SupabaseClient? get client {
    if (!SupabaseConfig.available) return null;
    return Supabase.instance.client;
  }
}
