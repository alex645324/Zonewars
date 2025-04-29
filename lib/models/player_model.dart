class Player {
  final String id;
  final String name;
  final String avatarAsset;
  int lives;
  final bool isCurrentPlayer;
  bool isSpectator;
  bool codeEntered;
  
  Player({
    required this.id,
    required this.name,
    required this.avatarAsset,
    this.lives = 3,
    this.isCurrentPlayer = false,
    this.isSpectator = false,
    this.codeEntered = false,
  });
  
  factory Player.fromMap(
    Map<String, dynamic> map, {
    required String id,
    required String currentPlayerId,
  }) {
    // Calculate lives based on elimination count
    final int eliminationCount = map['eliminationCount'] ?? 0;
    final int maxLives = 3;
    final int livesLeft = (maxLives - eliminationCount).clamp(0, maxLives);

    return Player(
      id: id,
      name: map['name'] ?? 'Unknown Player',
      avatarAsset: 'lib/assets/avatar1.png', // Default avatar
      lives: livesLeft,
      isCurrentPlayer: id == currentPlayerId,
      isSpectator: map['isSpectator'] ?? false,
      codeEntered: map['codeEntered'] ?? false,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'eliminationCount': (3 - lives).clamp(0, 3),
      'isSpectator': isSpectator,
      'codeEntered': codeEntered,
    };
  }
}