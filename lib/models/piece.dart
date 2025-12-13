enum PieceType {
  jang, // 장(將)
  sang, // 상(相)
  wang, // 왕(王)
  ja,   // 자(子)
  hu,   // 후(侯) - 자가 상대 진영에 들어가면 변신
}

enum Player {
  player1,
  player2,
}

class Piece {
  final PieceType type;
  final Player owner;
  final bool isCaptured; // 포로 상태인지

  Piece({
    required this.type,
    required this.owner,
    this.isCaptured = false,
  });

  Piece copyWith({
    PieceType? type,
    Player? owner,
    bool? isCaptured,
  }) {
    return Piece(
      type: type ?? this.type,
      owner: owner ?? this.owner,
      isCaptured: isCaptured ?? this.isCaptured,
    );
  }

  String get displayName {
    switch (type) {
      case PieceType.jang:
        return '장';
      case PieceType.sang:
        return '상';
      case PieceType.wang:
        return '왕';
      case PieceType.ja:
        return '자';
      case PieceType.hu:
        return '후';
    }
  }
}

