import 'dart:async';
import 'package:flutter/material.dart';
import '../models/piece.dart';
import '../models/position.dart';
import '../models/game_state.dart';
import '../game_logic.dart';
import '../services/game_service.dart';
import '../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OnlineGameScreen extends StatefulWidget {
  final String gameRoomId;
  final bool isPlayer1;

  const OnlineGameScreen({
    super.key,
    required this.gameRoomId,
    required this.isPlayer1,
  });

  @override
  State<OnlineGameScreen> createState() => _OnlineGameScreenState();
}

class _OnlineGameScreenState extends State<OnlineGameScreen> {
  late GameState _gameState;
  Timer? _timer;
  RealtimeChannel? _gameChannel;
  bool _isMyTurn = false;

  @override
  void initState() {
    super.initState();
    _gameState = GameState.initial();
    _isMyTurn = widget.isPlayer1;
    _loadGameState();
    _startTimer();
    _watchGameState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _gameChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadGameState() async {
    try {
      final game = await SupabaseService.client
          .from('games')
          .select('game_state, current_player, time_remaining, player1_id, player2_id')
          .eq('id', widget.gameRoomId)
          .single();

      if (mounted) {
        final gameStateJson = game['game_state'];
        if (gameStateJson != null) {
          setState(() {
            _gameState = _parseGameState(gameStateJson as Map<String, dynamic>);
            final currentPlayer = game['current_player'] as String;
            final player1Id = game['player1_id'] as String;
            final currentUserId = SupabaseService.currentUser!.id;
            
            // 현재 사용자가 player1인지 확인
            final isCurrentUserPlayer1 = currentUserId == player1Id;
            _isMyTurn = (currentPlayer == 'player1' && isCurrentUserPlayer1) ||
                        (currentPlayer == 'player2' && !isCurrentUserPlayer1);
            _gameState = _gameState.copyWith(
              timeRemaining: game['time_remaining'] as int? ?? 30,
            );
          });
        }
      }
    } catch (e) {
      // 게임 로드 실패
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('게임을 불러올 수 없습니다: $e')),
        );
      }
    }
  }

  void _watchGameState() {
    _gameChannel = GameService.watchGameState(
      widget.gameRoomId,
      (gameState, timeRemaining) {
        if (mounted) {
          setState(() {
            _gameState = gameState;
            _gameState = _gameState.copyWith(timeRemaining: timeRemaining);
            final currentPlayer = _gameState.currentPlayer;
            _isMyTurn = (currentPlayer == Player.player1 && widget.isPlayer1) ||
                        (currentPlayer == Player.player2 && !widget.isPlayer1);
          });
          _resetTimer();
        }
      },
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      setState(() {
        if (_gameState.winner != null) {
          timer.cancel();
          return;
        }

        if (_gameState.timeRemaining > 0) {
          _gameState = _gameState.copyWith(
            timeRemaining: _gameState.timeRemaining - 1,
          );
          
          // 서버에 타이머 업데이트
          GameService.updateGameState(
            gameId: widget.gameRoomId,
            gameState: _gameState,
            timeRemaining: _gameState.timeRemaining,
          );
        } else {
          // 시간 초과 - 상대방 승리
          final opponent = _gameState.currentPlayer == Player.player1
              ? Player.player2
              : Player.player1;
          _gameState = _gameState.copyWith(winner: opponent);
          timer.cancel();
          
          // 비동기로 승자 ID 가져오기
          _handleTimeOut(opponent);
        }
      });
    });
  }

  void _resetTimer() {
    _gameState = _gameState.copyWith(resetTimer: true);
    _startTimer();
  }

  Future<void> _handleTimeOut(Player winner) async {
    try {
      final game = await SupabaseService.client
          .from('games')
          .select('player1_id, player2_id')
          .eq('id', widget.gameRoomId)
          .single();
      
      final winnerId = winner == Player.player1
          ? game['player1_id'] as String
          : game['player2_id'] as String;
      
      await GameService.endGame(
        gameId: widget.gameRoomId,
        winnerId: winnerId,
      );
    } catch (e) {
      // 에러 처리
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('게임 종료 처리 중 오류: $e')),
        );
      }
    }
  }

  GameState _parseGameState(Map<String, dynamic> json) {
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
      timeRemaining: json['time_remaining'] as int? ?? 30,
    );
  }

  void _onCellTapped(Position pos) {
    if (_gameState.winner != null) return;
    if (!_isMyTurn) return;

    setState(() {
      // 포로를 놓는 중인 경우
      if (_gameState.isPlacingCaptured && _gameState.pieceToPlace != null) {
        final placeablePositions = GameLogic.getPlaceablePositions(
          _gameState,
          _gameState.currentPlayer,
        );

        if (placeablePositions.contains(pos) && _gameState.capturedPieceIndex != null) {
          _gameState = GameLogic.placeCapturedPiece(
            _gameState,
            pos,
            _gameState.pieceToPlace!,
            _gameState.capturedPieceIndex!,
          );
          _updateGameState();
        } else {
          _gameState = _gameState.copyWith(
            clearPlacing: true,
            pieceToPlace: null,
            capturedPieceIndex: null,
          );
        }
        return;
      }

      if (_gameState.isPlacingCaptured) {
        return;
      }

      // 말이 선택된 상태
      if (_gameState.selectedPosition != null) {
        if (_gameState.selectedPosition == pos) {
          _gameState = _gameState.copyWith(clearSelected: true);
          return;
        }

        if (_gameState.possibleMoves.contains(pos)) {
          _gameState = GameLogic.movePiece(_gameState, _gameState.selectedPosition!, pos);
          _gameState = GameLogic.checkKingSurvival(_gameState);
          _gameState = _gameState.copyWith(clearSelected: true);
          _updateGameState();
          return;
        }

        final piece = _gameState.board[pos];
        if (piece != null && piece.owner == _gameState.currentPlayer) {
          final moves = GameLogic.getPossibleMoves(_gameState, pos);
          _gameState = _gameState.copyWith(
            selectedPosition: pos,
            possibleMoves: moves,
          );
          return;
        }

        _gameState = _gameState.copyWith(clearSelected: true);
        return;
      }

      // 말 선택
      final piece = _gameState.board[pos];
      if (piece != null && piece.owner == _gameState.currentPlayer) {
        final moves = GameLogic.getPossibleMoves(_gameState, pos);
        _gameState = _gameState.copyWith(
          selectedPosition: pos,
          possibleMoves: moves,
        );
      }
    });
  }

  void _onCapturedPieceTapped(Piece piece, int index) {
    if (_gameState.winner != null) return;
    if (!_isMyTurn) return;
    if (piece.owner != _gameState.currentPlayer) return;

    setState(() {
      final placeablePositions = GameLogic.getPlaceablePositions(
        _gameState,
        _gameState.currentPlayer,
      );

      if (placeablePositions.isNotEmpty) {
        _gameState = _gameState.copyWith(
          isPlacingCaptured: true,
          pieceToPlace: piece,
          capturedPieceIndex: index,
          possibleMoves: placeablePositions,
        );
      }
    });
  }

  void _onPieceDropped(Position from, Position to) {
    if (_gameState.winner != null) return;
    if (!_isMyTurn) return;

    setState(() {
      _gameState = GameLogic.movePiece(_gameState, from, to);
      _gameState = GameLogic.checkKingSurvival(_gameState);
      _gameState = _gameState.copyWith(clearSelected: true);
      _updateGameState();
    });
  }

  Future<void> _updateGameState() async {
    await GameService.updateGameState(
      gameId: widget.gameRoomId,
      gameState: _gameState,
      timeRemaining: 30,
    );
    
    if (_gameState.winner != null) {
      final game = await SupabaseService.client
          .from('games')
          .select('player1_id, player2_id')
          .eq('id', widget.gameRoomId)
          .single();
      
      final winnerId = _gameState.winner == Player.player1
          ? game['player1_id'] as String
          : game['player2_id'] as String;
      
      await GameService.endGame(
        gameId: widget.gameRoomId,
        winnerId: winnerId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('온라인 게임'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Navigator.pop(context);
            },
            tooltip: '나가기',
          ),
        ],
      ),
      body: Column(
        children: [
          // Player 2 포로 영역
          _buildCapturedArea(Player.player2, _gameState.player2Captured),
          
          // 게임판
          Expanded(
            child: Center(
              child: _buildBoard(),
            ),
          ),
          
          // Player 1 포로 영역
          _buildCapturedArea(Player.player1, _gameState.player1Captured),
          
          // 현재 턴 표시
          _buildTurnIndicator(),
        ],
      ),
    );
  }

  Widget _buildBoard() {
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.brown, width: 3),
          color: Colors.brown.shade50,
        ),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1,
          ),
          itemCount: 12,
          itemBuilder: (context, index) {
            final row = index ~/ 3;
            final col = index % 3;
            final pos = Position(row, col);
            final piece = _gameState.board[pos];
            final isSelected = _gameState.selectedPosition == pos;
            final isPossibleMove = _gameState.possibleMoves.contains(pos);
            final isPlayer1Territory = pos.isPlayerTerritory(Player.player1);
            final isPlayer2Territory = pos.isPlayerTerritory(Player.player2);

            return DragTarget<Position>(
              onWillAccept: (data) {
                if (data == null || !_isMyTurn) return false;
                final sourcePiece = _gameState.board[data];
                if (sourcePiece == null || sourcePiece.owner != _gameState.currentPlayer) {
                  return false;
                }
                final moves = GameLogic.getPossibleMoves(_gameState, data);
                return moves.contains(pos);
              },
              onAccept: (fromPos) {
                _onPieceDropped(fromPos, pos);
              },
              builder: (context, candidateData, rejectedData) {
                final isDragTarget = candidateData.isNotEmpty;
                return GestureDetector(
                  onTap: () => _onCellTapped(pos),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDragTarget
                          ? Colors.yellow.shade200
                          : isSelected
                              ? Colors.blue.shade200
                              : isPossibleMove
                                  ? Colors.green.shade200
                                  : isPlayer1Territory
                                      ? Colors.red.shade50
                                      : isPlayer2Territory
                                          ? Colors.blue.shade50
                                          : Colors.brown.shade100,
                      border: Border.all(
                        color: isPlayer1Territory
                            ? Colors.red.shade300
                            : isPlayer2Territory
                                ? Colors.blue.shade300
                                : Colors.brown.shade300,
                        width: isDragTarget ? 3 : 1,
                      ),
                    ),
                    child: Center(
                      child: piece != null
                          ? _buildPiece(piece, pos)
                          : isPossibleMove
                              ? const Icon(Icons.circle, size: 20, color: Colors.green)
                              : null,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildPiece(Piece piece, Position pos) {
    final isPlayer1 = piece.owner == Player.player1;
    final isCurrentPlayerPiece = piece.owner == _gameState.currentPlayer;
    
    final pieceWidget = Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: isPlayer1 ? Colors.red.shade300 : Colors.blue.shade300,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Center(
        child: Text(
          piece.displayName,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );

    if (isCurrentPlayerPiece && !_gameState.isPlacingCaptured && _isMyTurn) {
      return Draggable<Position>(
        data: pos,
        feedback: Material(
          color: Colors.transparent,
          child: Opacity(
            opacity: 0.8,
            child: pieceWidget,
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: pieceWidget,
        ),
        onDragStarted: () {
          setState(() {
            final moves = GameLogic.getPossibleMoves(_gameState, pos);
            _gameState = _gameState.copyWith(
              selectedPosition: pos,
              possibleMoves: moves,
            );
          });
        },
        onDragEnd: (details) {
          setState(() {
            if (!details.wasAccepted) {
              _gameState = _gameState.copyWith(clearSelected: true);
            }
          });
        },
        child: pieceWidget,
      );
    } else {
      return pieceWidget;
    }
  }

  Widget _buildCapturedArea(Player player, List<Piece> captured) {
    final isPlayer1 = player == Player.player1;
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isPlayer1 ? Colors.red.shade50 : Colors.blue.shade50,
      child: Row(
        children: [
          Text(
            isPlayer1 ? 'Player 1 포로' : 'Player 2 포로',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isPlayer1 ? Colors.red.shade900 : Colors.blue.shade900,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: captured.length,
              itemBuilder: (context, index) {
                final piece = captured[index];
                return GestureDetector(
                  onTap: () => _onCapturedPieceTapped(piece, index),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isPlayer1 ? Colors.red.shade200 : Colors.blue.shade200,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _gameState.isPlacingCaptured &&
                                _gameState.capturedPieceIndex == index
                            ? Colors.green
                            : Colors.black,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        piece.displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTurnIndicator() {
    if (_gameState.winner != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.green.shade200,
        child: Center(
          child: Text(
            '${_gameState.winner == Player.player1 ? "Player 1" : "Player 2"} 승리!',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    final isPlayer1 = _gameState.currentPlayer == Player.player1;
    final timeColor = _gameState.timeRemaining <= 5
        ? Colors.red
        : _gameState.timeRemaining <= 10
            ? Colors.orange
            : Colors.black;

    return Container(
      padding: const EdgeInsets.all(16),
      color: isPlayer1 ? Colors.red.shade100 : Colors.blue.shade100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '현재 턴: ${isPlayer1 ? "Player 1" : "Player 2"}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isPlayer1 ? Colors.red.shade900 : Colors.blue.shade900,
            ),
          ),
          if (!_isMyTurn) ...[
            const SizedBox(width: 20),
            const Text(
              '(상대방 차례)',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
          const SizedBox(width: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: timeColor, width: 2),
            ),
            child: Text(
              '남은 시간: ${_gameState.timeRemaining}초',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: timeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

