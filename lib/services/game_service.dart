import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import '../models/game_state.dart';
import '../models/piece.dart';
import '../models/position.dart';
import 'dart:convert';

class GameService {
  // 게임 방 생성
  static Future<String> createGameRoom({
    required String player1Id,
    required String player2Id,
    required String mode,
  }) async {
    final initialState = GameState.initial();
    
    final response = await SupabaseService.client
        .from('games')
        .insert({
          'player1_id': player1Id,
          'player2_id': player2Id,
          'mode': mode,
          'game_state': _gameStateToJson(initialState),
          'current_player': 'player1',
          'time_remaining': 30,
          'status': 'playing',
          'created_at': DateTime.now().toIso8601String(),
        })
        .select('id')
        .single();
    
    return response['id'] as String;
  }
  
  // 게임 상태 업데이트
  static Future<void> updateGameState({
    required String gameId,
    required GameState gameState,
    required int timeRemaining,
  }) async {
    await SupabaseService.client
        .from('games')
        .update({
          'game_state': _gameStateToJson(gameState),
          'current_player': gameState.currentPlayer == Player.player1 ? 'player1' : 'player2',
          'time_remaining': timeRemaining,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', gameId);
  }
  
  // 게임 종료
  static Future<void> endGame({
    required String gameId,
    required String winnerId,
  }) async {
    await SupabaseService.client
        .from('games')
        .update({
          'status': 'finished',
          'winner_id': winnerId,
          'ended_at': DateTime.now().toIso8601String(),
        })
        .eq('id', gameId);
    
    // 랭크게임인 경우 랭크 업데이트
    final game = await SupabaseService.client
        .from('games')
        .select('mode, player1_id, player2_id')
        .eq('id', gameId)
        .single();
    
    if (game['mode'] == 'ranked') {
      final player1Id = game['player1_id'] as String;
      final player2Id = game['player2_id'] as String;
      
      // 승자와 패자 프로필 가져오기
      final winnerProfile = await SupabaseService.client
          .from('profiles')
          .select('rank, wins')
          .eq('id', winnerId)
          .single();
      
      final loserId = winnerId == player1Id ? player2Id : player1Id;
      final loserProfile = await SupabaseService.client
          .from('profiles')
          .select('rank, losses')
          .eq('id', loserId)
          .single();
      
      // 승자 랭크 증가, 패자 랭크 감소
      await SupabaseService.client
          .from('profiles')
          .update({
            'rank': (winnerProfile['rank'] as int) + 20,
            'wins': (winnerProfile['wins'] as int) + 1,
          })
          .eq('id', winnerId);
      
      await SupabaseService.client
          .from('profiles')
          .update({
            'rank': ((loserProfile['rank'] as int) - 10).clamp(0, double.infinity).toInt(),
            'losses': (loserProfile['losses'] as int) + 1,
          })
          .eq('id', loserId);
    }
  }
  
  // 게임 상태 리스너
  static RealtimeChannel watchGameState(String gameId, Function(GameState, int) onUpdate) {
    final channel = SupabaseService.client
        .channel('game:$gameId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'games',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: gameId,
          ),
          callback: (payload) {
            final data = payload.newRecord;
            if (data != null) {
              final gameState = _gameStateFromJson(data['game_state'] as Map<String, dynamic>);
              final timeRemaining = data['time_remaining'] as int;
              onUpdate(gameState, timeRemaining);
            }
          },
        )
        .subscribe();
    
    return channel;
  }
  
  // 게임 상태 JSON 변환
  static Map<String, dynamic> _gameStateToJson(GameState state) {
    return {
      'board': state.board.map((key, value) => MapEntry(
        '${key.row},${key.col}',
        {
          'type': value.type.name,
          'owner': value.owner.name,
        },
      )),
      'player1_captured': state.player1Captured.map((p) => {
        'type': p.type.name,
        'owner': p.owner.name,
      }).toList(),
      'player2_captured': state.player2Captured.map((p) => {
        'type': p.type.name,
        'owner': p.owner.name,
      }).toList(),
      'current_player': state.currentPlayer.name,
      'winner': state.winner?.name,
    };
  }
  
  static GameState _gameStateFromJson(Map<String, dynamic> json) {
    final board = <Position, Piece>{};
    if (json['board'] != null) {
      (json['board'] as Map<String, dynamic>).forEach((key, value) {
        final coords = key.split(',');
        final pos = Position(int.parse(coords[0]), int.parse(coords[1]));
        final pieceData = value as Map<String, dynamic>;
        board[pos] = Piece(
          type: PieceType.values.firstWhere((e) => e.name == pieceData['type']),
          owner: Player.values.firstWhere((e) => e.name == pieceData['owner']),
        );
      });
    }
    
    final player1Captured = (json['player1_captured'] as List<dynamic>?)
        ?.map((p) => Piece(
          type: PieceType.values.firstWhere((e) => e.name == p['type']),
          owner: Player.values.firstWhere((e) => e.name == p['owner']),
        ))
        .toList() ?? [];
    
    final player2Captured = (json['player2_captured'] as List<dynamic>?)
        ?.map((p) => Piece(
          type: PieceType.values.firstWhere((e) => e.name == p['type']),
          owner: Player.values.firstWhere((e) => e.name == p['owner']),
        ))
        .toList() ?? [];
    
    return GameState(
      board: board,
      player1Captured: player1Captured,
      player2Captured: player2Captured,
      currentPlayer: Player.values.firstWhere((e) => e.name == json['current_player']),
      winner: json['winner'] != null
          ? Player.values.firstWhere((e) => e.name == json['winner'])
          : null,
    );
  }
}

