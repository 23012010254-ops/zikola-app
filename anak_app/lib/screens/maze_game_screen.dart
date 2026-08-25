import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/audio_service.dart';
import 'dart:math' as math;
import 'dart:async';

/// Konfigurasi Level Labirin
class _MazeLevelConfig {
  final int levelNumber;
  final int gridSize;
  final int coinCount;
  final bool hasEnemy;
  final int enemyCount;
  final bool hasKey;
  final bool hasFog;
  final bool hasBatteryDecay;
  final double initialFogRadius;
  final int targetTimeSec;
  final int baseLevelScore;

  const _MazeLevelConfig({
    required this.levelNumber,
    required this.gridSize,
    required this.coinCount,
    required this.hasEnemy,
    required this.enemyCount,
    required this.hasKey,
    required this.hasFog,
    required this.hasBatteryDecay,
    required this.initialFogRadius,
    required this.targetTimeSec,
    required this.baseLevelScore,
  });
}

/// Representasi musuh luar angkasa yang berpatroli
class _SpaceHazard {
  int x;
  int y;
  int dx;
  int dy;
  final int startX;
  final int startY;
  final int range;
  int stepsMoved = 0;

  _SpaceHazard({
    required this.x,
    required this.y,
    required this.dx,
    required this.dy,
    required this.range,
  }) : startX = x, startY = y;
}

class MazeGameScreen extends StatefulWidget {
  const MazeGameScreen({super.key});

  @override
  State<MazeGameScreen> createState() => _MazeGameScreenState();
}

class _MazeGameScreenState extends State<MazeGameScreen>
    with TickerProviderStateMixin {
  
  // ── Konfigurasi 8 Level ──────────────────────────────────────────
  static const List<_MazeLevelConfig> _levelConfigs = [
    _MazeLevelConfig(
      levelNumber: 1,
      gridSize: 7,
      coinCount: 3,
      hasEnemy: false,
      enemyCount: 0,
      hasKey: false,
      hasFog: false,
      hasBatteryDecay: false,
      initialFogRadius: 99.0,
      targetTimeSec: 25,
      baseLevelScore: 100,
    ),
    _MazeLevelConfig(
      levelNumber: 2,
      gridSize: 7,
      coinCount: 3,
      hasEnemy: false,
      enemyCount: 0,
      hasKey: true,
      hasFog: false,
      hasBatteryDecay: false,
      initialFogRadius: 99.0,
      targetTimeSec: 30,
      baseLevelScore: 150,
    ),
    _MazeLevelConfig(
      levelNumber: 3,
      gridSize: 9,
      coinCount: 4,
      hasEnemy: true,
      enemyCount: 1,
      hasKey: false,
      hasFog: false,
      hasBatteryDecay: false,
      initialFogRadius: 99.0,
      targetTimeSec: 40,
      baseLevelScore: 200,
    ),
    _MazeLevelConfig(
      levelNumber: 4,
      gridSize: 9,
      coinCount: 4,
      hasEnemy: true,
      enemyCount: 2,
      hasKey: false,
      hasFog: false,
      hasBatteryDecay: false,
      initialFogRadius: 99.0,
      targetTimeSec: 45,
      baseLevelScore: 250,
    ),
    _MazeLevelConfig(
      levelNumber: 5,
      gridSize: 11,
      coinCount: 4,
      hasEnemy: true,
      enemyCount: 2,
      hasKey: true,
      hasFog: false,
      hasBatteryDecay: false,
      initialFogRadius: 99.0,
      targetTimeSec: 55,
      baseLevelScore: 300,
    ),
    _MazeLevelConfig(
      levelNumber: 6,
      gridSize: 11,
      coinCount: 4,
      hasEnemy: true,
      enemyCount: 2,
      hasKey: false,
      hasFog: true,
      hasBatteryDecay: false,
      initialFogRadius: 4.0,
      targetTimeSec: 65,
      baseLevelScore: 350,
    ),
    _MazeLevelConfig(
      levelNumber: 7,
      gridSize: 13,
      coinCount: 5,
      hasEnemy: true,
      enemyCount: 3,
      hasKey: false,
      hasFog: true,
      hasBatteryDecay: true,
      initialFogRadius: 3.0,
      targetTimeSec: 80,
      baseLevelScore: 400,
    ),
    _MazeLevelConfig(
      levelNumber: 8,
      gridSize: 13,
      coinCount: 5,
      hasEnemy: true,
      enemyCount: 3,
      hasKey: true,
      hasFog: true,
      hasBatteryDecay: true,
      initialFogRadius: 2.5,
      targetTimeSec: 95,
      baseLevelScore: 500,
    ),
  ];

  static const int _totalLevels = 8;

  // ── State Game ──────────────────────────────────────────────────
  String _gameState = 'menu'; // 'menu', 'level_select', 'playing', 'level_complete', 'game_over', 'victory'
  int _level = 1;
  bool get _isEvenLevel => _level % 2 == 0;
  int _highestUnlocked = 1;
  List<int> _starRatings = List.filled(_totalLevels, 0);

  late int _gridSize;
  late List<List<int>> _grid; // 0: path, 1: wall, 3: exit, 4: coin, 5: key, 6: laser gate, 7: battery
  late int _playerX, _playerY;
  double _playerAngle = 0.0;
  bool _levelWon = false;
  bool _isMoving = false;
  
  // HUD & Stats
  int _moves = 0;
  int _coinsCollected = 0;
  int _lives = 3;
  bool _hasKey = false;

  // Asesmen & Skor Akumulatif
  int _totalScore = 0;
  int _totalStars = 0;
  int _totalCoinsCollected = 0;
  int _totalElapsedSeconds = 0;
  int _totalMovesCount = 0;
  int _totalErrorsCount = 0;

  // Per-Level Stats
  int _elapsedSeconds = 0;
  int _levelScore = 0;
  int _levelStars = 0;

  // Fog & FX
  double _fogRadius = 99.0;
  bool _flashRed = false;
  String _hudMessage = "";
  final List<_SpaceHazard> _hazards = [];
  int _gameLoopTicks = 0;

  // Timers
  Timer? _timer;
  Timer? _gameLoopTimer;
  Timer? _hudMessageTimer;

  // Animations
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    AudioService().playGameBGM();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _gameLoopTimer?.cancel();
    _hudMessageTimer?.cancel();
    _pulseController.dispose();
    _rotationController.dispose();
    AudioService().stopBGM();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════
  //  LOGIKA PERMAINAN & LEVEL SETUP
  // ══════════════════════════════════════════════════════════════════

  void _startLevel() {
    final config = _levelConfigs[_level - 1];
    _gridSize = config.gridSize;
    _fogRadius = config.initialFogRadius;
    _levelWon = false;
    _moves = 0;
    _coinsCollected = 0;
    _elapsedSeconds = 0;
    _levelScore = 0;
    _levelStars = 0;
    _isMoving = false;
    _lives = 3;
    _hasKey = false;
    _flashRed = false;
    _hudMessage = "";

    bool success = false;
    int attempts = 0;
    while (!success && attempts < 30) {
      attempts++;
      _generateMazeDFS();
      
      // Tempatkan gerbang laser & kunci
      if (config.hasKey) {
        int ex = _gridSize - 2;
        int ey = _gridSize - 2;
        int n1 = _grid[ey - 1][ex];
        int n2 = _grid[ey][ex - 1];
        
        if (n1 == 0 && n2 == 0) {
          // Jika keduanya jalan terbuka, tutup salah satu agar tidak bisa dibypass gerbang
          _grid[ey - 1][ex] = 6; // Gerbang laser
          _grid[ey][ex - 1] = 1; // Jadikan dinding
        } else if (n1 == 0) {
          _grid[ey - 1][ex] = 6;
        } else if (n2 == 0) {
          _grid[ey][ex - 1] = 6;
        } else {
          // Fallback
          _grid[ey - 1][ex] = 6;
        }
        _placeItemFar(5, 1); // 5 = Key
      }

      // Tempatkan baterai jika ada fog decay
      if (config.hasFog && config.hasBatteryDecay) {
        _placeItemFar(7, 2); // 7 = Battery (2 unit)
      }

      // Tempatkan kristal koin
      _placeCrystals(config.coinCount);

      // Verifikasi solvability labirin
      if (_checkSolvability(config.hasKey)) {
        success = true;
      }
    }

    // Tempatkan musuh patroli setelah maze fix
    if (config.hasEnemy) {
      _placeHazards(config.enemyCount);
    } else {
      _hazards.clear();
    }

    _startTimers();
  }

  bool _checkSolvability(bool needKey) {
    int startX = 1;
    int startY = 1;
    int exitX = _gridSize - 2;
    int exitY = _gridSize - 2;

    if (needKey) {
      // Cari posisi kunci (value 5)
      int keyX = -1;
      int keyY = -1;
      for (int y = 1; y < _gridSize - 1; y++) {
        for (int x = 1; x < _gridSize - 1; x++) {
          if (_grid[y][x] == 5) {
            keyX = x;
            keyY = y;
            break;
          }
        }
        if (keyX != -1) break;
      }

      if (keyX == -1 || keyY == -1) return false;

      // 1. Jalur dari start ke kunci TANPA melewati gerbang laser (6)
      bool canReachKey = _hasPath(startX, startY, keyX, keyY, blockedValues: {6});
      if (!canReachKey) return false;

      // 2. Jalur dari kunci ke exit (gerbang laser dianggap terbuka, blockedValues kosong)
      bool canReachExit = _hasPath(keyX, keyY, exitX, exitY, blockedValues: {});
      return canReachExit;
    } else {
      // Jalur langsung dari start ke exit
      return _hasPath(startX, startY, exitX, exitY, blockedValues: {});
    }
  }

  bool _hasPath(int sx, int sy, int tx, int ty, {required Set<int> blockedValues}) {
    final visited = List.generate(_gridSize, (_) => List.generate(_gridSize, (_) => false));
    final queue = <List<int>>[];

    queue.add([sx, sy]);
    visited[sy][sx] = true;

    final dirs = [
      [0, 1], [0, -1], [1, 0], [-1, 0]
    ];

    while (queue.isNotEmpty) {
      final curr = queue.removeAt(0);
      final cx = curr[0];
      final cy = curr[1];

      if (cx == tx && cy == ty) return true;

      for (var d in dirs) {
        int nx = cx + d[0];
        int ny = cy + d[1];

        if (nx >= 0 && nx < _gridSize && ny >= 0 && ny < _gridSize) {
          int val = _grid[ny][nx];
          // Dinding (1) tidak bisa dilewati
          if (!visited[ny][nx] && val != 1 && !blockedValues.contains(val)) {
            visited[ny][nx] = true;
            queue.add([nx, ny]);
          }
        }
      }
    }
    return false;
  }

  void _startTimers() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_gameState == 'playing' && !_levelWon && mounted) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });

    _gameLoopTimer?.cancel();
    _gameLoopTicks = 0;
    _gameLoopTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_gameState == 'playing' && !_levelWon && mounted) {
        _gameLoopTicks++;

        // Gerakkan patroli musuh setiap 400ms (4 ticks)
        if (_gameLoopTicks % 4 == 0) {
          _updateHazards();
        }

        // Penyusutan radius cahaya (fog) setiap 1 detik
        final config = _levelConfigs[_level - 1];
        if (config.hasFog && config.hasBatteryDecay && _gameLoopTicks % 10 == 0) {
          setState(() {
            _fogRadius -= 0.07;
            if (_fogRadius < 1.1) {
              _fogRadius = 1.1; // minimum vision
            }
          });
        }
      }
    });
  }

  // Pembangkit Labirin DFS
  void _generateMazeDFS() {
    _grid = List.generate(_gridSize, (_) => List.generate(_gridSize, (_) => 1));

    final random = math.Random();
    void carve(int x, int y) {
      _grid[y][x] = 0;
      final dirs = [
        [0, -2],
        [2, 0],
        [0, 2],
        [-2, 0]
      ]..shuffle(random);

      for (var dir in dirs) {
        int nx = x + dir[0];
        int ny = y + dir[1];
        if (nx > 0 &&
            nx < _gridSize - 1 &&
            ny > 0 &&
            ny < _gridSize - 1 &&
            _grid[ny][nx] == 1) {
          _grid[y + dir[1] ~/ 2][x + dir[0] ~/ 2] = 0;
          carve(nx, ny);
        }
      }
    }

    carve(1, 1);

    _playerX = 1;
    _playerY = 1;
    _playerAngle = 0.0;

    // Pastikan exit di pojok bawah kanan selalu terhubung
    int targetX = _gridSize - 2;
    int targetY = _gridSize - 2;
    if (_gridSize % 2 == 0) {
      _grid[targetY - 1][targetX] = 0;
    }
    _grid[targetY][targetX] = 3; // 3 = Exit/Wormhole
  }

  // Tempatkan barang acak yang jauh dari titik start
  void _placeItemFar(int cellValue, int count) {
    final random = math.Random();
    final List<List<int>> candidates = [];

    for (int y = 1; y < _gridSize - 1; y++) {
      for (int x = 1; x < _gridSize - 1; x++) {
        if (_grid[y][x] == 0 && !(x == 1 && y == 1) && !(x == _gridSize - 2 && y == _gridSize - 2)) {
          int dist = (x - 1).abs() + (y - 1).abs();
          if (dist > _gridSize ~/ 2) {
            candidates.add([x, y]);
          }
        }
      }
    }

    candidates.shuffle(random);
    int placed = math.min(count, candidates.length);
    for (int i = 0; i < placed; i++) {
      _grid[candidates[i][1]][candidates[i][0]] = cellValue;
    }
  }

  // Tempatkan kristal energi
  void _placeCrystals(int count) {
    final random = math.Random();
    final List<List<int>> paths = [];

    for (int y = 1; y < _gridSize - 1; y++) {
      for (int x = 1; x < _gridSize - 1; x++) {
        if (_grid[y][x] == 0 && !(x == 1 && y == 1) && _grid[y][x] != 5 && _grid[y][x] != 6 && _grid[y][x] != 7) {
          paths.add([x, y]);
        }
      }
    }

    paths.shuffle(random);
    int placed = math.min(count, paths.length);
    for (int i = 0; i < placed; i++) {
      _grid[paths[i][1]][paths[i][0]] = 4; // 4 = Crystal
    }
  }

  // Tempatkan musuh patroli luar angkasa
  void _placeHazards(int count) {
    _hazards.clear();
    final random = math.Random();
    final List<List<int>> paths = [];

    for (int y = 1; y < _gridSize - 1; y++) {
      for (int x = 1; x < _gridSize - 1; x++) {
        if (_grid[y][x] == 0 && !(x == 1 && y == 1) && _grid[y][x] != 5 && _grid[y][x] != 6 && _grid[y][x] != 7) {
          int dist = (x - 1).abs() + (y - 1).abs();
          if (dist > 3) {
            paths.add([x, y]);
          }
        }
      }
    }

    paths.shuffle(random);
    int placed = math.min(count, paths.length);
    for (int i = 0; i < placed; i++) {
      int hx = paths[i][0];
      int hy = paths[i][1];

      // Tentukan arah gerak awal berdasarkan koridor kosong
      int dx = 0;
      int dy = 0;
      if (hx + 1 < _gridSize - 1 && _grid[hy][hx + 1] == 0) {
        dx = 1;
      } else if (hy + 1 < _gridSize - 1 && _grid[hy + 1][hx] == 0) {
        dy = 1;
      } else if (hx - 1 > 0 && _grid[hy][hx - 1] == 0) {
        dx = -1;
      } else if (hy - 1 > 0 && _grid[hy - 1][hx] == 0) {
        dy = -1;
      } else {
        dx = 1;
      }

      int range = random.nextInt(3) + 2; // range 2 - 4 langkah
      _hazards.add(_SpaceHazard(
        x: hx,
        y: hy,
        dx: dx,
        dy: dy,
        range: range,
      ));
    }
  }

  // ══════════════════════════════════════════════════════════════════
  //  KONTROL & PENGGERAK
  // ══════════════════════════════════════════════════════════════════

  // Penanganan Swipe Gesture (Slide to Wall)
  void _handleSwipe(DragEndDetails details) {
    if (_levelWon || _isMoving || _gameState != 'playing' || _flashRed) return;

    final velocity = details.velocity.pixelsPerSecond;
    int dx = 0;
    int dy = 0;

    if (velocity.dx.abs() > velocity.dy.abs()) {
      if (velocity.dx.abs() < 120) return;
      dx = velocity.dx > 0 ? 1 : -1;
    } else {
      if (velocity.dy.abs() < 120) return;
      dy = velocity.dy > 0 ? 1 : -1;
    }

    if (dx != 0 || dy != 0) {
      _movePlayerSlide(dx, dy);
    }
  }

  // Meluncur sampai mentok dinding
  void _movePlayerSlide(int dx, int dy) async {
    if (_levelWon || _isMoving || _gameState != 'playing' || _flashRed) return;
    _isMoving = true;
    bool moved = false;

    while (_isMoving && _gameState == 'playing') {
      int newX = _playerX + dx;
      int newY = _playerY + dy;

      if (newX >= 0 && newX < _gridSize && newY >= 0 && newY < _gridSize) {
        int targetVal = _grid[newY][newX];
        
        // Tabrak dinding atau gerbang terkunci
        if (targetVal == 1 || (targetVal == 6 && !_hasKey)) {
          break;
        }

        setState(() {
          _playerX = newX;
          _playerY = newY;
          moved = true;
          _totalMovesCount++;
          
          if (dx > 0) _playerAngle = math.pi / 2;
          if (dx < 0) _playerAngle = -math.pi / 2;
          if (dy > 0) _playerAngle = math.pi;
          if (dy < 0) _playerAngle = 0;
        });

        _checkCellEffects(newX, newY);

        if (_checkCollision()) {
          break; // Berhenti meluncur jika kena musuh
        }

        if (_gameState != 'playing') {
          break; // Keluar jika menang
        }

        await Future.delayed(const Duration(milliseconds: 65));
      } else {
        break;
      }
    }

    if (moved) {
      _moves++;
      AudioService().playClick();
    }
    _isMoving = false;
  }

  // Bergerak tepat 1 langkah (D-pad)
  void _movePlayerOneStep(int dx, int dy) {
    if (_levelWon || _isMoving || _gameState != 'playing' || _flashRed) return;

    int newX = _playerX + dx;
    int newY = _playerY + dy;

    if (newX >= 0 && newX < _gridSize && newY >= 0 && newY < _gridSize) {
      int targetVal = _grid[newY][newX];

      if (targetVal == 1) return;
      if (targetVal == 6 && !_hasKey) {
        AudioService().playWrong();
        _showHudMessage(_isEvenLevel ? "Gerbang Kuil Terkunci! 🔴" : "Gerbang Laser Terkunci! 🔴");
        return;
      }

      setState(() {
        _playerX = newX;
        _playerY = newY;
        _moves++;
        _totalMovesCount++;

        if (dx > 0) _playerAngle = math.pi / 2;
        if (dx < 0) _playerAngle = -math.pi / 2;
        if (dy > 0) _playerAngle = math.pi;
        if (dy < 0) _playerAngle = 0;
      });

      AudioService().playClick();
      _checkCellEffects(newX, newY);
      _checkCollision();
    }
  }

  // Cek barang di sel baru
  void _checkCellEffects(int x, int y) {
    int value = _grid[y][x];

    if (value == 4) { // Kristal Koin
      setState(() {
        _grid[y][x] = 0;
        _coinsCollected++;
      });
      AudioService().playCorrect();
      _showHudMessage(_isEvenLevel ? "+1 Koin Emas Kuno! 🪙" : "+1 Kristal Energi! 💎");
    } 
    else if (value == 5) { // Kunci
      setState(() {
        _grid[y][x] = 0;
        _hasKey = true;
        
        // Hilangkan gerbang laser (6) dari labirin
        for (int r = 0; r < _gridSize; r++) {
          for (int c = 0; c < _gridSize; c++) {
            if (_grid[r][c] == 6) {
              _grid[r][c] = 0;
            }
          }
        }
      });
      AudioService().playCorrect();
      _showHudMessage(_isEvenLevel ? "Gerbang Kuil Terbuka! 🔑" : "Pintu Laser Terbuka! 🔑");
    } 
    else if (value == 7) { // Baterai
      setState(() {
        _grid[y][x] = 0;
        _fogRadius = _levelConfigs[_level - 1].initialFogRadius; // isi ulang ke radius awal level
      });
      AudioService().playCorrect();
      _showHudMessage(_isEvenLevel ? "Obor Api Dinyalakan! 🔥" : "Senter Diisi Ulang! 🔋");
      // Tempatkan baterai baru jauh di lorong lain
      _placeItemFar(7, 1);
    } 
    else if (value == 3) { // Wormhole Keluar (Menang)
      _levelWon = true;
      _timer?.cancel();
      _gameLoopTimer?.cancel();
      AudioService().playAchievement();
      
      _calculateLevelScore();
      
      setState(() {
        _gameState = 'level_complete';
      });
    }
  }

  // Update pergerakan musuh
  void _updateHazards() {
    if (_checkCollision()) return;

    setState(() {
      for (var hazard in _hazards) {
        int nx = hazard.x + hazard.dx;
        int ny = hazard.y + hazard.dy;

        // Musuh tidak boleh lewat dinding (1), gerbang laser (6), atau wormhole (3)
        bool canMove = nx >= 0 && nx < _gridSize && ny >= 0 && ny < _gridSize &&
                       _grid[ny][nx] != 1 && _grid[ny][nx] != 6 && _grid[ny][nx] != 3;

        if (canMove && hazard.stepsMoved < hazard.range) {
          hazard.x = nx;
          hazard.y = ny;
          hazard.stepsMoved++;
        } else {
          // Balik arah
          hazard.dx = -hazard.dx;
          hazard.dy = -hazard.dy;
          hazard.stepsMoved = 0;

          int rnx = hazard.x + hazard.dx;
          int rny = hazard.y + hazard.dy;
          bool canMoveReverse = rnx >= 0 && rnx < _gridSize && rny >= 0 && rny < _gridSize &&
                               _grid[rny][rnx] != 1 && _grid[rny][rnx] != 6 && _grid[rny][rnx] != 3;

          if (canMoveReverse) {
            hazard.x = rnx;
            hazard.y = rny;
            hazard.stepsMoved = 1;
          }
        }
      }
    });

    _checkCollision();
  }

  // Deteksi tabrakan
  bool _checkCollision() {
    for (var hazard in _hazards) {
      if (hazard.x == _playerX && hazard.y == _playerY) {
        _handlePlayerHit();
        return true;
      }
    }
    return false;
  }

  // Pemain kena musuh
  void _handlePlayerHit() {
    AudioService().playWrong();
    _totalErrorsCount++;
    _lives--;

    _showHudMessage(_isEvenLevel ? "Disengat Serangga! Terluka 💥" : "Kena Alien! Pelindung Rusak 💥");

    setState(() {
      _flashRed = true;
      _isMoving = false;
    });

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _flashRed = false;
        });
      }
    });

    // Reset posisi ke start
    _playerX = 1;
    _playerY = 1;
    _playerAngle = 0.0;

    if (_lives <= 0) {
      _timer?.cancel();
      _gameLoopTimer?.cancel();
      AudioService().playGameOver();
      setState(() {
        _gameState = 'game_over';
      });
    }
  }

  // Tampilkan teks HUD melayang singkat
  void _showHudMessage(String msg) {
    setState(() {
      _hudMessage = msg;
    });
    _hudMessageTimer?.cancel();
    _hudMessageTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) {
        setState(() {
          _hudMessage = "";
        });
      }
    });
  }

  // ══════════════════════════════════════════════════════════════════
  //  PERHITUNGAN SKOR & STAR TELEMETRI
  // ══════════════════════════════════════════════════════════════════

  void _calculateLevelScore() {
    final config = _levelConfigs[_level - 1];
    
    // Penentuan Bintang
    if (_lives == 3 && _elapsedSeconds <= config.targetTimeSec) {
      _levelStars = 3;
    } else if (_lives >= 2 && _elapsedSeconds <= config.targetTimeSec * 1.5) {
      _levelStars = 2;
    } else {
      _levelStars = 1;
    }

    if (_levelStars > _starRatings[_level - 1]) {
      _starRatings[_level - 1] = _levelStars;
    }

    final coinBonus = _coinsCollected * 50;
    final starMult = _levelStars == 3 ? 2.0 : (_levelStars == 2 ? 1.5 : 1.0);
    final timeBonus = _elapsedSeconds < config.targetTimeSec ? (config.targetTimeSec - _elapsedSeconds) * 3 : 0;

    _levelScore = ((config.baseLevelScore + coinBonus) * starMult + timeBonus).round();
    
    _totalScore += _levelScore;
    _totalCoinsCollected += _coinsCollected;
    _totalElapsedSeconds += _elapsedSeconds;
    _totalStars = _starRatings.reduce((sum, val) => sum + val);

    // Kunci progres level baru
    if (_level == _highestUnlocked && _level < _totalLevels) {
      _highestUnlocked = _level + 1;
    }
  }

  void _finishGame() {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.addPointsFromScore(_totalScore);
    appState.addSticker('maze-expert');

    int avgResponseMs = _totalMovesCount > 0 ? (_totalElapsedSeconds * 1000) ~/ _totalMovesCount : 0;

    // Asesmen Kognitif
    appState.updateTestResults('cognitive', {
      'completed': true,
      'score': _totalScore,
      'timeSpent': _totalElapsedSeconds,
      'percentage': ((_totalStars / (_totalLevels * 3)) * 100).round(),
    });

    appState.updateGameAssessment('cognitiveGame', GameSession(
      score: _totalScore,
      timeSpent: _totalElapsedSeconds,
      errors: _totalErrorsCount,
      correctAnswers: _totalCoinsCollected,
      totalItems: _totalCoinsCollected,
      avgResponseTimeMs: avgResponseMs,
      maxLevelReached: _highestUnlocked,
    ));
  }

  bool _isCellVisible(int x, int y) {
    final config = _levelConfigs[_level - 1];
    if (!config.hasFog) return true;
    
    double dx = (x - _playerX).toDouble();
    double dy = (y - _playerY).toDouble();
    double distance = math.sqrt(dx * dx + dy * dy);
    
    return distance <= _fogRadius;
  }

  double _getCellFogOpacity(int x, int y) {
    final config = _levelConfigs[_level - 1];
    if (!config.hasFog) return 0.0;

    double dx = (x - _playerX).toDouble();
    double dy = (y - _playerY).toDouble();
    double distance = math.sqrt(dx * dx + dy * dy);

    if (distance < _fogRadius - 1.0) {
      return 0.0;
    } else if (distance <= _fogRadius) {
      // transisi
      return (distance - (_fogRadius - 1.0)).clamp(0.0, 1.0);
    }
    return 1.0;
  }

  String _formatTime(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ══════════════════════════════════════════════════════════════════
  //  UI WIDGETS BUILDERS
  // ══════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Latar belakang luar angkasa
          _buildSpaceBackground(),

          // Konten Layar berdasarkan state game
          SafeArea(
            child: _buildScreenContent(),
          ),

          // Flash Layar Merah jika kena tabrak
          if (_flashRed)
            Positioned.fill(
              child: Container(
                color: Colors.red.withOpacity(0.35),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSpaceBackground() {
    if (_isEvenLevel) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A120D), // Sangat Gelap Hijau Hutan
              Color(0xFF14241C), // Lumut Hijau Gelap
              Color(0xFF222415), // Cokelat/Kuning Lumut Kuil
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _StaticFirefliesPainter(),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF070B19), // Sangat Gelap
            Color(0xFF0F172A), // Biru Slate
            Color(0xFF1E1B4B), // Ungu Nebula
          ],
        ),
      ),
      child: Stack(
        children: [
          // Bintang-bintang bercahaya diam
          Positioned.fill(
            child: CustomPaint(
              painter: _StaticStarsPainter(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreenContent() {
    switch (_gameState) {
      case 'menu':
        return _buildMenuScreen();
      case 'level_select':
        return _buildLevelSelectScreen();
      case 'playing':
        return _buildGameplayScreen();
      case 'level_complete':
        return _buildLevelCompleteScreen();
      case 'game_over':
        return _buildGameOverScreen();
      case 'victory':
        return _buildVictoryScreen();
      default:
        return _buildMenuScreen();
    }
  }

  // 1. MENU UTAMA SCREEN
  Widget _buildMenuScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Roket / UFO mengambang
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, (1 - _pulseAnimation.value) * 30),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent.withOpacity(0.2),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.rocket_launch_rounded,
                      color: Colors.cyanAccent,
                      size: 90,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            // Judul Game
            const Text(
              'SPACE MAZE',
              style: TextStyle(
                color: Colors.cyanAccent,
                fontSize: 38,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
                shadows: [
                  Shadow(color: Colors.cyan, blurRadius: 15),
                ],
              ),
            ),
            const Text(
              'ADVENTURE',
              style: TextStyle(
                color: Colors.purpleAccent,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 6,
                shadows: [
                  Shadow(color: Colors.purple, blurRadius: 10),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Pandu roketmu melewati labirin kosmik, hindari alien, kumpulkan kristal daya!',
              style: TextStyle(color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            // Tombol Mulai
            _buildNeonButton(
              text: "MULAI PETUALANGAN",
              color: Colors.greenAccent,
              onPressed: () {
                AudioService().playClick();
                setState(() {
                  _gameState = 'level_select';
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Tombol Keluar
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'KEMBALI KE HUB',
                style: TextStyle(color: Colors.white38, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2. LEVEL SELECTOR SCREEN (PETA CELESTIAL)
  Widget _buildLevelSelectScreen() {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: () {
                  AudioService().playClick();
                  setState(() {
                    _gameState = 'menu';
                  });
                },
              ),
              const Expanded(
                child: Text(
                  'PETA LEVEL KOSMIK',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48), // spacer untuk keseimbangan
            ],
          ),
        ),
        
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              const h = 760.0; // Tinggi tetap peta orbit
              
              // Titik koordinat planet level (x, y)
              final List<Offset> points = [
                Offset(w * 0.25, h * 0.90), // Level 1 (bawah kiri)
                Offset(w * 0.70, h * 0.81), // Level 2 (kanan)
                Offset(w * 0.78, h * 0.64), // Level 3 (kanan atas)
                Offset(w * 0.38, h * 0.53), // Level 4 (tengah)
                Offset(w * 0.22, h * 0.40), // Level 5 (kiri)
                Offset(w * 0.58, h * 0.28), // Level 6 (tengah kanan)
                Offset(w * 0.76, h * 0.16), // Level 7 (kanan atas)
                Offset(w * 0.46, h * 0.05), // Level 8 (puncak)
              ];

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: SizedBox(
                  width: w,
                  height: h,
                  child: Stack(
                    children: [
                      // Jalur garis neon menghubungkan planet
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _MapConnectionPainter(points),
                        ),
                      ),

                      // Planet-planet
                      for (int i = 0; i < _totalLevels; i++) ...[
                        Positioned(
                          left: points[i].dx - 45,
                          top: points[i].dy - 45,
                          child: SizedBox(
                            width: 90,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildPlanetCircle(i + 1),
                                const SizedBox(height: 3),
                                _buildPlanetStars(i + 1),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlanetCircle(int levelNum) {
    bool isLocked = levelNum > _highestUnlocked;
    
    // Warna gradien unik per level planet
    List<Color> planetColors;
    if (isLocked) {
      planetColors = [Colors.grey.shade700, Colors.grey.shade900];
    } else {
      switch (levelNum) {
        case 1: planetColors = [Colors.cyanAccent, Colors.blueAccent]; break;
        case 2: planetColors = [Colors.greenAccent, Colors.teal]; break;
        case 3: planetColors = [Colors.amberAccent, Colors.orange]; break;
        case 4: planetColors = [Colors.pinkAccent, Colors.deepPurple]; break;
        case 5: planetColors = [Colors.redAccent, Colors.deepOrangeAccent]; break;
        case 6: planetColors = [Colors.blue, Colors.indigoAccent]; break;
        case 7: planetColors = [Colors.purpleAccent, Colors.deepPurpleAccent]; break;
        case 8: planetColors = [Colors.amber, Colors.redAccent]; break;
        default: planetColors = [Colors.cyan, Colors.blue];
      }
    }

    return GestureDetector(
      onTap: () {
        if (isLocked) {
          AudioService().playWrong();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Level ini masih terkunci! Selesaikan level sebelumnya.'),
              duration: Duration(seconds: 1),
            ),
          );
          return;
        }
        AudioService().playClick();
        setState(() {
          _level = levelNum;
          _gameState = 'playing';
          _startLevel();
        });
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: planetColors,
            center: const Alignment(-0.3, -0.3),
            radius: 0.8,
          ),
          boxShadow: isLocked
              ? []
              : [
                  BoxShadow(
                    color: planetColors[0].withOpacity(0.5),
                    blurRadius: 15,
                    spreadRadius: 2,
                  )
                ],
          border: Border.all(
            color: isLocked ? Colors.white24 : Colors.white70,
            width: 1.5,
          ),
        ),
        child: Center(
          child: isLocked
              ? const Icon(Icons.lock_rounded, color: Colors.white38, size: 20)
              : Text(
                  '$levelNum',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    shadows: [
                      Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(1, 1)),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildPlanetStars(int levelNum) {
    int stars = _starRatings[levelNum - 1];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return Icon(
          index < stars ? Icons.star_rounded : Icons.star_border_rounded,
          color: index < stars ? Colors.amber : Colors.white12,
          size: 14,
        );
      }),
    );
  }

  // 3. GAMEPLAY SCREEN (HUD + BOARD + CONTROLS)
  Widget _buildGameplayScreen() {
    return Column(
      children: [
        // HUD
        _buildHUD(),
        
        // Pesan Transisi HUD Terapung
        _buildHudNotificationBanner(),

        const Spacer(),

        // Board Labirin
        GestureDetector(
          onPanEnd: _handleSwipe,
          child: _buildMazeGrid(),
        ),

        const Spacer(),

        // Kontrol D-Pad / Petunjuk
        _buildControlPanel(),

        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildHUD() {
    final config = _levelConfigs[_level - 1];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isEvenLevel
              ? Colors.amberAccent.withOpacity(0.25)
              : Colors.cyanAccent.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: _isEvenLevel
                ? Colors.amberAccent.withOpacity(0.06)
                : Colors.cyanAccent.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Nyawa / Lives
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              return Icon(
                Icons.favorite_rounded,
                color: i < _lives ? Colors.redAccent : Colors.white10,
                size: 20,
              );
            }),
          ),
          
          // Kristal Terkumpul / Koin Kuno
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isEvenLevel ? Icons.monetization_on_rounded : Icons.diamond_rounded,
                color: _isEvenLevel ? Colors.amber : Colors.amberAccent,
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                '$_coinsCollected/${config.coinCount}',
                style: TextStyle(
                  color: _isEvenLevel ? Colors.amber : Colors.amberAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),

          // Senter / Fog indicator (jika ada fog)
          if (config.hasFog && config.hasBatteryDecay)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isEvenLevel ? Icons.local_fire_department_rounded : Icons.flash_on_rounded,
                  color: _isEvenLevel ? Colors.orangeAccent : Colors.yellowAccent,
                  size: 18,
                ),
                const SizedBox(width: 2),
                SizedBox(
                  width: 50,
                  height: 6,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: (_fogRadius / _levelConfigs[_level - 1].initialFogRadius).clamp(0.0, 1.0),
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _fogRadius < (_levelConfigs[_level - 1].initialFogRadius * 0.5) 
                            ? Colors.redAccent 
                            : (_isEvenLevel ? Colors.orangeAccent : Colors.yellowAccent),
                      ),
                    ),
                  ),
                ),
              ],
            ),

          // Kunci
          if (config.hasKey)
            Icon(
              _isEvenLevel ? Icons.key_rounded : Icons.vpn_key_rounded,
              color: _hasKey 
                  ? (_isEvenLevel ? Colors.amberAccent : Colors.greenAccent) 
                  : Colors.white24,
              size: 20,
            ),

          // Waktu
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer_outlined,
                color: _isEvenLevel ? Colors.greenAccent : Colors.cyanAccent,
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                _formatTime(_elapsedSeconds),
                style: TextStyle(
                  color: _isEvenLevel ? Colors.greenAccent : Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHudNotificationBanner() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: _hudMessage.isNotEmpty ? 36 : 0,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _hudMessage.contains("💥") 
            ? Colors.redAccent.withOpacity(0.2) 
            : (_hudMessage.contains("🔑") ? Colors.greenAccent.withOpacity(0.2) : Colors.cyanAccent.withOpacity(0.15)),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _hudMessage.contains("💥") 
              ? Colors.redAccent.withOpacity(0.4) 
              : (_hudMessage.contains("🔑") ? Colors.greenAccent.withOpacity(0.4) : Colors.cyanAccent.withOpacity(0.3)),
          width: 1,
        ),
      ),
      child: _hudMessage.isNotEmpty
          ? Text(
              _hudMessage,
              style: TextStyle(
                color: _hudMessage.contains("💥") 
                    ? Colors.red : (_hudMessage.contains("🔑") ? Colors.greenAccent : Colors.white),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            )
          : const SizedBox(),
    );
  }

  Widget _buildMazeGrid() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final maxGridHeight = screenHeight * 0.53;
    double size = math.min(screenWidth * 0.94, maxGridHeight);

    final config = _levelConfigs[_level - 1];

    final Color gridBorderColor = _isEvenLevel
        ? (config.hasFog
            ? Colors.orangeAccent.withOpacity(0.35)
            : Colors.greenAccent.withOpacity(0.35))
        : (config.hasFog
            ? Colors.deepPurpleAccent.withOpacity(0.3)
            : Colors.cyanAccent.withOpacity(0.3));

    final Color gridShadowColor = _isEvenLevel
        ? (config.hasFog
            ? Colors.orangeAccent.withOpacity(0.12)
            : Colors.greenAccent.withOpacity(0.1))
        : (config.hasFog
            ? Colors.deepPurpleAccent.withOpacity(0.1)
            : Colors.cyanAccent.withOpacity(0.08));

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _isEvenLevel ? const Color(0xFF0A120D).withOpacity(0.7) : const Color(0xFF0F172A).withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: gridBorderColor,
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: gridShadowColor,
            blurRadius: 25,
            spreadRadius: 3,
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _gridSize,
          ),
          itemCount: _gridSize * _gridSize,
          itemBuilder: (context, index) {
            int x = index % _gridSize;
            int y = index ~/ _gridSize;
            
            int cellVal = _grid[y][x];
            bool isPlayer = (x == _playerX && y == _playerY);
            bool isVisible = _isCellVisible(x, y);
            double fogOpacity = _getCellFogOpacity(x, y);

            return _buildCell(x, y, cellVal, isPlayer, isVisible, fogOpacity);
          },
        ),
      ),
    );
  }

  Widget _buildCell(int x, int y, int cellVal, bool isPlayer, bool isVisible, double fogOpacity) {
    // Ukuran huruf & ikon dinamis berdasarkan grid size
    double itemSize = _gridSize <= 7
        ? 34
        : _gridSize <= 9
            ? 28
            : _gridSize <= 11
                ? 22
                : 17;

    Widget cellContent = const SizedBox();

    if (isVisible) {
      if (isPlayer) {
        // Player spaceship vs Explorer
        cellContent = Transform.rotate(
          angle: _playerAngle,
          child: Icon(
            _isEvenLevel ? Icons.hiking_rounded : Icons.navigation_rounded,
            color: _isEvenLevel ? Colors.amberAccent : Colors.cyanAccent,
            size: itemSize * 1.15,
            shadows: [
              Shadow(
                color: _isEvenLevel ? Colors.amber : Colors.cyan, 
                blurRadius: 10,
              ),
            ],
          ),
        );
      } else {
        // Cek musuh patroli di koordinat ini
        _SpaceHazard? hazard = _getHazardAt(x, y);
        if (hazard != null) {
          cellContent = AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Icon(
                  _isEvenLevel ? Icons.bug_report_rounded : Icons.pest_control_rounded,
                  color: Colors.redAccent,
                  size: itemSize * 1.1,
                  shadows: const [
                    Shadow(color: Colors.red, blurRadius: 10),
                  ],
                ),
              );
            },
          );
        } else {
          // Renders asset statis
          switch (cellVal) {
            case 3: // Exit Wormhole vs Temple Portal
              cellContent = AnimatedBuilder(
                animation: _rotationController,
                builder: (context, child) {
                  return _isEvenLevel
                      ? Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Icon(
                            Icons.fort_rounded,
                            color: Colors.amberAccent,
                            size: itemSize * 1.25,
                            shadows: const [
                              Shadow(color: Colors.amber, blurRadius: 8),
                            ],
                          ),
                        )
                      : Transform.rotate(
                          angle: _rotationController.value * 2 * math.pi,
                          child: Icon(
                            Icons.filter_tilt_shift_rounded,
                            color: Colors.pinkAccent,
                            size: itemSize * 1.25,
                            shadows: const [
                              Shadow(color: Colors.purple, blurRadius: 8),
                            ],
                          ),
                        );
                },
              );
              break;
            case 4: // Kristal Energi vs Koin Emas
              cellContent = AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Icon(
                      _isEvenLevel ? Icons.monetization_on_rounded : Icons.diamond_rounded,
                      color: _isEvenLevel ? Colors.amber : Colors.amberAccent,
                      size: itemSize * 1.05,
                      shadows: [
                        Shadow(
                          color: _isEvenLevel ? Colors.orange : Colors.amber, 
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  );
                },
              );
              break;
            case 5: // Kunci
              cellContent = AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Icon(
                      _isEvenLevel ? Icons.key_rounded : Icons.vpn_key_rounded,
                      color: _isEvenLevel ? Colors.amberAccent : Colors.greenAccent,
                      size: itemSize * 1.0,
                      shadows: [
                        Shadow(
                          color: _isEvenLevel ? Colors.orange : Colors.green, 
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  );
                },
              );
              break;
            case 6: // Laser Gate (Terkunci) vs Pagar Kayu
              cellContent = Icon(
                _isEvenLevel ? Icons.fence_rounded : Icons.grid_3x3_rounded,
                color: _isEvenLevel ? Colors.orangeAccent : Colors.redAccent,
                size: itemSize * 0.95,
                shadows: [
                  Shadow(
                    color: _isEvenLevel ? Colors.orange : Colors.red, 
                    blurRadius: 6,
                  ),
                ],
              );
              break;
            case 7: // Baterai vs Obor
              cellContent = AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Icon(
                      _isEvenLevel ? Icons.fireplace_rounded : Icons.battery_charging_full_rounded,
                      color: _isEvenLevel ? Colors.orangeAccent : Colors.yellowAccent,
                      size: itemSize * 1.0,
                      shadows: [
                        Shadow(
                          color: _isEvenLevel ? Colors.deepOrange : Colors.yellow, 
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  );
                },
              );
              break;
            default:
              cellContent = const SizedBox();
          }
        }
      }
    }

    // Styling latar belakang cell
    BoxDecoration cellDecoration;
    if (cellVal == 1 && isVisible) {
      // Wall (Laser Grid vs Mossy Ancient Wall)
      if (_isEvenLevel) {
        cellDecoration = BoxDecoration(
          color: const Color(0xFF14241C),
          border: Border.all(color: Colors.green.withOpacity(0.55), width: 1.0),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.2),
              blurRadius: 4,
              spreadRadius: 0.5,
            )
          ],
        );
      } else {
        cellDecoration = BoxDecoration(
          color: const Color(0xFF0F172A),
          border: Border.all(color: Colors.blueAccent.withOpacity(0.55), width: 1.0),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.15),
              blurRadius: 4,
              spreadRadius: 0.5,
            )
          ],
        );
      }
    } else {
      // Path
      if (_isEvenLevel) {
        cellDecoration = BoxDecoration(
          color: const Color(0xFF2E2D22).withOpacity(0.4),
          borderRadius: BorderRadius.circular(2),
        );
      } else {
        cellDecoration = BoxDecoration(
          color: const Color(0xFF1E293B).withOpacity(0.4),
          borderRadius: BorderRadius.circular(2),
        );
      }
    }

    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            margin: const EdgeInsets.all(0.8),
            decoration: cellDecoration,
            child: cellVal == 0 && isVisible && !isPlayer && _getHazardAt(x, y) == null
                ? Center(
                    child: Container(
                      width: 1.5,
                      height: 1.5,
                      decoration: BoxDecoration(
                        color: _isEvenLevel 
                            ? Colors.greenAccent.withOpacity(0.25)
                            : Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                : Center(child: cellContent),
          ),
        ),
        
        // Layer Hitam untuk FOG OF WAR
        if (fogOpacity > 0.0)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                margin: const EdgeInsets.all(0.8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(fogOpacity),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
      ],
    );
  }

  _SpaceHazard? _getHazardAt(int x, int y) {
    for (var hazard in _hazards) {
      if (hazard.x == x && hazard.y == y) {
        return hazard;
      }
    }
    return null;
  }

  // 4. KONTROL DAN PETUNJUK
  Widget _buildControlPanel() {
    final config = _levelConfigs[_level - 1];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Petunjuk kiri
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "KONTROL:",
                  style: TextStyle(color: Colors.white30, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  "• Usap layar (Swipe) untuk meluncur menabrak tembok.",
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
                const SizedBox(height: 2),
                const Text(
                  "• Gunakan D-Pad kanan untuk gerak presisi.",
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
                if (config.hasFog) ...[
                  const SizedBox(height: 6),
                  Text(
                    _isEvenLevel ? "⚠️ KABUT JUNGLE MISTERIUS!" : "⚠️ KABUT LUAR ANGKASA!",
                    style: TextStyle(
                      color: _isEvenLevel ? Colors.orangeAccent : Colors.purpleAccent, 
                      fontSize: 11, 
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _isEvenLevel
                        ? "Ambil obor api 🔥 sebelum lentera padam."
                        : "Ambil baterai 🔋 sebelum senter padam.",
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ]
              ],
            ),
          ),

          const SizedBox(width: 16),

          // D-Pad Bulat Kanan
          _buildVirtualDPad(),
        ],
      ),
    );
  }

  Widget _buildVirtualDPad() {
    return Container(
      width: 125,
      height: 125,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blueGrey.withOpacity(0.08),
        border: Border.all(
          color: _isEvenLevel
              ? Colors.greenAccent.withOpacity(0.25)
              : Colors.blueAccent.withOpacity(0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _isEvenLevel
                ? Colors.greenAccent.withOpacity(0.03)
                : Colors.blueAccent.withOpacity(0.03),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Cap Tengah
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0F172A),
              border: Border.all(
                color: _isEvenLevel
                    ? Colors.greenAccent.withOpacity(0.4)
                    : Colors.blueAccent.withOpacity(0.4),
                width: 1,
              ),
            ),
          ),
          
          // Tombol UP
          Positioned(
            top: 2,
            child: _buildDPadButton(
              icon: Icons.keyboard_arrow_up_rounded,
              onPressed: () => _movePlayerOneStep(0, -1),
            ),
          ),

          // Tombol DOWN
          Positioned(
            bottom: 2,
            child: _buildDPadButton(
              icon: Icons.keyboard_arrow_down_rounded,
              onPressed: () => _movePlayerOneStep(0, 1),
            ),
          ),

          // Tombol LEFT
          Positioned(
            left: 2,
            child: _buildDPadButton(
              icon: Icons.keyboard_arrow_left_rounded,
              onPressed: () => _movePlayerOneStep(-1, 0),
            ),
          ),

          // Tombol RIGHT
          Positioned(
            right: 2,
            child: _buildDPadButton(
              icon: Icons.keyboard_arrow_right_rounded,
              onPressed: () => _movePlayerOneStep(1, 0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDPadButton({required IconData icon, required VoidCallback onPressed}) {
    return GestureDetector(
      onTapDown: (_) {
        onPressed();
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF1E293B).withOpacity(0.9),
          border: Border.all(
            color: _isEvenLevel
                ? Colors.amberAccent.withOpacity(0.2)
                : Colors.cyanAccent.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Icon(
          icon, 
          color: _isEvenLevel ? Colors.amberAccent : Colors.cyanAccent, 
          size: 22,
        ),
      ),
    );
  }

  // 4. LEVEL COMPLETE OVERLAY SCREEN
  Widget _buildLevelCompleteScreen() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.cyanAccent.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withOpacity(0.1),
              blurRadius: 25,
              spreadRadius: 3,
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'LEVEL SELESAI! 🎉',
              style: TextStyle(color: Colors.cyanAccent, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1.2),
            ),
            const SizedBox(height: 16),
            
            // Bintang Rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    i < _levelStars ? Icons.star_rounded : Icons.star_border_rounded,
                    color: Colors.amberAccent,
                    size: 44,
                    shadows: i < _levelStars
                        ? [const Shadow(color: Colors.amber, blurRadius: 10)]
                        : [],
                  ),
                );
              }),
            ),
            
            const SizedBox(height: 20),

            _buildStatDetailRow('⏱️ Waktu:', _formatTime(_elapsedSeconds)),
            _buildStatDetailRow('👣 Jumlah Langkah:', '$_moves'),
            _buildStatDetailRow('💎 Kristal:', '$_coinsCollected'),
            _buildStatDetailRow('💥 Kerusakan Pesawat:', '${3 - _lives} HP'),
            _buildStatDetailRow('🏆 Skor Level:', '+$_levelScore'),

            const SizedBox(height: 24),

            Row(
              children: [
                // Tombol Peta
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      AudioService().playClick();
                      setState(() {
                        _gameState = 'level_select';
                      });
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white10,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('PETA LEVEL', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Tombol Main/Selanjutnya
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      AudioService().playClick();
                      if (_level < _totalLevels) {
                        setState(() {
                          _level++;
                          _gameState = 'playing';
                          _startLevel();
                        });
                      } else {
                        // Level 8 Berhasil, selesai permainan!
                        _finishGame();
                        setState(() {
                          _gameState = 'victory';
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 4,
                    ),
                    child: Text(
                      _level < _totalLevels ? 'LANJUT' : 'KEMENANGAN',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatDetailRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  // 5. GAME OVER SCREEN
  Widget _buildGameOverScreen() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.redAccent.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.redAccent.withOpacity(0.15),
              blurRadius: 30,
              spreadRadius: 2,
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.gpp_bad_rounded, color: Colors.redAccent, size: 72),
            const SizedBox(height: 16),
            const Text(
              'MISI GAGAL! 🚀',
              style: TextStyle(color: Colors.redAccent, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1.2),
            ),
            const SizedBox(height: 8),
            const Text(
              'Perisai pesawat hancur karena serangan alien atau menabrak rintangan luar angkasa!',
              style: TextStyle(color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      AudioService().playClick();
                      setState(() {
                        _gameState = 'level_select';
                      });
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white10,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('MENYERAH', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      AudioService().playClick();
                      setState(() {
                        _gameState = 'playing';
                        _startLevel();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('COBA LAGI', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // 6. FINAL VICTORY SCREEN
  Widget _buildVictoryScreen() {
    double averageStars = _totalStars / _totalLevels;
    int performaPercentage = (averageStars / 3.0 * 100).round();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Piala emas pulsing
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: Colors.amber,
                      size: 100,
                      shadows: [
                        Shadow(color: Colors.amberAccent, blurRadius: 20),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'KOSMOS DITAKLUKKAN!',
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(color: Colors.cyan, blurRadius: 10)],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Selamat! Kamu adalah Pilot Penjelajah Labirin Kosmik Terbaik!',
                style: TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Rangkuman Statistik Kartu
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withOpacity(0.85),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'RANGKUMAN PENJELAJAHAN',
                      style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1.1),
                    ),
                    const SizedBox(height: 16),
                    _buildFinalStatRow('🏆 Total Skor:', '$_totalScore'),
                    _buildFinalStatRow('⭐ Total Bintang:', '$_totalStars / ${_totalLevels * 3}'),
                    _buildFinalStatRow('💎 Total Kristal:', '$_totalCoinsCollected'),
                    _buildFinalStatRow('⏱️ Total Waktu:', _formatTime(_totalElapsedSeconds)),
                    _buildFinalStatRow('📊 Performa Akurasi:', '$performaPercentage%'),
                    const SizedBox(height: 16),
                    
                    // Rata-rata bintang
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) {
                        return Icon(
                          i < averageStars.round() ? Icons.star_rounded : Icons.star_border_rounded,
                          color: Colors.amberAccent,
                          size: 32,
                        );
                      }),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // Tombol Hub
              _buildNeonButton(
                text: "KEMBALI KE HUB",
                color: Colors.amber,
                onPressed: () {
                  AudioService().playClick();
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),

              // Main Lagi
              TextButton(
                onPressed: () {
                  AudioService().playClick();
                  setState(() {
                    _level = 1;
                    _starRatings = List.filled(_totalLevels, 0);
                    _highestUnlocked = 1;
                    _totalScore = 0;
                    _totalStars = 0;
                    _totalCoinsCollected = 0;
                    _totalElapsedSeconds = 0;
                    _totalMovesCount = 0;
                    _totalErrorsCount = 0;
                    _gameState = 'level_select';
                  });
                },
                child: const Text(
                  'ULANGI PETUALANGAN 🔄',
                  style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinalStatRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildNeonButton({required String text, required Color color, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 6,
          shadowColor: color.withOpacity(0.5),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: Colors.black87,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

// ── WIDGET PAINTER TAMBAHAN ───────────────────────────────────────

/// Menggambar bintang statis di latar belakang langit
class _StaticStarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final random = math.Random(1337); // Seed tetap agar tidak berubah-ubah

    for (int i = 0; i < 90; i++) {
      double x = random.nextDouble() * size.width;
      double y = random.nextDouble() * size.height;
      double r = random.nextDouble() * 1.5 + 0.4;
      
      // Menggambar beberapa bintang berkilau lemah
      paint.color = Colors.white.withOpacity(random.nextDouble() * 0.4 + 0.1);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Menggambar garis neon bergelombang/titik-titik untuk rute planet
class _MapConnectionPainter extends CustomPainter {
  final List<Offset> points;
  _MapConnectionPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = Colors.greenAccent.withOpacity(0.3)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = Colors.greenAccent.withOpacity(0.08)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke;

    // Gambar jalur putus-putus
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      
      final dx = p2.dx - p1.dx;
      final dy = p2.dy - p1.dy;
      final len = math.sqrt(dx * dx + dy * dy);
      final ux = dx / len;
      final uy = dy / len;

      double cur = 0;
      double dashW = 7.0;
      double space = 5.0;

      while (cur < len) {
        double nextLen = math.min(cur + dashW, len);
        Offset start = Offset(p1.dx + ux * cur, p1.dy + uy * cur);
        Offset end = Offset(p1.dx + ux * nextLen, p1.dy + uy * nextLen);
        
        canvas.drawLine(start, end, glowPaint);
        canvas.drawLine(start, end, paint);
        
        cur += dashW + space;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MapConnectionPainter oldDelegate) => true;
}

/// Menggambar kunang-kunang statis untuk tema kuil/hutan kuno
class _StaticFirefliesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final random = math.Random(42); // Seed tetap agar tidak berkedip acak secara konstan

    for (int i = 0; i < 40; i++) {
      double x = random.nextDouble() * size.width;
      double y = random.nextDouble() * size.height;
      double r = random.nextDouble() * 3.0 + 1.0;
      
      // Kunang-kunang berwarna kuning/hijau neon pudar
      paint.color = Colors.amberAccent.withOpacity(random.nextDouble() * 0.5 + 0.15);
      canvas.drawCircle(Offset(x, y), r, paint);
      
      // Halo glow untuk kunang-kunang
      final glowPaint = Paint()
        ..color = Colors.yellowAccent.withOpacity(random.nextDouble() * 0.1 + 0.03)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(Offset(x, y), r * 2.5, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
