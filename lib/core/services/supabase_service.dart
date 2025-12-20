/// Supabase Service
/// 
/// Singleton service untuk inisialisasi dan akses Supabase client.
/// Menggunakan environment variables untuk credentials (security best practice).

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  // Private constructor untuk singleton pattern
  SupabaseService._();

  /// Supabase client instance
  static SupabaseClient get client => Supabase.instance.client;

  /// Current authenticated user
  static User? get currentUser => client.auth.currentUser;

  /// Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;

  /// Initialize Supabase
  /// 
  /// Panggil ini di main.dart sebelum runApp()
  static Future<void> initialize() async {
    await Supabase.initialize(
      // TODO: Move to environment variables for production
      // Untuk sekarang, pakai credentials yang sama dengan PWA
      url: const String.fromEnvironment(
        'SUPABASE_URL',
        defaultValue: 'https://hrvzimtclvyvfjwoezxa.supabase.co',
      ),
      anonKey: const String.fromEnvironment(
        'SUPABASE_ANON_KEY',
        defaultValue: 'sb_publishable_9CsV2B0z-N8blMk_lpSIig_Xlzd87p6', // Ganti dengan Anon Key Supabase Anda
      ),
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.info,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // AUTH METHODS
  // ═══════════════════════════════════════════════════════════

  /// Sign in dengan email dan password
  static Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign up dengan email dan password
  static Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      data: fullName != null ? {'full_name': fullName} : null,
    );
  }

  /// Sign out
  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  /// Reset password
  static Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  // ═══════════════════════════════════════════════════════════
  // AUTH STATE STREAM
  // ═══════════════════════════════════════════════════════════

  /// Stream of auth state changes
  static Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;
}
