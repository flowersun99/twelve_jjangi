import 'piece.dart';
import 'position.dart';

class GameState {
  final Map<Position, Piece> board; // 보드 상태
  final List<Piece> player1Captured; // player1의 포로
  final List<Piece> player2Captured; // player2의 포로
  final Player currentPlayer;
  final Position? selectedPosition; // 선택된 말 위치
  final List<Position> possibleMoves; // 가능한 이동 위치
  final bool isPlacingCaptured; // 포로를 놓는 중인지
  final Piece? pieceToPlace; // 놓을 포로
  final int? capturedPieceIndex; // 놓을 포로의 인덱스
  final Player? winner; // 승자
  final int timeRemaining; // 남은 시간 (초)

  GameState({
    Map<Position, Piece>? board,
    List<Piece>? player1Captured,
    List<Piece>? player2Captured,
    Player? currentPlayer,
    Position? selectedPosition,
    List<Position>? possibleMoves,
    bool? isPlacingCaptured,
    Piece? pieceToPlace,
    int? capturedPieceIndex,
    Player? winner,
    int? timeRemaining,
  })  : board = board ?? {},
        player1Captured = player1Captured ?? [],
        player2Captured = player2Captured ?? [],
        currentPlayer = currentPlayer ?? Player.player1,
        selectedPosition = selectedPosition,
        possibleMoves = possibleMoves ?? [],
        isPlacingCaptured = isPlacingCaptured ?? false,
        pieceToPlace = pieceToPlace,
        capturedPieceIndex = capturedPieceIndex,
        winner = winner,
        timeRemaining = timeRemaining ?? 30;

  GameState copyWith({
    Map<Position, Piece>? board,
    List<Piece>? player1Captured,
    List<Piece>? player2Captured,
    Player? currentPlayer,
    Position? selectedPosition,
    List<Position>? possibleMoves,
    bool? isPlacingCaptured,
    Piece? pieceToPlace,
    int? capturedPieceIndex,
    Player? winner,
    int? timeRemaining,
    bool clearSelected = false,
    bool clearPossibleMoves = false,
    bool clearPlacing = false,
    bool resetTimer = false,
  }) {
    return GameState(
      board: board ?? this.board,
      player1Captured: player1Captured ?? this.player1Captured,
      player2Captured: player2Captured ?? this.player2Captured,
      currentPlayer: currentPlayer ?? this.currentPlayer,
      selectedPosition: clearSelected ? null : (selectedPosition ?? this.selectedPosition),
      possibleMoves: clearPossibleMoves ? [] : (possibleMoves ?? this.possibleMoves),
      isPlacingCaptured: clearPlacing ? false : (isPlacingCaptured ?? this.isPlacingCaptured),
      pieceToPlace: pieceToPlace ?? this.pieceToPlace,
      capturedPieceIndex: clearPlacing ? null : (capturedPieceIndex ?? this.capturedPieceIndex),
      winner: winner ?? this.winner,
      timeRemaining: resetTimer ? 30 : (timeRemaining ?? this.timeRemaining),
    );
  }

  // 초기 보드 설정 (4행 3열)
  static GameState initial() {
    final board = <Position, Piece>{};
    
    // Player1 초기 배치 (row 3, 아래쪽) - 상, 왕, 장 순서
    board[Position(3, 0)] = Piece(type: PieceType.sang, owner: Player.player1); // 상 - 왼쪽
    board[Position(3, 1)] = Piece(type: PieceType.wang, owner: Player.player1); // 왕 - 중앙
    board[Position(3, 2)] = Piece(type: PieceType.jang, owner: Player.player1); // 장 - 오른쪽

    // Player2 초기 배치 (row 0, 위쪽) - 장, 왕, 상 순서
    board[Position(0, 0)] = Piece(type: PieceType.jang, owner: Player.player2); // 장 - 왼쪽
    board[Position(0, 1)] = Piece(type: PieceType.wang, owner: Player.player2); // 왕 - 중앙
    board[Position(0, 2)] = Piece(type: PieceType.sang, owner: Player.player2); // 상 - 오른쪽
    
    // 자(子)는 왕 앞에 배치 (Player1: row 2, col 1 / Player2: row 1, col 1)
    board[Position(2, 1)] = Piece(type: PieceType.ja, owner: Player.player1);  // 자 - 왕 앞
    board[Position(1, 1)] = Piece(type: PieceType.ja, owner: Player.player2);  // 자 - 왕 앞

    return GameState(
      board: board,
      currentPlayer: Player.player1,
    );
  }
}

