import 'models/piece.dart';
import 'models/position.dart';
import 'models/game_state.dart';

class GameLogic {
  // 말의 이동 가능한 위치 계산
  static List<Position> getPossibleMoves(
    GameState state,
    Position from,
  ) {
    final piece = state.board[from];
    if (piece == null) return [];

    final moves = <Position>[];
    final player = piece.owner;
    final isPlayer1 = player == Player.player1;

    // 방향 정의 (player1 기준: 앞=row 감소, player2 기준: 앞=row 증가)
    // player2의 경우 방향을 반대로 적용
    Position Function(int, int) getForward = isPlayer1
        ? (r, c) => Position(r - 1, c)
        : (r, c) => Position(r + 1, c);
    Position Function(int, int) getBackward = isPlayer1
        ? (r, c) => Position(r + 1, c)
        : (r, c) => Position(r - 1, c);
    Position Function(int, int) getLeft = (r, c) => Position(r, c - 1);
    Position Function(int, int) getRight = (r, c) => Position(r, c + 1);
    Position Function(int, int) getForwardLeft = isPlayer1
        ? (r, c) => Position(r - 1, c - 1)
        : (r, c) => Position(r + 1, c - 1);
    Position Function(int, int) getForwardRight = isPlayer1
        ? (r, c) => Position(r - 1, c + 1)
        : (r, c) => Position(r + 1, c + 1);
    Position Function(int, int) getBackwardLeft = isPlayer1
        ? (r, c) => Position(r + 1, c - 1)
        : (r, c) => Position(r - 1, c - 1);
    Position Function(int, int) getBackwardRight = isPlayer1
        ? (r, c) => Position(r + 1, c + 1)
        : (r, c) => Position(r - 1, c + 1);

    switch (piece.type) {
      case PieceType.jang: // 장: 앞, 뒤, 좌, 우
        _addMoveIfValid(moves, getForward(from.row, from.col), state, player);
        _addMoveIfValid(moves, getBackward(from.row, from.col), state, player);
        _addMoveIfValid(moves, getLeft(from.row, from.col), state, player);
        _addMoveIfValid(moves, getRight(from.row, from.col), state, player);
        break;

      case PieceType.sang: // 상: 대각선 4방향
        _addMoveIfValid(moves, getForwardLeft(from.row, from.col), state, player);
        _addMoveIfValid(moves, getForwardRight(from.row, from.col), state, player);
        _addMoveIfValid(moves, getBackwardLeft(from.row, from.col), state, player);
        _addMoveIfValid(moves, getBackwardRight(from.row, from.col), state, player);
        break;

      case PieceType.wang: // 왕: 모든 방향
        _addMoveIfValid(moves, getForward(from.row, from.col), state, player);
        _addMoveIfValid(moves, getBackward(from.row, from.col), state, player);
        _addMoveIfValid(moves, getLeft(from.row, from.col), state, player);
        _addMoveIfValid(moves, getRight(from.row, from.col), state, player);
        _addMoveIfValid(moves, getForwardLeft(from.row, from.col), state, player);
        _addMoveIfValid(moves, getForwardRight(from.row, from.col), state, player);
        _addMoveIfValid(moves, getBackwardLeft(from.row, from.col), state, player);
        _addMoveIfValid(moves, getBackwardRight(from.row, from.col), state, player);
        break;

      case PieceType.ja: // 자: 앞으로만
        _addMoveIfValid(moves, getForward(from.row, from.col), state, player);
        break;

      case PieceType.hu: // 후: 대각선 뒤쪽 제외한 전 방향 (앞, 뒤, 좌, 우, 앞 대각선 2방향)
        _addMoveIfValid(moves, getForward(from.row, from.col), state, player);
        _addMoveIfValid(moves, getBackward(from.row, from.col), state, player);
        _addMoveIfValid(moves, getLeft(from.row, from.col), state, player);
        _addMoveIfValid(moves, getRight(from.row, from.col), state, player);
        _addMoveIfValid(moves, getForwardLeft(from.row, from.col), state, player);
        _addMoveIfValid(moves, getForwardRight(from.row, from.col), state, player);
        // 뒤 대각선은 제외
        break;
    }

    return moves;
  }

  // 이동 가능한지 확인하고 추가
  static void _addMoveIfValid(
    List<Position> moves,
    Position pos,
    GameState state,
    Player player,
  ) {
    if (!pos.isValid()) return;
    
    final targetPiece = state.board[pos];
    // 같은 편 말이 있으면 이동 불가
    if (targetPiece != null && targetPiece.owner == player) return;
    
    moves.add(pos);
  }

  // 말 이동
  static GameState movePiece(
    GameState state,
    Position from,
    Position to,
  ) {
    final piece = state.board[from];
    if (piece == null) return state;

    final newBoard = Map<Position, Piece>.from(state.board);
    newBoard.remove(from);

    // 상대 말을 잡았는지 확인
    final capturedPiece = state.board[to];
    if (capturedPiece != null && capturedPiece.owner != piece.owner) {
      // 포로로 추가
      final newPlayer1Captured = List<Piece>.from(state.player1Captured);
      final newPlayer2Captured = List<Piece>.from(state.player2Captured);

      // 상대 후(侯)를 잡으면 자(子)로 변환
      // 포로를 잡을 때는 owner를 잡은 사람으로 변경해야 함
      Piece pieceToAdd;
      if (capturedPiece.type == PieceType.hu) {
        pieceToAdd = Piece(type: PieceType.ja, owner: piece.owner);
      } else {
        // 포로의 owner를 잡은 사람으로 변경
        pieceToAdd = Piece(type: capturedPiece.type, owner: piece.owner);
      }

      if (piece.owner == Player.player1) {
        newPlayer1Captured.add(pieceToAdd);
      } else {
        newPlayer2Captured.add(pieceToAdd);
      }

      // 자(子)가 상대 진영에 들어가면 후(侯)로 변신
      Piece pieceToPlace = piece;
      if (piece.type == PieceType.ja && to.isPlayerTerritory(_getOpponent(piece.owner))) {
        pieceToPlace = Piece(type: PieceType.hu, owner: piece.owner);
      }

      newBoard[to] = pieceToPlace;

      // 승리 조건 체크 (상대 왕을 잡았는지)
      if (capturedPiece.type == PieceType.wang) {
        return GameState(
          board: newBoard,
          player1Captured: newPlayer1Captured,
          player2Captured: newPlayer2Captured,
          currentPlayer: piece.owner,
          winner: piece.owner,
        );
      }

      return GameState(
        board: newBoard,
        player1Captured: newPlayer1Captured,
        player2Captured: newPlayer2Captured,
        currentPlayer: _getOpponent(piece.owner),
        timeRemaining: 30, // 타이머 리셋
      );
    }

    // 자(子)가 상대 진영에 들어가면 후(侯)로 변신
    Piece pieceToPlace = piece;
    if (piece.type == PieceType.ja && to.isPlayerTerritory(_getOpponent(piece.owner))) {
      pieceToPlace = Piece(type: PieceType.hu, owner: piece.owner);
    }

    newBoard[to] = pieceToPlace;

    final newState = GameState(
      board: newBoard,
      player1Captured: state.player1Captured,
      player2Captured: state.player2Captured,
      currentPlayer: _getOpponent(piece.owner),
      timeRemaining: 30, // 타이머 리셋
    );

    // 자신의 왕이 상대 진영에 들어갔는지 확인
    // 왕이 상대 진영에 들어가면, 상대 턴이 지나고 자신의 턴이 다시 돌아올 때까지 한 턴을 버텼을 때 승리
    // 즉시 승리가 아니라 다음 턴에서 checkKingSurvival로 체크해야 함
    return newState;
  }

  // 포로를 놓을 수 있는 위치 계산
  // 룰: 이미 말이 놓여진 곳이나 상대의 진영에는 말을 내려놓을 수 없다
  // 즉, 자기 진영과 중간 영역의 빈 칸에는 놓을 수 있음
  static List<Position> getPlaceablePositions(GameState state, Player player) {
    final positions = <Position>[];
    final captured = player == Player.player1 
        ? state.player1Captured 
        : state.player2Captured;

    if (captured.isEmpty) return positions;

    // 모든 빈 칸 중에서 상대 진영이 아닌 곳 (자기 진영과 중간 영역 포함)
    for (int row = 0; row < 4; row++) {
      for (int col = 0; col < 3; col++) {
        final pos = Position(row, col);
        // 이미 말이 있으면 불가
        if (state.board.containsKey(pos)) continue;
        // 상대 진영에는 불가 (자기 진영은 가능)
        if (pos.isPlayerTerritory(_getOpponent(player))) continue;
        positions.add(pos);
      }
    }

    return positions;
  }

  // 포로 놓기
  static GameState placeCapturedPiece(
    GameState state,
    Position to,
    Piece piece,
    int capturedIndex,
  ) {
    // 현재 플레이어의 포로인지 확인
    final currentPlayer = state.currentPlayer;
    if (piece.owner != currentPlayer) {
      return state; // 현재 플레이어의 포로가 아니면 무시
    }

    // 놓을 수 있는 위치인지 확인
    final placeablePositions = getPlaceablePositions(state, currentPlayer);
    if (!placeablePositions.contains(to)) {
      return state; // 놓을 수 없는 위치면 무시
    }

    final newBoard = Map<Position, Piece>.from(state.board);
    newBoard[to] = piece;

    final newPlayer1Captured = List<Piece>.from(state.player1Captured);
    final newPlayer2Captured = List<Piece>.from(state.player2Captured);

    // 인덱스로 정확히 제거
    if (piece.owner == Player.player1) {
      if (capturedIndex >= 0 && capturedIndex < newPlayer1Captured.length) {
        newPlayer1Captured.removeAt(capturedIndex);
      }
    } else {
      if (capturedIndex >= 0 && capturedIndex < newPlayer2Captured.length) {
        newPlayer2Captured.removeAt(capturedIndex);
      }
    }

    final newState = GameState(
      board: newBoard,
      player1Captured: newPlayer1Captured,
      player2Captured: newPlayer2Captured,
      currentPlayer: _getOpponent(piece.owner),
      isPlacingCaptured: false,
      pieceToPlace: null,
      capturedPieceIndex: null,
      timeRemaining: 30, // 타이머 리셋
    );

    // 포로를 놓은 후 왕 생존 체크
    return checkKingSurvival(newState);
  }

  // 이전 턴 플레이어의 왕이 상대 진영에서 한 턴을 버텼는지 체크
  // (자신의 왕이 상대 진영에 들어가 상대 턴이 지나고 자신의 턴이 다시 돌아왔을 때 승리)
  static GameState checkKingSurvival(GameState state) {
    // 이전 턴의 플레이어(현재 플레이어의 상대)의 왕이 상대 진영(현재 플레이어의 진영)에 있는지 확인
    final previousPlayer = _getOpponent(state.currentPlayer);
    Position? kingPosition;

    for (var entry in state.board.entries) {
      if (entry.value.type == PieceType.wang && 
          entry.value.owner == previousPlayer &&
          entry.key.isPlayerTerritory(state.currentPlayer)) {
        kingPosition = entry.key;
        break;
      }
    }

    if (kingPosition != null) {
      // 현재 플레이어(상대)가 왕을 잡을 수 있는지 확인
      bool canCapture = false;

      for (var entry in state.board.entries) {
        if (entry.value.owner == state.currentPlayer) {
          final moves = getPossibleMoves(state, entry.key);
          if (moves.contains(kingPosition)) {
            canCapture = true;
            break;
          }
        }
      }

      // 상대가 왕을 잡을 수 없으면 이전 턴 플레이어(왕을 진영에 넣은 플레이어) 승리
      if (!canCapture) {
        return state.copyWith(winner: previousPlayer);
      }
    }

    return state;
  }

  static Player _getOpponent(Player player) {
    return player == Player.player1 ? Player.player2 : Player.player1;
  }
}

