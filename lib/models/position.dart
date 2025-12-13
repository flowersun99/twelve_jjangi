import 'piece.dart';

class Position {
  final int row; // 0-3 (세로, 4행)
  final int col; // 0-2 (가로, 3열)

  Position(this.row, this.col);

  bool isValid() {
    return row >= 0 && row < 4 && col >= 0 && col < 3;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Position && other.row == row && other.col == col;
  }

  @override
  int get hashCode => row.hashCode ^ col.hashCode;

  @override
  String toString() => '($row, $col)';

  // 플레이어의 진영인지 확인 (앞쪽 3칸)
  bool isPlayerTerritory(Player player) {
    if (player == Player.player1) {
      return row == 3; // player1의 진영은 맨 아래 행
    } else {
      return row == 0; // player2의 진영은 맨 위 행
    }
  }
}

