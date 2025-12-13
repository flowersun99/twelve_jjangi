import 'dart:async';
import 'package:flutter/material.dart';
import 'models/piece.dart';
import 'models/position.dart';
import 'models/game_state.dart';
import 'game_logic.dart';
import 'services/supabase_service.dart';
import 'services/auth_service.dart';
import 'screens/auth_screen.dart';
import 'screens/matchmaking_screen.dart';
import 'services/matchmaking_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Supabase 초기화 (실제 URL과 키로 교체 필요)
  // TODO: Supabase 프로젝트 생성 후 URL과 anonKey를 입력하세요
  await SupabaseService.initialize(
    url: 'YOUR_SUPABASE_URL', // 예: 'https://xxxxx.supabase.co'
    anonKey: 'YOUR_SUPABASE_ANON_KEY', // 예: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '십이장기',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        useMaterial3: true,
      ),
      home: const MainPage(),
      routes: {
        '/game': (context) => const GameScreen(),
        '/rules': (context) => const RulesPage(),
        '/auth': (context) => const AuthScreen(),
      },
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  void _showGameModeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            '게임 모드 선택',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.brown,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    if (!SupabaseService.isAuthenticated) {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AuthScreen()),
                      );
                      if (result != true) return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MatchmakingScreen(
                          mode: GameMode.normal,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown.shade400,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '일반게임',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    if (!SupabaseService.isAuthenticated) {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AuthScreen()),
                      );
                      if (result != true) return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MatchmakingScreen(
                          mode: GameMode.ranked,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown.shade500,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '랭크게임',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/game');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '2인게임',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('취소'),
            ),
          ],
        );
      },
    );
  }

  void _showComingSoonDialog(BuildContext context, String mode) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(mode),
          content: const Text('곧 출시될 예정입니다!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.brown.shade100,
              Colors.brown.shade50,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '십이장기 온라인',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
              const SizedBox(height: 80),
              SizedBox(
                width: 200,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    _showGameModeDialog(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '게임 시작',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 200,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/rules');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown.shade300,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '게임 설명',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RulesPage extends StatelessWidget {
  const RulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('게임 설명'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '십이장기 게임 규칙',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.brown,
              ),
            ),
            const SizedBox(height: 20),
            _buildSection(
              '게임판',
              '십이장기는 가로 4칸, 세로 3칸 총 12칸으로 이루어진 게임 판에서 진행되며 플레이어들의 바로 앞쪽 3칸이 각자의 진영이 된다.',
            ),
            _buildSection(
              '초기 배치',
              '결승 진출자 2명에게는 4가지 종류의 말이 1개씩 주어지며 각 말은 지정된 위치에 놓인 상태로 게임을 시작한다.',
            ),
            _buildSection(
              '말의 종류와 이동',
              '',
              children: [
                _buildRuleItem('장(將)', '자신의 진영 오른쪽에 놓이는 말로 앞, 뒤와 좌, 우로 이동이 가능하다.'),
                _buildRuleItem('상(相)', '자신의 진영 왼쪽에 놓이며 대각선 4방향으로 이동할 수 있다.'),
                _buildRuleItem('왕(王)', '자신의 진영 중앙에 위치하며 앞, 뒤, 좌, 우, 대각선 방향까지 모든 방향으로 이동이 가능하다.'),
                _buildRuleItem('자(子)', '왕의 앞에 놓이며 오로지 앞으로만 이동할 수 있다.'),
                _buildRuleItem('후(侯)', '자(子)가 상대 진영에 들어가면 뒤집어서 후(侯)로 사용된다. 후(侯)는 대각선 뒤쪽 방향을 제외한 전 방향으로 이동할 수 있다.'),
              ],
            ),
            _buildSection(
              '게임 진행',
              '게임이 시작되면 선 플레이어부터 말 1개를 1칸 이동시킬 수 있다.',
            ),
            _buildSection(
              '포로 시스템',
              '',
              children: [
                _buildRuleItem('포로 잡기', '말을 이동시켜 상대방의 말을 잡은 경우, 해당 말을 포로로 잡게 되며 포로로 잡은 말은 다음 턴부터 자신의 말로 사용할 수 있다.'),
                _buildRuleItem('포로 놓기', '게임 판에 포로로 잡은 말을 내려놓는 행동도 턴을 소모하는 것이며 이미 말이 놓여진 곳이나 상대의 진영에는 말을 내려놓을 수 없다.'),
                _buildRuleItem('후(侯) 포로', '상대방의 후(侯)를 잡아 자신의 말로 사용할 경우에는 자(子)로 뒤집어서 사용해야 한다.'),
                _buildRuleItem('포로 사용', '잡은 말을 사용할 땐 자신이 원하는 턴에 자유롭게 사용가능 하며 원하지 않으면 사용하지 않아도 무관하다.'),
              ],
            ),
            _buildSection(
              '승리 조건',
              '',
              children: [
                _buildRuleItem('조건 1', '한 플레이어가 상대방의 왕(王)을 잡으면 해당 플레이어의 승리로 종료된다.'),
                _buildRuleItem('조건 2', '만약 자신의 왕(王)이 상대방의 진영에 들어가 자신의 턴이 다시 돌아올 때까지 한 턴을 버틸 경우 해당 플레이어의 승리로 게임이 종료된다.'),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                ),
                child: const Text(
                  '돌아가기',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, {List<Widget>? children}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.brown,
            ),
          ),
          const SizedBox(height: 8),
          if (content.isNotEmpty)
            Text(
              content,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          if (children != null) ...children,
        ],
      ),
    );
  }

  Widget _buildRuleItem(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, left: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty)
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                Text(
                  content,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameState _gameState;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _gameState = GameState.initial();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      
      setState(() {
        if (_gameState.winner != null) {
          _timer?.cancel();
          return;
        }

        if (_gameState.timeRemaining > 0) {
          _gameState = _gameState.copyWith(
            timeRemaining: _gameState.timeRemaining - 1,
          );
        } else {
          // 시간 초과 - 상대방 승리
          final opponent = _gameState.currentPlayer == Player.player1
              ? Player.player2
              : Player.player1;
          _gameState = _gameState.copyWith(winner: opponent);
          _timer?.cancel();
        }
      });
    });
  }

  void _resetTimer() {
    _gameState = _gameState.copyWith(resetTimer: true);
    _startTimer();
  }

  void _onCellTapped(Position pos) {
    if (_gameState.winner != null) return;

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
          // 포로를 놓은 후 상태 초기화는 placeCapturedPiece에서 처리됨
          _resetTimer(); // 타이머 리셋
        } else {
          // 취소
          _gameState = _gameState.copyWith(
            clearPlacing: true,
            pieceToPlace: null,
            capturedPieceIndex: null,
          );
        }
        return;
      }

      // 포로를 놓는 중이면 말 선택 불가
      if (_gameState.isPlacingCaptured) {
        return;
      }

      // 말이 선택된 상태
      if (_gameState.selectedPosition != null) {
        // 같은 말을 다시 클릭하면 선택 해제
        if (_gameState.selectedPosition == pos) {
          _gameState = _gameState.copyWith(clearSelected: true);
          return;
        }

        // 이동 가능한 위치를 클릭한 경우
        if (_gameState.possibleMoves.contains(pos)) {
          _gameState = GameLogic.movePiece(
            _gameState,
            _gameState.selectedPosition!,
            pos,
          );
          _gameState = GameLogic.checkKingSurvival(_gameState);
          _gameState = _gameState.copyWith(clearSelected: true);
          _resetTimer(); // 타이머 리셋
          return;
        }

        // 다른 말을 클릭한 경우
        final piece = _gameState.board[pos];
        if (piece != null && piece.owner == _gameState.currentPlayer) {
          final moves = GameLogic.getPossibleMoves(_gameState, pos);
          _gameState = _gameState.copyWith(
            selectedPosition: pos,
            possibleMoves: moves,
          );
          return;
        }

        // 빈 칸이나 상대 말을 클릭한 경우 선택 해제
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

  void _resetGame() {
    setState(() {
      _gameState = GameState.initial();
      _resetTimer(); // 타이머 리셋
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('십이장기'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetGame,
            tooltip: '게임 다시 시작',
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
                if (data == null) return false;
                // 현재 플레이어의 말이고, 이동 가능한 위치인지 확인
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
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );

    // 현재 플레이어의 말만 드래그 가능
    if (isCurrentPlayerPiece && !_gameState.isPlacingCaptured) {
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
            // 드래그가 끝났지만 드롭되지 않은 경우 선택 해제
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

  void _onPieceDropped(Position from, Position to) {
    if (_gameState.winner != null) return;

    setState(() {
      _gameState = GameLogic.movePiece(_gameState, from, to);
      _gameState = GameLogic.checkKingSurvival(_gameState);
      _gameState = _gameState.copyWith(clearSelected: true);
      _resetTimer(); // 타이머 리셋
    });
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
