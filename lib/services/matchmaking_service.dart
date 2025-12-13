import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'dart:async';

enum GameMode { normal, ranked }

class MatchmakingService {
  static const int matchTimeoutSeconds = 30;
  
  // 매칭 큐에 추가
  static Future<void> joinQueue(GameMode mode) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    
    await SupabaseService.client
        .from('matchmaking')
        .insert({
          'user_id': userId,
          'mode': mode.name,
          'created_at': DateTime.now().toIso8601String(),
        });
  }
  
  // 매칭 큐에서 제거
  static Future<void> leaveQueue() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;
    
    await SupabaseService.client
        .from('matchmaking')
        .delete()
        .eq('user_id', userId);
  }
  
  // 매칭 대기 중인 플레이어 찾기
  static Future<String?> findMatch(GameMode mode) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    
    // 랭크게임인 경우 비슷한 랭크의 플레이어 찾기
    if (mode == GameMode.ranked) {
      final profile = await SupabaseService.client
          .from('profiles')
          .select('rank')
          .eq('id', userId)
          .single();
      
      final rank = profile['rank'] as int;
      final rankRange = 200; // ±200 랭크 범위
      
      // 비슷한 랭크의 플레이어 찾기
      // 먼저 매칭 큐의 모든 사용자 가져오기
      final allMatches = await SupabaseService.client
          .from('matchmaking')
          .select('user_id')
          .eq('mode', mode.name)
          .neq('user_id', userId);
      
      // 각 사용자의 랭크 확인
      for (var match in allMatches) {
        final opponentId = match['user_id'] as String;
        final opponentProfile = await SupabaseService.client
            .from('profiles')
            .select('rank')
            .eq('id', opponentId)
            .maybeSingle();
        
        if (opponentProfile != null) {
          final opponentRank = opponentProfile['rank'] as int;
          if ((opponentRank - rank).abs() <= rankRange) {
            return opponentId;
          }
        }
      }
    }
    
    // 일반게임이거나 매칭이 안 된 경우 - 아무나 매칭
    final matches = await SupabaseService.client
        .from('matchmaking')
        .select('user_id')
        .eq('mode', mode.name)
        .neq('user_id', userId)
        .limit(1);
    
    if (matches.isNotEmpty) {
      return matches[0]['user_id'] as String;
    }
    
    return null;
  }
  
  // 실시간 매칭 리스너 (현재는 사용하지 않음 - 주기적 확인 방식 사용)
  // 필요시 구현 가능
}

