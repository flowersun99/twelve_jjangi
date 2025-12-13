import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class AuthService {
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    final response = await SupabaseService.client.auth.signUp(
      email: email,
      password: password,
      data: {'username': username},
    );
    
    if (response.user != null) {
      // 사용자 프로필 생성
      await SupabaseService.client
          .from('profiles')
          .insert({
            'id': response.user!.id,
            'username': username,
            'rank': 1000, // 기본 랭크
            'wins': 0,
            'losses': 0,
          });
    }
    
    return response;
  }
  
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await SupabaseService.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  
  static Future<void> signOut() async {
    await SupabaseService.client.auth.signOut();
  }
  
  static Stream<AuthState> get authStateChanges =>
      SupabaseService.client.auth.onAuthStateChange;
}

