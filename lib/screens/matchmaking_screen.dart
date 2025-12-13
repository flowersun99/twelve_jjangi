import 'package:flutter/material.dart';
import 'dart:async';
import '../services/matchmaking_service.dart';
import '../services/game_service.dart';
import '../services/supabase_service.dart';
import 'online_game_screen.dart';

class MatchmakingScreen extends StatefulWidget {
  final GameMode mode;

  const MatchmakingScreen({super.key, required this.mode});

  @override
  State<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends State<MatchmakingScreen> {
  bool _isMatching = false;
  Timer? _matchTimer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _startMatchmaking();
  }

  @override
  void dispose() {
    _matchTimer?.cancel();
    MatchmakingService.leaveQueue();
    super.dispose();
  }

  Future<void> _startMatchmaking() async {
    setState(() {
      _isMatching = true;
      _elapsedSeconds = 0;
    });

    await MatchmakingService.joinQueue(widget.mode);

    // 주기적으로 매칭 확인
    _matchTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _elapsedSeconds += 2;
      });

      try {
        final opponentId = await MatchmakingService.findMatch(widget.mode);
        
        if (opponentId != null) {
          timer.cancel();
          await MatchmakingService.leaveQueue();
          
          // 게임 방 생성
          final currentUserId = SupabaseService.currentUser!.id;
          final gameRoomId = await GameService.createGameRoom(
            player1Id: currentUserId,
            player2Id: opponentId,
            mode: widget.mode.name,
          );
          
          // 상대방도 큐에서 제거 (상대방이 이미 나갔을 수도 있음)
          try {
            await SupabaseService.client
                .from('matchmaking')
                .delete()
                .eq('user_id', opponentId);
          } catch (e) {
            // 무시
          }
          
          if (mounted) {
            // 게임 정보 가져오기
            final game = await SupabaseService.client
                .from('games')
                .select('player1_id')
                .eq('id', gameRoomId)
                .single();
            
            final isCurrentUserPlayer1 = currentUserId == game['player1_id'];
            
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => OnlineGameScreen(
                  gameRoomId: gameRoomId,
                  isPlayer1: isCurrentUserPlayer1,
                ),
              ),
            );
          }
        }
      } catch (e) {
        // 매칭 실패 시 계속 시도
      }
    });
  }

  void _cancelMatchmaking() {
    _matchTimer?.cancel();
    MatchmakingService.leaveQueue();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.mode == GameMode.normal ? "일반" : "랭크"}게임 매칭'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            const Text(
              '상대방을 찾는 중...',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              '대기 시간: ${_elapsedSeconds}초',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _cancelMatchmaking,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('매칭 취소'),
            ),
          ],
        ),
      ),
    );
  }
}

