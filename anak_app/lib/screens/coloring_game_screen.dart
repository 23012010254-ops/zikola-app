import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../services/audio_service.dart';

// --- Game States ---
enum SpeedDrawState { lobby, prep, drawing, voting, results }
enum SpeedDrawMode { bot, player }

// --- Models ---
class DrawnLine {
  final List<Offset> points;
  final Color color;
  final double width;

  DrawnLine({required this.points, required this.color, this.width = 5.0});
}

class FloatingEmoji {
  final String emoji;
  final double x;
  double y;
  double opacity;

  FloatingEmoji({required this.emoji, required this.x, required this.y, this.opacity = 1.0});
}

// --- Predefined Prompts ---
final List<Map<String, String>> easyPrompts = [
  {'text': 'Rumah 🏠', 'emoji': '🏠'},
  {'text': 'Bintang ⭐', 'emoji': '⭐'},
  {'text': 'Awan ☁️', 'emoji': '☁️'},
  {'text': 'Kotak 🟥', 'emoji': '🟥'},
  {'text': 'Segitiga 🔺', 'emoji': '🔺'},
  {'text': 'Matahari ☀️', 'emoji': '☀️'},
];

final List<Map<String, String>> mediumPrompts = [
  {'text': 'Kucing 🐱', 'emoji': '🐱'},
  {'text': 'Es Krim 🍦', 'emoji': '🍦'},
  {'text': 'Mobil 🚗', 'emoji': '🚗'},
  {'text': 'Bunga 🌸', 'emoji': '🌸'},
  {'text': 'Ikan 🐟', 'emoji': '🐟'},
  {'text': 'Pohon 🌳', 'emoji': '🌳'},
];

final List<Map<String, String>> hardPrompts = [
  {'text': 'Roket 🚀', 'emoji': '🚀'},
  {'text': 'Naga 🐉', 'emoji': '🐉'},
  {'text': 'Kastil 🏰', 'emoji': '🏰'},
  {'text': 'Astronaut 🧑‍🚀', 'emoji': '🧑‍🚀'},
  {'text': 'T-Rex 🦖', 'emoji': '🦖'},
  {'text': 'Kapal Laut 🚢', 'emoji': '🚢'},
];

final List<Map<String, String>> drawPrompts = [...easyPrompts, ...mediumPrompts, ...hardPrompts];

final List<Color> crayonColors = [
  const Color(0xFFEF4444), // Red
  const Color(0xFFF43F5E), // Rose
  const Color(0xFFEC4899), // Pink
  const Color(0xFFD946EF), // Fuchsia
  const Color(0xFF8B5CF6), // Purple
  const Color(0xFF6366F1), // Indigo
  const Color(0xFF3B82F6), // Blue
  const Color(0xFF0EA5E9), // Sky Blue
  const Color(0xFF06B6D4), // Cyan
  const Color(0xFF14B8A6), // Teal
  const Color(0xFF10B981), // Emerald
  const Color(0xFF22C55E), // Green
  const Color(0xFF84CC16), // Lime
  const Color(0xFFFBBF24), // Yellow
  const Color(0xFFF59E0B), // Amber
  const Color(0xFFF97316), // Orange
  const Color(0xFF78350F), // Brown
  const Color(0xFF6B7280), // Grey
  const Color(0xFF1F2937), // Black
  const Color(0xFFFFFFFF), // White (Eraser)
];

// --- Serialization Helpers ---
List<Map<String, dynamic>> serializeLines(List<DrawnLine> lines) {
  return lines.map((line) {
    return {
      'points': line.points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
      'color': line.color.value,
      'width': line.width,
    };
  }).toList();
}

List<DrawnLine> deserializeLines(List<dynamic> jsonList) {
  return jsonList.map((item) {
    final pointsList = item['points'] as List<dynamic>;
    final points = pointsList.map((p) => Offset((p['x'] as num).toDouble(), (p['y'] as num).toDouble())).toList();
    return DrawnLine(
      points: points,
      color: Color(item['color'] as int),
      width: (item['width'] as num).toDouble(),
    );
  }).toList();
}

// --- Flood Fill BFS Helper ---
Map<Offset, Color> computeFilledGridPoints(List<DrawnLine> lines, double canvasWidth, double canvasHeight) {
  final Map<Offset, Color> filledPoints = {};
  if (canvasWidth <= 0 || canvasHeight <= 0) return filledPoints;

  const int gridW = 150;
  const int gridH = 150;

  // 1. Initialize boundary grid
  final List<List<bool>> boundaries = List.generate(gridW, (_) => List.filled(gridH, false));
  for (var line in lines) {
    // Skip fill actions and eraser lines
    if (line.width == -99.0 || line.color.value == 0xFFFFFFFF) continue;

    for (int i = 0; i < line.points.length - 1; i++) {
      final p1 = line.points[i];
      final p2 = line.points[i + 1];
      if (p1 == Offset.zero || p2 == Offset.zero) continue;

      final dist = (p2 - p1).distance;
      final steps = (dist / 1.5).ceil().clamp(1, 150);
      for (int s = 0; s <= steps; s++) {
        final t = s / steps;
        final p = Offset.lerp(p1, p2, t)!;
        final gx = ((p.dx / canvasWidth) * gridW).floor().clamp(0, gridW - 1);
        final gy = ((p.dy / canvasHeight) * gridH).floor().clamp(0, gridH - 1);
        boundaries[gx][gy] = true;
      }
    }
  }

  // 2. Run BFS for each fill action
  for (var line in lines) {
    if (line.width != -99.0 || line.points.isEmpty) continue;

    final startX = line.points[0].dx.toInt().clamp(0, gridW - 1);
    final startY = line.points[0].dy.toInt().clamp(0, gridH - 1);
    final fillColor = line.color;

    if (boundaries[startX][startY]) continue;

    final queue = <math.Point<int>>[math.Point(startX, startY)];
    final visited = <math.Point<int>>{math.Point(startX, startY)};

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      final curOffset = Offset(current.x.toDouble(), current.y.toDouble());
      
      filledPoints[curOffset] = fillColor;

      final neighbors = [
        math.Point(current.x + 1, current.y),
        math.Point(current.x - 1, current.y),
        math.Point(current.x, current.y + 1),
        math.Point(current.x, current.y - 1),
      ];

      for (var n in neighbors) {
        if (n.x >= 0 && n.x < gridW && n.y >= 0 && n.y < gridH) {
          if (!boundaries[n.x][n.y] && !visited.contains(n)) {
            final nOffset = Offset(n.x.toDouble(), n.y.toDouble());
            if (filledPoints[nOffset] != fillColor) {
              visited.add(n);
              queue.add(n);
            }
          }
        }
      }
    }
  }

  return filledPoints;
}

// --- Painter ---
class DrawingPainter extends CustomPainter {
  final List<DrawnLine> lines;
  final Map<Offset, Color> filledPoints;
  final Color backgroundColor;

  DrawingPainter({
    required this.lines,
    required this.filledPoints,
    this.backgroundColor = Colors.white,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Paint Background
    Paint bgPaint = Paint()..color = backgroundColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. Draw Fills
    if (filledPoints.isNotEmpty) {
      final double cellW = size.width / 150.0;
      final double cellH = size.height / 150.0;
      final double strokeWidth = cellW > cellH ? cellW : cellH;

      // Group points by color to call drawPoints as few times as possible
      final Map<Color, List<Offset>> pointsByColor = {};
      filledPoints.forEach((gridOffset, color) {
        final screenX = (gridOffset.dx / 150.0) * size.width + (cellW / 2.0);
        final screenY = (gridOffset.dy / 150.0) * size.height + (cellH / 2.0);
        pointsByColor.putIfAbsent(color, () => []).add(Offset(screenX, screenY));
      });

      pointsByColor.forEach((color, offsets) {
        final fillPaint = Paint()
          ..color = color
          ..strokeWidth = strokeWidth * 1.5 // Overlay slightly to prevent gaps
          ..strokeCap = StrokeCap.square;
        canvas.drawPoints(ui.PointMode.points, offsets, fillPaint);
      });
    }

    // 3. Draw Lines
    for (var line in lines) {
      if (line.width == -99.0) continue; // Skip fill lines in line-drawing pass

      Paint paint = Paint()
        ..color = line.color
        ..strokeWidth = line.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      for (int i = 0; i < line.points.length - 1; i++) {
        if (line.points[i] != Offset.zero && line.points[i + 1] != Offset.zero) {
          canvas.drawLine(line.points[i], line.points[i + 1], paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) => true;
}

// --- Main Widget ---
class ColoringGameScreen extends StatefulWidget {
  const ColoringGameScreen({super.key});

  @override
  State<ColoringGameScreen> createState() => _ColoringGameScreenState();
}

class _ColoringGameScreenState extends State<ColoringGameScreen> with TickerProviderStateMixin {
  SpeedDrawMode? _selectedMode;
  SpeedDrawState _gameState = SpeedDrawState.lobby;
  Map<String, String> _currentPrompt = drawPrompts[0];
  String _selectedDifficulty = 'medium'; // easy, medium, hard

  int _getDrawingDuration(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return 180; // 3 minutes
      case 'hard':
        return 480; // 8 minutes
      case 'medium':
      default:
        return 300; // 5 minutes
    }
  }

  Widget _buildDifficultyButton(String diffKey, String label, Color activeColor, {bool enabled = true, Function(String)? onSelect}) {
    final bool isSelected = _selectedDifficulty == diffKey;
    return Expanded(
      child: GestureDetector(
        onTap: enabled
            ? () {
                AudioService().playClick();
                if (onSelect != null) {
                  onSelect(diffKey);
                } else {
                  setState(() {
                    _selectedDifficulty = diffKey;
                  });
                }
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withOpacity(0.15) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? activeColor : Colors.transparent,
              width: 2,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? activeColor : Colors.grey.shade600,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _updateOnlineRoomDifficulty(String diff) async {
    if (!_isHost || _roomId == null) return;
    setState(() {
      _selectedDifficulty = diff;
    });
    try {
      await _firestore.collection('speed_draw_rooms').doc(_roomId).update({
        'difficulty': diff
      });
    } catch (e) {
      debugPrint('Error updating difficulty: $e');
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  
  // Timers
  Timer? _gameTimer;
  int _timeLeft = 0;
  
  // Drawing state
  List<DrawnLine> _userLines = [];
  DrawnLine? _currentLine;
  Color _selectedColor = crayonColors[0];
  double _brushWidth = 6.0;

  // Bucket/Fill state
  bool _isBucketMode = false;
  bool _drawingSubmitted = false;
  bool _isTransitioningToVoting = false;
  Map<Offset, Color> _userFilledPoints = {};
  double _lastCanvasWidth = 0.0;
  double _lastCanvasHeight = 0.0;

  void _updateUserFilledPoints(double width, double height) {
    if (width <= 0 || height <= 0) return;
    _lastCanvasWidth = width;
    _lastCanvasHeight = height;
    setState(() {
      _userFilledPoints = computeFilledGridPoints(_userLines, width, height);
    });
  }

  // Bot Mode simulation state
  final List<Map<String, dynamic>> _botOpponents = [
    {'name': 'DinoDraw 🦕', 'avatar': '🦖', 'color': Colors.orange.shade400, 'lines': <DrawnLine>[]},
    {'name': 'PrincessScribble 👑', 'avatar': '👸', 'color': Colors.pink.shade300, 'lines': <DrawnLine>[]},
    {'name': 'GamerDoodle 🎮', 'avatar': '👾', 'color': Colors.blue.shade400, 'lines': <DrawnLine>[]},
  ];

  // Online Multiplayer state
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot>? _roomSubscription;
  String? _roomId;
  bool _isHost = false;
  List<Map<String, dynamic>> _onlinePlayers = [];
  Map<String, dynamic> _roomData = {};
  
  // Voting state variables
  int _votingIndex = 0; // Index of player/bot being voted on
  int _selectedVoteStars = 0;
  Map<String, int> _myVotes = {}; // Name/UID -> stars
  List<int> _botVotesForPlayer = [0, 0, 0]; // Votes given by bots
  List<FloatingEmoji> _floatingEmojis = [];
  Timer? _emojiTimer;
  Timer? _emojiUpdateTimer;
  List<String> _voteLogs = [];

  // Standings / Result
  List<Map<String, dynamic>> _standings = [];

  // Room code input controller
  final TextEditingController _roomCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    AudioService().playGameBGM();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _emojiTimer?.cancel();
    _emojiUpdateTimer?.cancel();
    _roomSubscription?.cancel();
    _roomCodeController.dispose();
    AudioService().stopBGM();
    super.dispose();
  }

  // --- Online Multiplayer Actions ---

  Future<void> _createOnlineRoom() async {
    final appState = context.read<AppState>();
    if (appState.uid == null) {
      _showSnackBar('Silakan login terlebih dahulu untuk membuat room online.', Colors.orange);
      return;
    }
    final String uid = appState.uid!;
    final random = math.Random();
    final String generatedRoomId = (1000 + random.nextInt(9000)).toString(); // 4-digit code
    final playerProfile = {
      'uid': uid,
      'name': appState.childProfile.name.isNotEmpty ? appState.childProfile.name : 'Pemain',
      'avatar': appState.childProfile.avatar.isNotEmpty ? appState.childProfile.avatar : '🧒',
      'ready': true,
      'drawingSubmitted': false,
      'lines': <Map<String, dynamic>>[],
    };

    try {
      await _firestore.collection('speed_draw_rooms').doc(generatedRoomId).set({
        'roomId': generatedRoomId,
        'status': 'waiting',
        'hostUid': uid,
        'promptText': '',
        'promptEmoji': '',
        'difficulty': _selectedDifficulty,
        'currentVotingIndex': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'players': {uid: playerProfile},
        'votes': <String, dynamic>{}, // targetUid -> {voterUid: stars}
      });

      setState(() {
        _roomId = generatedRoomId;
        _isHost = true;
      });

      _subscribeToRoom(generatedRoomId);
    } catch (e) {
      debugPrint('Error creating room: $e');
      _showSnackBar('Gagal membuat room. Coba lagi.', Colors.red);
    }
  }

  Future<void> _joinOnlineRoom(String code) async {
    if (code.trim().length != 4) {
      _showSnackBar('Kode room harus 4 digit.', Colors.orange);
      return;
    }
    
    final appState = context.read<AppState>();
    if (appState.uid == null) {
      _showSnackBar('Silakan login terlebih dahulu untuk bergabung ke room online.', Colors.orange);
      return;
    }
    final String uid = appState.uid!;
    final playerProfile = {
      'uid': uid,
      'name': appState.childProfile.name.isNotEmpty ? appState.childProfile.name : 'Pemain',
      'avatar': appState.childProfile.avatar.isNotEmpty ? appState.childProfile.avatar : '🧒',
      'ready': true,
      'drawingSubmitted': false,
      'lines': <Map<String, dynamic>>[],
    };

    try {
      final roomDoc = await _firestore.collection('speed_draw_rooms').doc(code).get();
      if (!roomDoc.exists) {
        _showSnackBar('Room tidak ditemukan.', Colors.red);
        return;
      }

      final data = roomDoc.data()!;
      if (data['status'] != 'waiting') {
        _showSnackBar('Pertandingan di room ini sudah dimulai.', Colors.orange);
        return;
      }

      // Add player to room map
      await _firestore.collection('speed_draw_rooms').doc(code).update({
        'players.$uid': playerProfile
      });

      setState(() {
        _roomId = code;
        _isHost = false;
      });

      _subscribeToRoom(code);
    } catch (e) {
      debugPrint('Error joining room: $e');
      _showSnackBar('Gagal bergabung ke room.', Colors.red);
    }
  }

  Future<void> _leaveOnlineRoom() async {
    if (_roomId == null) return;
    final appState = context.read<AppState>();
    final String? uid = appState.uid;

    try {
      _roomSubscription?.cancel();
      
      if (_isHost) {
        // Delete room completely
        await _firestore.collection('speed_draw_rooms').doc(_roomId).delete();
      } else if (uid != null) {
        // Remove player record
        await _firestore.collection('speed_draw_rooms').doc(_roomId).update({
          'players.$uid': FieldValue.delete()
        });
      }
    } catch (e) {
      debugPrint('Error leaving room: $e');
    } finally {
      setState(() {
        _roomId = null;
        _isHost = false;
        _onlinePlayers = [];
        _selectedMode = null;
        _gameState = SpeedDrawState.lobby;
      });
    }
  }

  void _subscribeToRoom(String id) {
    _roomSubscription?.cancel();
    _roomSubscription = _firestore.collection('speed_draw_rooms').doc(id).snapshots().listen((snapshot) {
      try {
        if (!snapshot.exists) {
          // Room deleted by host
          if (!_isHost) {
            _showSnackBar('Room telah ditutup oleh host.', Colors.orange);
            _leaveOnlineRoom();
          }
          return;
        }

        final data = snapshot.data()!;
        _roomData = data;
        final playersMap = Map<String, dynamic>.from(data['players'] ?? {});
        final difficulty = data['difficulty'] ?? 'medium';
        
        // Update online players list
        List<Map<String, dynamic>> loadedPlayers = [];
        playersMap.forEach((uid, val) {
          loadedPlayers.add(Map<String, dynamic>.from(val));
        });

        setState(() {
          _onlinePlayers = loadedPlayers;
          _selectedDifficulty = difficulty;
        });

        // Handle real-time state transitions
        final String status = data['status'];
        
        if (status != 'drawing') {
          _isTransitioningToVoting = false;
        }

        // Host checks if all players submitted drawing reactively
        if (_isHost && status == 'drawing' && !_isTransitioningToVoting) {
          bool allSubmitted = true;
          playersMap.forEach((key, val) {
            if (val is Map) {
              if (val['drawingSubmitted'] != true) {
                allSubmitted = false;
              }
            } else {
              allSubmitted = false;
            }
          });

          if (allSubmitted) {
            _isTransitioningToVoting = true;
            final Map<String, Map<String, int>> finalVotes = {};
            final random = math.Random();
            
            // Pre-populate empty maps for all players (human and bot) to avoid dotted path write issues.
            playersMap.forEach((playerUid, _) {
              finalVotes[playerUid] = <String, int>{};
            });

            // Generate bot votes for human players.
            playersMap.forEach((playerUid, playerVal) {
              if (playerVal is Map) {
                final isBotPlayer = playerVal['isBot'] == true || playerUid.startsWith('bot_');
                if (!isBotPlayer) {
                  // This is a human player. Generate a vote from each bot in the room.
                  playersMap.forEach((botUid, botVal) {
                    if (botVal is Map) {
                      final isBotSource = botVal['isBot'] == true || botUid.startsWith('bot_');
                      if (isBotSource) {
                        // botUid votes for playerUid
                        finalVotes[playerUid]![botUid] = 3 + random.nextInt(3); // 3, 4, or 5 stars
                      }
                    }
                  });
                }
              }
            });

            // Host starts voting
            _firestore.collection('speed_draw_rooms').doc(_roomId).update({
              'status': 'voting',
              'currentVotingIndex': 0,
              'votes': finalVotes,
            }).catchError((err) {
              _isTransitioningToVoting = false;
              debugPrint('Error updating room to voting: $err');
            });
          }
        }

        if (status == 'drawing') {
          if (_gameState != SpeedDrawState.drawing && _gameState != SpeedDrawState.prep) {
            // Transition to prep screen locally first!
            _gameTimer?.cancel();
            setState(() {
              _currentPrompt = {
                'text': data['promptText'] ?? '',
                'emoji': data['promptEmoji'] ?? '',
              };
              _gameState = SpeedDrawState.prep;
              _timeLeft = 3;
            });
            _runOnlineLocalPrepTimer();
          }
        } else if (status == 'voting') {
          if (_gameState != SpeedDrawState.voting) {
            // Transition to voting
            _gameTimer?.cancel();
            _startOnlineVotingPhase();
          } else {
            // Listening to index changes during voting
            final int index = data['currentVotingIndex'] ?? 0;
            if (index != _votingIndex) {
              _moveToNextOnlineVotingItem(index);
            }
          }
        } else if (status == 'results' && _gameState != SpeedDrawState.results) {
          // Transition to results screen
          _showOnlineResults();
        }
      } catch (e, stack) {
        debugPrint('Stream callback error: $e\n$stack');
      }
    }, onError: (e) {
      debugPrint('Room listener error: $e');
    });
  }

  // --- Real-time Timers & Sycing Loops ---

  void _runOnlineLocalPrepTimer() {
    AudioService().playClick();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 1) {
        setState(() {
          _timeLeft--;
        });
        AudioService().playClick();
      } else {
        timer.cancel();
        setState(() {
          _gameState = SpeedDrawState.drawing;
          _timeLeft = _getDrawingDuration(_selectedDifficulty);
          _userLines = [];
          _drawingSubmitted = false;
        });
        _runOnlineDrawingTimer();
      }
    });
  }

  void _runOnlineDrawingTimer() {
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 1) {
        setState(() {
          _timeLeft--;
        });
        if (_timeLeft <= 5) {
          AudioService().playClick();
        }
      } else {
        timer.cancel();
        _submitOnlineDrawing();
      }
    });
  }

  Future<void> _startOnlineMatch() async {
    if (!_isHost) return;
    
    // Choose prompt based on selected difficulty
    final List<Map<String, String>> promptList;
    if (_selectedDifficulty == 'easy') {
      promptList = easyPrompts;
    } else if (_selectedDifficulty == 'hard') {
      promptList = hardPrompts;
    } else {
      promptList = mediumPrompts;
    }
    final random = math.Random();
    final prompt = promptList[random.nextInt(promptList.length)];

    final int botCountNeeded = 4 - _onlinePlayers.length;
    final Map<String, dynamic> playerUpdates = {};

    if (botCountNeeded > 0) {
      final List<Map<String, String>> botNamesAvatars = [
        {'name': 'DinoDraw 🦕', 'avatar': '🦖', 'color': '0xFFF97316'},
        {'name': 'PrincessScribble 👑', 'avatar': '👸', 'color': '0xFFEC4899'},
        {'name': 'GamerDoodle 🎮', 'avatar': '👾', 'color': '0xFF3B82F6'},
      ];

      for (int i = 0; i < botCountNeeded; i++) {
        final botId = 'bot_$i';
        final botInfo = botNamesAvatars[i % botNamesAvatars.length];
        
        // Pre-generate bot drawing for this prompt
        final botLines = _getOpponentDrawing(prompt['text']!, botInfo['name']!, Color(int.parse(botInfo['color']!)));
        final serializedBotLines = serializeLines(botLines);

        playerUpdates['players.$botId'] = {
          'uid': botId,
          'name': botInfo['name'],
          'avatar': botInfo['avatar'],
          'ready': true,
          'drawingSubmitted': true,
          'isBot': true,
          'lines': serializedBotLines,
        };
      }
    }

    // Sync room to start
    await _firestore.collection('speed_draw_rooms').doc(_roomId).update({
      'status': 'drawing',
      'promptText': prompt['text'],
      'promptEmoji': prompt['emoji'],
      ...playerUpdates,
    });
  }

  Future<void> _submitOnlineDrawing() async {
    if (_drawingSubmitted) return;
    _gameTimer?.cancel();
    setState(() {
      _drawingSubmitted = true;
    });
    final appState = context.read<AppState>();
    final String? uid = appState.uid;
    if (uid == null) return;
    final serialized = serializeLines(_userLines);

    try {
      // Upload player drawing to room
      await _firestore.collection('speed_draw_rooms').doc(_roomId).update({
        'players.$uid.drawingSubmitted': true,
        'players.$uid.lines': serialized,
      });
    } catch (e) {
      debugPrint('Error submitting drawing: $e');
      setState(() {
        _drawingSubmitted = false;
      });
      _showSnackBar('Gagal mengunggah gambar.', Colors.red);
    }
  }

  void _startOnlineVotingPhase() {
    setState(() {
      _gameState = SpeedDrawState.voting;
      _votingIndex = 0;
      _timeLeft = 8;
      _selectedVoteStars = 0;
    });

    _runOnlineVotingTimer();
  }

  void _runOnlineVotingTimer() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 1) {
        setState(() {
          _timeLeft--;
        });
      } else {
        timer.cancel();
        if (_isHost) {
          // Host manages moving to the next item
          _hostAdvanceOnlineVotingIndex();
        }
      }
    });
  }

  Future<void> _hostAdvanceOnlineVotingIndex() async {
    int nextIndex = _votingIndex + 1;
    if (nextIndex < _onlinePlayers.length) {
      await _firestore.collection('speed_draw_rooms').doc(_roomId).update({
        'currentVotingIndex': nextIndex
      });
    } else {
      // Voting finished -> Results state
      await _firestore.collection('speed_draw_rooms').doc(_roomId).update({
        'status': 'results'
      });
    }
  }

  void _moveToNextOnlineVotingItem(int newIndex) {
    _gameTimer?.cancel();
    setState(() {
      _votingIndex = newIndex;
      _timeLeft = 8;
      _selectedVoteStars = 0;
      _floatingEmojis = [];
      _voteLogs = []; // Reset logs
    });
    
    // Play SFX on transition
    AudioService().playClick();

    // Populate bot votes log if this item has bot votes
    final targetUid = _onlinePlayers[_votingIndex]['uid'];
    final targetVotes = Map<String, dynamic>.from(_roomData['votes']?[targetUid] ?? {});
    targetVotes.forEach((voterUid, stars) {
      if (voterUid.startsWith('bot_')) {
        final botName = _onlinePlayers.firstWhere((p) => p['uid'] == voterUid, orElse: () => {'name': 'Bot'})['name'] ?? 'Bot';
        _voteLogs.add('$botName: ⭐ $stars Bintang!');
      }
    });

    // If it's my drawing's turn to be voted on, simulate emoji shower
    final appState = context.read<AppState>();
    if (_onlinePlayers[_votingIndex]['uid'] == appState.uid) {
      _startLocalPlayerReactionSimulation();
    }

    _runOnlineVotingTimer();
  }

  void _startLocalPlayerReactionSimulation() {
    final random = math.Random();
    List<String> reactionEmojis = ['👍', '❤️', '🔥', '🎉', '😮', '😍', '👏'];
    
    _emojiTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (_gameState == SpeedDrawState.voting && _timeLeft > 0) {
        setState(() {
          _floatingEmojis.add(FloatingEmoji(
            emoji: reactionEmojis[random.nextInt(reactionEmojis.length)],
            x: 50.0 + random.nextDouble() * 250.0,
            y: 450.0,
          ));
        });
      } else {
        timer.cancel();
      }
    });

    _emojiUpdateTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_gameState == SpeedDrawState.voting) {
        setState(() {
          for (var fe in _floatingEmojis) {
            fe.y -= 8.0;
            fe.opacity = (fe.opacity - 0.05).clamp(0.0, 1.0);
          }
          _floatingEmojis.removeWhere((fe) => fe.y < 100.0 || fe.opacity <= 0.0);
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _submitOnlineVote(String targetUid) async {
    final appState = context.read<AppState>();
    final String? uid = appState.uid;
    if (uid == null) return;
    final int stars = _selectedVoteStars == 0 ? 3 : _selectedVoteStars;

    try {
      await _firestore.collection('speed_draw_rooms').doc(_roomId).update({
        'votes.$targetUid.$uid': stars
      });
      _myVotes[targetUid] = stars;
      _showSnackBar('Vote berhasil dikirim!', Colors.green);
    } catch (e) {
      debugPrint('Error submitting vote: $e');
      _showSnackBar('Gagal mengirim vote.', Colors.red);
    }
  }

  void _showOnlineResults() {
    _gameTimer?.cancel();
    _emojiTimer?.cancel();
    _emojiUpdateTimer?.cancel();

    final appState = context.read<AppState>();
    final votesMap = Map<String, dynamic>.from(_roomData['votes'] ?? {});

    // Compute scores
    List<Map<String, dynamic>> results = [];

    for (var player in _onlinePlayers) {
      final String uid = player['uid'];
      final playerVotes = Map<String, dynamic>.from(votesMap[uid] ?? {});
      
      // Calculate total stars received
      int totalStars = 0;
      if (playerVotes.isNotEmpty) {
        playerVotes.forEach((key, val) {
          totalStars += (val as num).toInt();
        });
      } else {
        // Default average if no one voted
        totalStars = (_onlinePlayers.length - 1) * 3;
      }

      results.add({
        'name': uid == appState.uid ? 'Kamu 👤' : player['name'],
        'avatar': player['avatar'],
        'score': totalStars,
        'isPlayer': uid == appState.uid,
        'lines': deserializeLines(player['lines'] ?? []),
        'color': Colors.blue,
      });
    }

    // Sort descending by score
    results.sort((a, b) => b['score'].compareTo(a['score']));
    
    // Identify rank
    int playerRank = results.indexWhere((r) => r['isPlayer'] == true) + 1;
    int maxPossibleStars = (_onlinePlayers.length - 1) * 5;
    int playerStars = results.firstWhere((r) => r['isPlayer'] == true)['score'];
    int motorScore = maxPossibleStars > 0 ? ((playerStars / maxPossibleStars) * 100.0).round().clamp(50, 100) : 100;

    setState(() {
      _gameState = SpeedDrawState.results;
      _standings = results;
    });

    // Update global app state
    context.read<AppState>().updateTestResults('motor', {
      'completed': true,
      'score': motorScore,
      'percentage': motorScore,
      'timeSpent': 40,
    });
    
    // Rewards
    int pointsEarned = (100 - (playerRank * 15)).clamp(40, 100);
    context.read<AppState>().addPointsFromScore(pointsEarned);
    if (playerRank == 1) {
      context.read<AppState>().addSticker('artist-pro');
    }

    AudioService().playAchievement();
  }

  // --- Helper to generate Bot Drawings ---
  List<DrawnLine> _getOpponentDrawing(String promptText, String name, Color color) {
    List<DrawnLine> lines = [];

    // Dapatkan estimasi ukuran kanvas aktif untuk penskalaan dinamis
    double targetWidth = 300.0;
    double targetHeight = 300.0;
    if (_lastCanvasWidth > 0 && _lastCanvasHeight > 0) {
      targetWidth = _lastCanvasWidth;
      targetHeight = _lastCanvasHeight;
    } else {
      try {
        final mediaQuery = MediaQuery.of(context);
        targetWidth = mediaQuery.size.width - 32;
        targetHeight = mediaQuery.size.height - 200;
        if (targetWidth <= 0) targetWidth = 300.0;
        if (targetHeight <= 0) targetHeight = 300.0;
      } catch (_) {
        targetWidth = 300.0;
        targetHeight = 300.0;
      }
    }

    final double scaleX = targetWidth / 300.0;
    final double scaleY = targetHeight / 300.0;
    final double scaleBrush = (scaleX + scaleY) / 2.0;

    // Helper untuk menskalakan titik-titik koordinat
    List<Offset> scalePoints(List<Offset> pts) {
      return pts.map((p) => Offset(p.dx * scaleX, p.dy * scaleY)).toList();
    }

    // Helper untuk membuat lingkaran koordinat
    List<Offset> generateCircle(double cx, double cy, double r, int count) {
      return List.generate(count, (i) {
        double angle = (i / (count - 1)) * 2 * math.pi;
        return Offset(cx + r * math.cos(angle), cy + r * math.sin(angle));
      });
    }

    if (promptText.contains('Rumah')) {
      // Atap Segitiga
      lines.add(DrawnLine(
        points: scalePoints([
          const Offset(150, 60),
          const Offset(70, 130),
          const Offset(230, 130),
          const Offset(150, 60),
        ]),
        color: color,
        width: 6.0 * scaleBrush,
      ));
      // Dinding Rumah
      lines.add(DrawnLine(
        points: scalePoints([
          const Offset(80, 130),
          const Offset(80, 230),
          const Offset(220, 230),
          const Offset(220, 130),
          const Offset(80, 130),
        ]),
        color: color,
        width: 6.0 * scaleBrush,
      ));
      // Pintu
      lines.add(DrawnLine(
        points: scalePoints([
          const Offset(135, 230),
          const Offset(135, 175),
          const Offset(165, 175),
          const Offset(165, 230),
        ]),
        color: color,
        width: 4.0 * scaleBrush,
      ));
      // Jendela
      lines.add(DrawnLine(
        points: scalePoints([
          const Offset(100, 155),
          const Offset(100, 185),
          const Offset(120, 185),
          const Offset(120, 155),
          const Offset(100, 155),
        ]),
        color: color,
        width: 3.0 * scaleBrush,
      ));
      // Cerobong asap
      lines.add(DrawnLine(
        points: scalePoints([
          const Offset(190, 95),
          const Offset(190, 70),
          const Offset(205, 70),
          const Offset(205, 108),
        ]),
        color: color,
        width: 4.0 * scaleBrush,
      ));
      // Asap
      lines.add(DrawnLine(
        points: scalePoints([
          const Offset(197, 60),
          const Offset(192, 50),
          const Offset(202, 40),
        ]),
        color: color.withOpacity(0.6),
        width: 3.0 * scaleBrush,
      ));
    } else if (promptText.contains('Bintang')) {
      // Bintang Utama
      lines.add(DrawnLine(
        points: scalePoints([
          const Offset(150, 50),
          const Offset(180, 130),
          const Offset(260, 130),
          const Offset(195, 180),
          const Offset(220, 260),
          const Offset(150, 210),
          const Offset(80, 260),
          const Offset(105, 180),
          const Offset(40, 130),
          const Offset(120, 130),
          const Offset(150, 50),
        ]),
        color: color,
        width: 6.0 * scaleBrush,
      ));
      // Bintang Kecil Kiri
      lines.add(DrawnLine(
        points: scalePoints([
          const Offset(60, 70),
          const Offset(65, 80),
          const Offset(75, 80),
          const Offset(68, 85),
          const Offset(70, 95),
          const Offset(60, 90),
          const Offset(50, 95),
          const Offset(52, 85),
          const Offset(45, 80),
          const Offset(55, 80),
          const Offset(60, 70),
        ]),
        color: color.withOpacity(0.7),
        width: 3.0 * scaleBrush,
      ));
      // Bintang Kecil Kanan
      lines.add(DrawnLine(
        points: scalePoints([
          const Offset(240, 70),
          const Offset(245, 80),
          const Offset(255, 80),
          const Offset(248, 85),
          const Offset(250, 95),
          const Offset(240, 90),
          const Offset(230, 95),
          const Offset(232, 85),
          const Offset(225, 80),
          const Offset(235, 80),
          const Offset(240, 70),
        ]),
        color: color.withOpacity(0.7),
        width: 3.0 * scaleBrush,
      ));
    } else if (promptText.contains('Awan')) {
      // Awan
      lines.add(DrawnLine(
        points: scalePoints([
          const Offset(100, 160),
          const Offset(120, 130),
          const Offset(150, 120),
          const Offset(180, 130),
          const Offset(200, 160),
          const Offset(220, 180),
          const Offset(200, 200),
          const Offset(100, 200),
          const Offset(80, 180),
          const Offset(100, 160),
        ]),
        color: color,
        width: 6.0 * scaleBrush,
      ));
      // Lengkungan dalam
      lines.add(DrawnLine(
        points: scalePoints([
          const Offset(110, 170),
          const Offset(130, 160),
          const Offset(150, 165),
        ]),
        color: color.withOpacity(0.6),
        width: 3.0 * scaleBrush,
      ));
      // Rintik Hujan
      lines.add(DrawnLine(
        points: scalePoints([const Offset(110, 215), const Offset(105, 230)]),
        color: color,
        width: 3.0 * scaleBrush,
      ));
      lines.add(DrawnLine(
        points: scalePoints([const Offset(150, 220), const Offset(145, 235)]),
        color: color,
        width: 3.0 * scaleBrush,
      ));
      lines.add(DrawnLine(
        points: scalePoints([const Offset(190, 215), const Offset(185, 230)]),
        color: color,
        width: 3.0 * scaleBrush,
      ));
    } else if (promptText.contains('Kotak')) {
      // Kotak Kado
      lines.add(DrawnLine(
        points: scalePoints([
          const Offset(80, 80),
          const Offset(220, 80),
          const Offset(220, 220),
          const Offset(80, 220),
          const Offset(80, 80),
        ]),
        color: color,
        width: 6.0 * scaleBrush,
      ));
      // Pita Vertikal
      lines.add(DrawnLine(
        points: scalePoints([const Offset(150, 80), const Offset(150, 220)]),
        color: Colors.redAccent,
        width: 10.0 * scaleBrush,
      ));
      // Pita Horizontal
      lines.add(DrawnLine(
        points: scalePoints([const Offset(80, 150), const Offset(220, 150)]),
        color: Colors.redAccent,
        width: 10.0 * scaleBrush,
      ));
      // Ikatan Pita Kiri
      lines.add(DrawnLine(
        points: scalePoints([
          const Offset(150, 80),
          const Offset(120, 50),
          const Offset(135, 40),
          const Offset(150, 80),
        ]),
        color: Colors.redAccent,
        width: 4.0 * scaleBrush,
      ));
      // Ikatan Pita Kanan
      lines.add(DrawnLine(
        points: scalePoints([
          const Offset(150, 80),
          const Offset(180, 50),
          const Offset(165, 40),
          const Offset(150, 80),
        ]),
        color: Colors.redAccent,
        width: 4.0 * scaleBrush,
      ));
    } else if (promptText.contains('Segitiga')) {
      // Segitiga Pizza
      lines.add(DrawnLine(
        points: scalePoints([
          const Offset(150, 60),
          const Offset(70, 210),
          const Offset(230, 210),
          const Offset(150, 60),
        ]),
        color: Colors.amber,
        width: 6.0 * scaleBrush,
      ));
      // Pinggiran Pizza (Crust)
      lines.add(DrawnLine(
        points: scalePoints([
          const Offset(65, 210),
          const Offset(235, 210),
          const Offset(230, 225),
          const Offset(70, 225),
          const Offset(65, 210),
        ]),
        color: color,
        width: 6.0 * scaleBrush,
      ));
      // Pepperoni
      lines.add(DrawnLine(
        points: scalePoints(generateCircle(150, 120, 10, 10)),
        color: Colors.red,
        width: 3.0 * scaleBrush,
      ));
      lines.add(DrawnLine(
        points: scalePoints(generateCircle(120, 170, 10, 10)),
        color: Colors.red,
        width: 3.0 * scaleBrush,
      ));
      lines.add(DrawnLine(
        points: scalePoints(generateCircle(180, 175, 10, 10)),
        color: Colors.red,
        width: 3.0 * scaleBrush,
      ));
    } else if (promptText.contains('Matahari')) {
      // Lingkaran Matahari
      lines.add(DrawnLine(
        points: scalePoints(generateCircle(150, 150, 50, 24)),
        color: Colors.amber,
        width: 6.0 * scaleBrush,
      ));
      // Sinar Matahari
      for (int i = 0; i < 8; i++) {
        double angle = (i / 8) * 2 * math.pi;
        lines.add(DrawnLine(
          points: scalePoints([
            Offset(150 + 55 * math.cos(angle), 150 + 55 * math.sin(angle)),
            Offset(150 + 75 * math.cos(angle), 150 + 75 * math.sin(angle)),
          ]),
          color: Colors.orange,
          width: 4.0 * scaleBrush,
        ));
      }
      // Senyum
      lines.add(DrawnLine(
        points: scalePoints([
          const Offset(135, 165),
          const Offset(150, 178),
          const Offset(165, 165),
        ]),
        color: Colors.redAccent,
        width: 3.0 * scaleBrush,
      ));
      // Kacamata Hitam Kiri
      lines.add(DrawnLine(
        points: scalePoints([
          const Offset(115, 140),
          const Offset(138, 140),
          const Offset(128, 152),
          const Offset(115, 140),
        ]),
        color: Colors.black,
        width: 3.0 * scaleBrush,
      ));
      // Kacamata Hitam Kanan
      lines.add(DrawnLine(
        points: scalePoints([
          const Offset(162, 140),
          const Offset(185, 140),
          const Offset(175, 152),
          const Offset(162, 140),
        ]),
        color: Colors.black,
        width: 3.0 * scaleBrush,
      ));
      // Penghubung kacamata
      lines.add(DrawnLine(
        points: scalePoints([const Offset(138, 142), const Offset(162, 142)]),
        color: Colors.black,
        width: 3.0 * scaleBrush,
      ));
    } else if (promptText.contains('Kucing')) {
      // Kepala
      lines.add(DrawnLine(
        points: scalePoints(generateCircle(150, 130, 42, 20)),
        color: color,
        width: 6.0 * scaleBrush,
      ));
      // Telinga Kiri
      lines.add(DrawnLine(
        points: scalePoints([const Offset(112, 102), const Offset(100, 60), const Offset(135, 94)]),
        color: color,
        width: 5.0 * scaleBrush,
      ));
      // Telinga Kanan
      lines.add(DrawnLine(
        points: scalePoints([const Offset(188, 102), const Offset(200, 60), const Offset(165, 94)]),
        color: color,
        width: 5.0 * scaleBrush,
      ));
      // Mata Kiri
      lines.add(DrawnLine(
        points: scalePoints([const Offset(132, 122), const Offset(133, 122)]),
        color: Colors.black,
        width: 8.0 * scaleBrush,
      ));
      // Mata Kanan
      lines.add(DrawnLine(
        points: scalePoints([const Offset(168, 122), const Offset(169, 122)]),
        color: Colors.black,
        width: 8.0 * scaleBrush,
      ));
      // Hidung & Mulut
      lines.add(DrawnLine(
        points: scalePoints([
          const Offset(145, 138),
          const Offset(150, 142),
          const Offset(155, 138),
        ]),
        color: Colors.redAccent,
        width: 3.0 * scaleBrush,
      ));
      // Kumis Kiri
      lines.add(DrawnLine(
        points: scalePoints([const Offset(115, 135), const Offset(90, 130)]),
        color: color,
        width: 2.0 * scaleBrush,
      ));
      lines.add(DrawnLine(
        points: scalePoints([const Offset(115, 142), const Offset(85, 142)]),
        color: color,
        width: 2.0 * scaleBrush,
      ));
      // Kumis Kanan
      lines.add(DrawnLine(
        points: scalePoints([const Offset(185, 135), const Offset(210, 130)]),
        color: color,
        width: 2.0 * scaleBrush,
      ));
      lines.add(DrawnLine(
        points: scalePoints([const Offset(185, 142), const Offset(215, 142)]),
        color: color,
        width: 2.0 * scaleBrush,
      ));
      // Badan
      lines.add(DrawnLine(
        points: scalePoints([
          const Offset(120, 170),
          const Offset(120, 240),
          const Offset(180, 240),
          const Offset(180, 170),
        ]),
        color: color,
        width: 5.0 * scaleBrush,
      ));
      // Ekor
      lines.add(DrawnLine(
        points: scalePoints([
          const Offset(180, 220),
          const Offset(215, 210),
          const Offset(225, 185),
        ]),
        color: color,
        width: 4.0 * scaleBrush,
      ));
    } else if (promptText.contains('Es Krim')) {
      // Cone
      lines.add(DrawnLine(
        points: scalePoints([
          const Offset(110, 160),
          const Offset(190, 160),
          const Offset(150, 250),
          const Offset(110, 160),
        ]),
        color: Colors.brown,
        width: 5.0 * scaleBrush,
      ));
      // Garis Cone
      lines.add(DrawnLine(
        points: scalePoints([const Offset(130, 160), const Offset(150, 250)]),
        color: Colors.brown.withOpacity(0.5),
        width: 3.0 * scaleBrush,
      ));
      lines.add(DrawnLine(
        points: scalePoints([const Offset(170, 160), const Offset(150, 250)]),
        color: Colors.brown.withOpacity(0.5),
        width: 3.0 * scaleBrush,
      ));
      // Es Krim Bawah
      lines.add(DrawnLine(
        points: scalePoints([
          const Offset(95, 160),
          const Offset(90, 140),
          const Offset(120, 130),
          const Offset(150, 140),
          const Offset(180, 130),
          const Offset(210, 140),
          const Offset(205, 160),
        ]),
        color: color,
        width: 6.0 * scaleBrush,
      ));
      // Es Krim Tengah
      lines.add(DrawnLine(
        points: scalePoints([
          const Offset(110, 135),
          const Offset(115, 110),
          const Offset(150, 100),
          const Offset(185, 110),
          const Offset(190, 135),
        ]),
        color: color,
        width: 6.0 * scaleBrush,
      ));
      // Puncak Es Krim
      lines.add(DrawnLine(
        points: scalePoints([
          const Offset(130, 105),
          const Offset(150, 75),
          const Offset(170, 105),
        ]),
        color: color,
        width: 6.0 * scaleBrush,
      ));
      // Ceri
      lines.add(DrawnLine(
        points: scalePoints(generateCircle(150, 65, 8, 10)),
        color: Colors.red,
        width: 4.0 * scaleBrush,
      ));
      // Tangkai Ceri
      lines.add(DrawnLine(
        points: scalePoints([const Offset(150, 57), const Offset(162, 45)]),
        color: Colors.green,
        width: 2.0 * scaleBrush,
      ));
    } else if (promptText.contains('Mobil')) {
      // Body Mobil
      lines.add(DrawnLine(
        points: scalePoints([
          const Offset(50, 170),
          const Offset(250, 170),
          const Offset(250, 210),
          const Offset(50, 210),
          const Offset(50, 170),
        ]),
        color: color,
        width: 6.0 * scaleBrush,
      ));
      // Kabin Atap Mobil
      lines.add(DrawnLine(
        points: scalePoints([
          const Offset(90, 170),
          const Offset(110, 120),
          const Offset(190, 120),
          const Offset(210, 170),
        ]),
        color: color,
        width: 5.0 * scaleBrush,
      ));
      // Pembatas Jendela
      lines.add(DrawnLine(
        points: scalePoints([const Offset(150, 120), const Offset(150, 170)]),
        color: color,
        width: 3.0 * scaleBrush,
      ));
      // Roda Kiri
      lines.add(DrawnLine(
        points: scalePoints(generateCircle(95, 215, 18, 12)),
        color: Colors.black,
        width: 6.0 * scaleBrush,
      ));
      // Roda Kanan
      lines.add(DrawnLine(
        points: scalePoints(generateCircle(205, 215, 18, 12)),
        color: Colors.black,
        width: 6.0 * scaleBrush,
      ));
      // Lampu depan
      lines.add(DrawnLine(
        points: scalePoints([const Offset(245, 180), const Offset(250, 185), const Offset(245, 190)]),
        color: Colors.yellowAccent,
        width: 4.0 * scaleBrush,
      ));
    } else if (promptText.contains('Bunga')) {
      // Batang
      lines.add(DrawnLine(
        points: scalePoints([const Offset(150, 170), const Offset(150, 250)]),
        color: Colors.green,
        width: 5.0 * scaleBrush,
      ));
      // Daun Kiri
      lines.add(DrawnLine(
        points: scalePoints([const Offset(150, 210), const Offset(120, 200), const Offset(150, 190)]),
        color: Colors.green,
        width: 4.0 * scaleBrush,
      ));
      // Daun Kanan
      lines.add(DrawnLine(
        points: scalePoints([const Offset(150, 225), const Offset(180, 215), const Offset(150, 205)]),
        color: Colors.green,
        width: 4.0 * scaleBrush,
      ));
      // Putik Tengah
      lines.add(DrawnLine(
        points: scalePoints(generateCircle(150, 135, 18, 15)),
        color: Colors.yellow,
        width: 5.0 * scaleBrush,
      ));
      // Kelopak Bunga (5 Kelopak)
      for (int i = 0; i < 5; i++) {
        double angle = (i / 5) * 2 * math.pi;
        double px = 150 + 30 * math.cos(angle);
        double py = 135 + 30 * math.sin(angle);
        lines.add(DrawnLine(
          points: scalePoints(generateCircle(px, py, 12, 10)),
          color: color,
          width: 4.0 * scaleBrush,
        ));
      }
    } else if (promptText.contains('Ikan')) {
      // Badan Ikan
      lines.add(DrawnLine(
        points: scalePoints([
          const Offset(80, 150),
          const Offset(130, 110),
          const Offset(210, 120),
          const Offset(230, 150),
          const Offset(210, 180),
          const Offset(130, 190),
          const Offset(80, 150),
        ]),
        color: color,
        width: 6.0 * scaleBrush,
      ));
      // Mata
      lines.add(DrawnLine(
        points: scalePoints([const Offset(202, 142), const Offset(203, 142)]),
        color: Colors.black,
        width: 6.0 * scaleBrush,
      ));
      // Insang
      lines.add(DrawnLine(
        points: scalePoints([const Offset(190, 130), const Offset(185, 170)]),
        color: color.withOpacity(0.7),
        width: 3.0 * scaleBrush,
      ));
      // Ekor Ikan
      lines.add(DrawnLine(
        points: scalePoints([
          const Offset(80, 150),
          const Offset(50, 115),
          const Offset(60, 150),
          const Offset(50, 185),
          const Offset(80, 150),
        ]),
        color: color,
        width: 5.0 * scaleBrush,
      ));
      // Sirip Atas
      lines.add(DrawnLine(
        points: scalePoints([const Offset(150, 115), const Offset(170, 90), const Offset(190, 118)]),
        color: color,
        width: 4.0 * scaleBrush,
      ));
    } else if (promptText.contains('Pohon')) {
      // Batang
      lines.add(DrawnLine(
        points: scalePoints([
          const Offset(140, 180),
          const Offset(135, 250),
          const Offset(165, 250),
          const Offset(160, 180),
          const Offset(140, 180),
        ]),
        color: Colors.brown,
        width: 6.0 * scaleBrush,
      ));
      // Daun Rimbun
      lines.add(DrawnLine(
        points: scalePoints(generateCircle(150, 130, 52, 24)),
        color: Colors.green,
        width: 6.0 * scaleBrush,
      ));
      // Detail Daun dalam
      lines.add(DrawnLine(
        points: scalePoints([const Offset(130, 115), const Offset(150, 105), const Offset(170, 115)]),
        color: Colors.green.shade800,
        width: 4.0 * scaleBrush,
      ));
      // Buah Apel
      lines.add(DrawnLine(
        points: scalePoints(generateCircle(120, 120, 5, 8)),
        color: Colors.red,
        width: 3.0 * scaleBrush,
      ));
      lines.add(DrawnLine(
        points: scalePoints(generateCircle(180, 130, 5, 8)),
        color: Colors.red,
        width: 3.0 * scaleBrush,
      ));
      lines.add(DrawnLine(
        points: scalePoints(generateCircle(150, 95, 5, 8)),
        color: Colors.red,
        width: 3.0 * scaleBrush,
      ));
    } else if (promptText.contains('Roket')) {
      // Kepala Roket
      lines.add(DrawnLine(
        points: scalePoints([
          const Offset(150, 50),
          const Offset(125, 90),
          const Offset(175, 90),
          const Offset(150, 50),
        ]),
        color: Colors.red,
        width: 6.0 * scaleBrush,
      ));
      // Badan Roket
      lines.add(DrawnLine(
        points: scalePoints([
          const Offset(125, 90),
          const Offset(125, 200),
          const Offset(175, 200),
          const Offset(175, 90),
        ]),
        color: color,
        width: 6.0 * scaleBrush,
      ));
      // Sayap Kiri
      lines.add(DrawnLine(
        points: scalePoints([const Offset(125, 160), const Offset(95, 210), const Offset(125, 210)]),
        color: Colors.red,
        width: 5.0 * scaleBrush,
      ));
      // Sayap Kanan
      lines.add(DrawnLine(
        points: scalePoints([const Offset(175, 160), const Offset(205, 210), const Offset(175, 210)]),
        color: Colors.red,
        width: 5.0 * scaleBrush,
      ));
      // Jendela Roket
      lines.add(DrawnLine(
        points: scalePoints(generateCircle(150, 130, 12, 12)),
        color: Colors.blueAccent,
        width: 4.0 * scaleBrush,
      ));
      // Api Pendorong
      lines.add(DrawnLine(
        points: scalePoints([
          const Offset(135, 205),
          const Offset(150, 245),
          const Offset(165, 205),
          const Offset(150, 220),
          const Offset(135, 205),
        ]),
        color: Colors.orange,
        width: 4.0 * scaleBrush,
      ));
    } else if (promptText.contains('Naga')) {
      // Badan Naga meliuk-liuk
      lines.add(DrawnLine(
        points: scalePoints([
          const Offset(225, 95),
          const Offset(185, 100),
          const Offset(150, 130),
          const Offset(130, 170),
          const Offset(160, 200),
          const Offset(190, 215),
          const Offset(160, 240),
          const Offset(110, 230),
          const Offset(75, 185),
        ]),
        color: color,
        width: 6.0 * scaleBrush,
      ));
      // Kepala Naga
      lines.add(DrawnLine(
        points: scalePoints([
          const Offset(225, 95),
          const Offset(220, 75),
          const Offset(245, 75),
          const Offset(255, 95),
          const Offset(235, 105),
          const Offset(225, 95),
        ]),
        color: color,
        width: 6.0 * scaleBrush,
      ));
      // Tanduk Naga
      lines.add(DrawnLine(
        points: scalePoints([const Offset(222, 75), const Offset(212, 55)]),
        color: Colors.orange,
        width: 3.0 * scaleBrush,
      ));
      lines.add(DrawnLine(
        points: scalePoints([const Offset(235, 75), const Offset(228, 55)]),
        color: Colors.orange,
        width: 3.0 * scaleBrush,
      ));
      // Mata Naga
      lines.add(DrawnLine(
        points: scalePoints([const Offset(238, 86)]),
        color: Colors.black,
        width: 5.0 * scaleBrush,
      ));
      // Sayap Naga
      lines.add(DrawnLine(
        points: scalePoints([
          const Offset(150, 130),
          const Offset(120, 70),
          const Offset(145, 95),
          const Offset(145, 135),
        ]),
        color: Colors.redAccent,
        width: 4.0 * scaleBrush,
      ));
      // Ekor Sekop
      lines.add(DrawnLine(
        points: scalePoints([
          const Offset(75, 185),
          const Offset(55, 180),
          const Offset(65, 200),
          const Offset(78, 188),
        ]),
        color: Colors.orange,
        width: 4.0 * scaleBrush,
      ));
    } else if (promptText.contains('Kastil')) {
      // Dinding Kastil Utama
      lines.add(DrawnLine(
        points: scalePoints([
          const Offset(70, 160),
          const Offset(230, 160),
          const Offset(230, 240),
          const Offset(70, 240),
          const Offset(70, 160),
        ]),
        color: color,
        width: 6.0 * scaleBrush,
      ));
      // Gerigi Kastil (Battlements)
      lines.add(DrawnLine(
        points: scalePoints([
          const Offset(70, 160), const Offset(70, 150), const Offset(90, 150), const Offset(90, 160),
          const Offset(110, 160), const Offset(110, 150), const Offset(130, 150), const Offset(130, 160),
          const Offset(170, 160), const Offset(170, 150), const Offset(190, 150), const Offset(190, 160),
          const Offset(210, 160), const Offset(210, 150), const Offset(230, 150), const Offset(230, 160),
        ]),
        color: color,
        width: 4.0 * scaleBrush,
      ));
      // Menara Tengah
      lines.add(DrawnLine(
        points: scalePoints([
          const Offset(130, 160),
          const Offset(130, 110),
          const Offset(170, 110),
          const Offset(170, 160),
        ]),
        color: color,
        width: 5.0 * scaleBrush,
      ));
      // Atap Kerucut Tengah
      lines.add(DrawnLine(
        points: scalePoints([
          const Offset(130, 110),
          const Offset(150, 70),
          const Offset(170, 110),
        ]),
        color: Colors.red,
        width: 5.0 * scaleBrush,
      ));
      // Menara Kiri
      lines.add(DrawnLine(
        points: scalePoints([
          const Offset(50, 240),
          const Offset(50, 120),
          const Offset(80, 120),
          const Offset(80, 240),
        ]),
        color: color,
        width: 5.0 * scaleBrush,
      ));
      // Atap Kerucut Kiri
      lines.add(DrawnLine(
        points: scalePoints([
          const Offset(50, 120),
          const Offset(65, 80),
          const Offset(80, 120),
        ]),
        color: Colors.red,
        width: 5.0 * scaleBrush,
      ));
      // Menara Kanan
      lines.add(DrawnLine(
        points: scalePoints([
          const Offset(220, 240),
          const Offset(220, 120),
          const Offset(250, 120),
          const Offset(250, 240),
        ]),
        color: color,
        width: 5.0 * scaleBrush,
      ));
      // Atap Kerucut Kanan
      lines.add(DrawnLine(
        points: scalePoints([
          const Offset(220, 120),
          const Offset(235, 80),
          const Offset(250, 120),
        ]),
        color: Colors.red,
        width: 5.0 * scaleBrush,
      ));
      // Gerbang Gerigi
      lines.add(DrawnLine(
        points: scalePoints([
          const Offset(130, 240),
          const Offset(130, 200),
          const Offset(140, 190),
          const Offset(160, 190),
          const Offset(170, 200),
          const Offset(170, 240),
        ]),
        color: Colors.black,
        width: 4.0 * scaleBrush,
      ));
    } else if (promptText.contains('Astronaut')) {
      // Badan Pakaian Astronaut
      lines.add(DrawnLine(
        points: scalePoints([
          const Offset(110, 150),
          const Offset(110, 230),
          const Offset(190, 230),
          const Offset(190, 150),
          const Offset(110, 150),
        ]),
        color: color,
        width: 6.0 * scaleBrush,
      ));
      // Helm Bulat
      lines.add(DrawnLine(
        points: scalePoints(generateCircle(150, 110, 38, 20)),
        color: color,
        width: 6.0 * scaleBrush,
      ));
      // Kaca Helm Depan (Visor)
      lines.add(DrawnLine(
        points: scalePoints(generateCircle(150, 110, 22, 12)),
        color: Colors.blueAccent,
        width: 4.0 * scaleBrush,
      ));
      // Kilau Kaca Helm
      lines.add(DrawnLine(
        points: scalePoints([const Offset(136, 102), const Offset(148, 97)]),
        color: Colors.white,
        width: 3.0 * scaleBrush,
      ));
      // Tangan Kiri
      lines.add(DrawnLine(
        points: scalePoints([const Offset(110, 160), const Offset(80, 190), const Offset(90, 200), const Offset(110, 180)]),
        color: color,
        width: 4.0 * scaleBrush,
      ));
      // Tangan Kanan
      lines.add(DrawnLine(
        points: scalePoints([const Offset(190, 160), const Offset(220, 190), const Offset(210, 200), const Offset(190, 180)]),
        color: color,
        width: 4.0 * scaleBrush,
      ));
      // Panel kontrol di dada
      lines.add(DrawnLine(
        points: scalePoints([
          const Offset(135, 175),
          const Offset(165, 175),
          const Offset(165, 200),
          const Offset(135, 200),
          const Offset(135, 175),
        ]),
        color: Colors.red,
        width: 3.0 * scaleBrush,
      ));
    } else if (promptText.contains('T-Rex')) {
      // Kepala & Punggung
      lines.add(DrawnLine(
        points: scalePoints([
          const Offset(190, 70),
          const Offset(210, 70),
          const Offset(220, 85),
          const Offset(200, 105),
          const Offset(150, 120),
          const Offset(120, 150),
          const Offset(105, 190),
          const Offset(85, 225),
          const Offset(45, 235),
        ]),
        color: color,
        width: 6.0 * scaleBrush,
      ));
      // Perut & Bawah ekor
      lines.add(DrawnLine(
        points: scalePoints([
          const Offset(45, 235),
          const Offset(75, 242),
          const Offset(110, 242),
          const Offset(130, 210),
          const Offset(155, 170),
          const Offset(165, 140),
        ]),
        color: color,
        width: 6.0 * scaleBrush,
      ));
      // Rahang Atas
      lines.add(DrawnLine(
        points: scalePoints([const Offset(210, 70), const Offset(238, 80), const Offset(233, 95), const Offset(205, 95)]),
        color: color,
        width: 6.0 * scaleBrush,
      ));
      // Rahang Bawah
      lines.add(DrawnLine(
        points: scalePoints([const Offset(205, 100), const Offset(223, 100), const Offset(218, 108), const Offset(195, 105)]),
        color: color,
        width: 5.0 * scaleBrush,
      ));
      // Mata T-Rex
      lines.add(DrawnLine(
        points: scalePoints([const Offset(202, 82)]),
        color: Colors.black,
        width: 5.0 * scaleBrush,
      ));
      // Tangan Kecil
      lines.add(DrawnLine(
        points: scalePoints([const Offset(160, 150), const Offset(178, 150), const Offset(178, 158)]),
        color: color,
        width: 3.0 * scaleBrush,
      ));
      // Kaki Kiri
      lines.add(DrawnLine(
        points: scalePoints([const Offset(120, 200), const Offset(115, 245), const Offset(130, 245)]),
        color: color,
        width: 5.0 * scaleBrush,
      ));
      // Kaki Kanan
      lines.add(DrawnLine(
        points: scalePoints([const Offset(135, 200), const Offset(135, 245), const Offset(150, 245)]),
        color: color,
        width: 5.0 * scaleBrush,
      ));
    } else if (promptText.contains('Kapal Laut')) {
      // Lambung Kapal
      lines.add(DrawnLine(
        points: scalePoints([
          const Offset(40, 180),
          const Offset(260, 180),
          const Offset(240, 230),
          const Offset(70, 230),
          const Offset(40, 180),
        ]),
        color: color,
        width: 6.0 * scaleBrush,
      ));
      // Kabin Dek 1
      lines.add(DrawnLine(
        points: scalePoints([
          const Offset(80, 180),
          const Offset(80, 150),
          const Offset(210, 150),
          const Offset(210, 180),
        ]),
        color: color,
        width: 5.0 * scaleBrush,
      ));
      // Kabin Dek 2
      lines.add(DrawnLine(
        points: scalePoints([
          const Offset(110, 150),
          const Offset(110, 125),
          const Offset(190, 125),
          const Offset(190, 150),
        ]),
        color: color,
        width: 5.0 * scaleBrush,
      ));
      // Cerobong 1
      lines.add(DrawnLine(
        points: scalePoints([const Offset(130, 125), const Offset(130, 100), const Offset(145, 100), const Offset(145, 125)]),
        color: Colors.black,
        width: 4.0 * scaleBrush,
      ));
      // Cerobong 2
      lines.add(DrawnLine(
        points: scalePoints([const Offset(160, 125), const Offset(160, 100), const Offset(175, 100), const Offset(175, 125)]),
        color: Colors.black,
        width: 4.0 * scaleBrush,
      ));
      // Jendela Bulat Dek
      lines.add(DrawnLine(
        points: scalePoints([const Offset(125, 137), const Offset(126, 137)]),
        color: Colors.yellow,
        width: 6.0 * scaleBrush,
      ));
      lines.add(DrawnLine(
        points: scalePoints([const Offset(150, 137), const Offset(151, 137)]),
        color: Colors.yellow,
        width: 6.0 * scaleBrush,
      ));
      lines.add(DrawnLine(
        points: scalePoints([const Offset(175, 137), const Offset(176, 137)]),
        color: Colors.yellow,
        width: 6.0 * scaleBrush,
      ));
      // Ombak Air
      lines.add(DrawnLine(
        points: scalePoints([
          const Offset(20, 235), const Offset(60, 245), const Offset(100, 235),
          const Offset(140, 245), const Offset(180, 235), const Offset(220, 245), const Offset(260, 235)
        ]),
        color: Colors.blue,
        width: 4.0 * scaleBrush,
      ));
    } else {
      // Fallback Wajah Bulat Senyum jika prompt tidak dikenali
      lines.add(DrawnLine(
        points: scalePoints(generateCircle(150, 150, 60, 24)),
        color: color,
        width: 6.0 * scaleBrush,
      ));
      lines.add(DrawnLine(
        points: scalePoints([const Offset(130, 135), const Offset(131, 135)]),
        color: Colors.black,
        width: 8.0 * scaleBrush,
      ));
      lines.add(DrawnLine(
        points: scalePoints([const Offset(170, 135), const Offset(171, 135)]),
        color: Colors.black,
        width: 8.0 * scaleBrush,
      ));
      lines.add(DrawnLine(
        points: scalePoints([
          const Offset(130, 170),
          const Offset(150, 185),
          const Offset(170, 170),
        ]),
        color: Colors.redAccent,
        width: 4.0 * scaleBrush,
      ));
    }

    return lines;
  }

  // --- Offline Bot Mode Actions ---

  void _startBotLobby() {
    setState(() {
      _selectedMode = SpeedDrawMode.bot;
      _gameState = SpeedDrawState.lobby;
      _userLines = [];
      _myVotes = {};
      _botVotesForPlayer = [0, 0, 0];
      _voteLogs = [];
      _selectedVoteStars = 0;
    });
    AudioService().playGameBGM();
  }

  void _startBotPrep() {
    final random = math.Random();
    final List<Map<String, String>> promptList;
    if (_selectedDifficulty == 'easy') {
      promptList = easyPrompts;
    } else if (_selectedDifficulty == 'hard') {
      promptList = hardPrompts;
    } else {
      promptList = mediumPrompts;
    }
    setState(() {
      _currentPrompt = promptList[random.nextInt(promptList.length)];
      _gameState = SpeedDrawState.prep;
      _timeLeft = 3;
    });
    
    AudioService().playClick();
    
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 1) {
        setState(() {
          _timeLeft--;
        });
        AudioService().playClick();
      } else {
        timer.cancel();
        _startBotDrawing();
      }
    });
  }

  void _startBotDrawing() {
    setState(() {
      _gameState = SpeedDrawState.drawing;
      _timeLeft = _getDrawingDuration(_selectedDifficulty);
      _userLines = [];
    });

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 1) {
        setState(() {
          _timeLeft--;
        });
        if (_timeLeft <= 5) {
          AudioService().playClick();
        }
      } else {
        timer.cancel();
        _submitBotDrawing();
      }
    });
  }

  void _submitBotDrawing() {
    _gameTimer?.cancel();
    
    // Pre-generate bot drawings
    for (var bot in _botOpponents) {
      bot['lines'] = _getOpponentDrawing(_currentPrompt['text']!, bot['name']!, bot['color']);
    }

    _startBotVoting();
  }

  void _startBotVoting() {
    setState(() {
      _gameState = SpeedDrawState.voting;
      _votingIndex = 0; // DinoDraw
      _timeLeft = 6;
      _selectedVoteStars = 0;
    });

    _runBotVotingTimer();
  }

  void _runBotVotingTimer() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 1) {
        setState(() {
          _timeLeft--;
        });
      } else {
        timer.cancel();
        _nextBotVotingStep();
      }
    });
  }

  void _nextBotVotingStep() {
    if (_votingIndex < 3) {
      String name = _botOpponents[_votingIndex]['name'];
      _myVotes[name] = _selectedVoteStars == 0 ? 3 : _selectedVoteStars;
    }

    if (_votingIndex < 2) {
      setState(() {
        _votingIndex++;
        _timeLeft = 6;
        _selectedVoteStars = 0;
      });
      _runBotVotingTimer();
    } else if (_votingIndex == 2) {
      setState(() {
        _votingIndex = 3;
        _timeLeft = 8;
        _floatingEmojis = [];
      });
      _startBotRatingRevealForPlayer();
    } else {
      _showBotResults();
    }
  }

  void _startBotRatingRevealForPlayer() {
    AudioService().playAchievement();
    _startLocalPlayerReactionSimulation();

    final random = math.Random();
    _botVotesForPlayer = [
      3 + random.nextInt(3),
      2 + random.nextInt(4),
      3 + random.nextInt(3),
    ];

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _gameState == SpeedDrawState.voting && _votingIndex == 3) {
        setState(() {
          _voteLogs.add('${_botOpponents[0]['name']}: ⭐ ${_botVotesForPlayer[0]} Bintang!');
        });
        AudioService().playClick();
      }
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _gameState == SpeedDrawState.voting && _votingIndex == 3) {
        setState(() {
          _voteLogs.add('${_botOpponents[1]['name']}: ⭐ ${_botVotesForPlayer[1]} Bintang!');
        });
        AudioService().playClick();
      }
    });

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _gameState == SpeedDrawState.voting && _votingIndex == 3) {
        setState(() {
          _voteLogs.add('${_botOpponents[2]['name']}: ⭐ ${_botVotesForPlayer[2]} Bintang!');
        });
        AudioService().playClick();
      }
    });

    _runBotVotingTimer();
  }

  void _showBotResults() {
    _gameTimer?.cancel();
    _emojiTimer?.cancel();
    _emojiUpdateTimer?.cancel();

    final random = math.Random();
    int scoreOpp1 = (_myVotes[_botOpponents[0]['name']] ?? 3) + 6 + random.nextInt(4);
    int scoreOpp2 = (_myVotes[_botOpponents[1]['name']] ?? 3) + 7 + random.nextInt(3);
    int scoreOpp3 = (_myVotes[_botOpponents[2]['name']] ?? 3) + 5 + random.nextInt(5);
    int playerTotalStars = _botVotesForPlayer.reduce((value, element) => value + element);

    List<Map<String, dynamic>> results = [
      {
        'name': 'Kamu 👤',
        'avatar': '🧒',
        'score': playerTotalStars,
        'isPlayer': true,
        'lines': _userLines,
        'color': Colors.blue,
      },
      {
        'name': _botOpponents[0]['name'],
        'avatar': _botOpponents[0]['avatar'],
        'score': scoreOpp1,
        'isPlayer': false,
        'lines': _botOpponents[0]['lines'],
        'color': _botOpponents[0]['color'],
      },
      {
        'name': _botOpponents[1]['name'],
        'avatar': _botOpponents[1]['avatar'],
        'score': scoreOpp2,
        'isPlayer': false,
        'lines': _botOpponents[1]['lines'],
        'color': _botOpponents[1]['color'],
      },
      {
        'name': _botOpponents[2]['name'],
        'avatar': _botOpponents[2]['avatar'],
        'score': scoreOpp3,
        'isPlayer': false,
        'lines': _botOpponents[2]['lines'],
        'color': _botOpponents[2]['color'],
      },
    ];

    results.sort((a, b) => b['score'].compareTo(a['score']));
    int playerRank = results.indexWhere((r) => r['isPlayer'] == true) + 1;
    int motorScore = ((playerTotalStars / 15.0) * 100.0).round().clamp(50, 100);

    setState(() {
      _gameState = SpeedDrawState.results;
      _standings = results;
    });

    context.read<AppState>().updateTestResults('motor', {
      'completed': true,
      'score': motorScore,
      'percentage': motorScore,
      'timeSpent': _getDrawingDuration(_selectedDifficulty),
    });
    
    int pointsEarned = (100 - (playerRank * 15)).clamp(40, 100);
    context.read<AppState>().addPointsFromScore(pointsEarned);
    if (playerRank == 1) {
      context.read<AppState>().addSticker('artist-pro');
    }

    AudioService().playAchievement();
  }

  // --- Helper UI Utilities ---

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, duration: const Duration(seconds: 2))
    );
  }

  // --- Views Router ---

  @override
  Widget build(BuildContext context) {
    if (_selectedMode == null) {
      return _buildModeSelectionScreen();
    }
    
    if (_selectedMode == SpeedDrawMode.player && _roomId != null && _gameState == SpeedDrawState.lobby) {
      return _buildOnlineLobbyView();
    }

    switch (_gameState) {
      case SpeedDrawState.lobby:
        return _buildBotLobbyView();
      case SpeedDrawState.prep:
        return _buildPrepView();
      case SpeedDrawState.drawing:
        return _buildDrawingView();
      case SpeedDrawState.voting:
        return _buildVotingView();
      case SpeedDrawState.results:
        return _buildResultsView();
    }
  }

  Widget _buildModeSelectionScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Speed Draw 🎨', style: AppTheme.heading3),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.gray700),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.palette_rounded, size: 96, color: Color(0xFF2563EB)),
            const SizedBox(height: 16),
            Text(
              'Speed Draw Challenge',
              style: AppTheme.heading2.copyWith(fontSize: 28, letterSpacing: -0.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Pilih mode permainan dan mulailah menggambar dengan cepat!',
              style: TextStyle(color: AppTheme.gray500, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            // Mode 1: Offline Vs Bot
            GestureDetector(
              onTap: _startBotLobby,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)]),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.pink.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    const Text('🤖', style: TextStyle(fontSize: 40)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Mode Offline (Vs Bot)', style: AppTheme.heading3.copyWith(color: Colors.white, fontSize: 18)),
                          const SizedBox(height: 4),
                          const Text('Lawan robot AI pintar untuk melatih imajinasi cepat.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Mode 2: Online Vs Player
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedMode = SpeedDrawMode.player;
                  _gameState = SpeedDrawState.lobby;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    const Text('👥', style: TextStyle(fontSize: 40)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Mode Online (Vs Player)', style: AppTheme.heading3.copyWith(color: Colors.white, fontSize: 18)),
                          const SizedBox(height: 4),
                          const Text('Buat atau gabung room dan bermain bersama teman secara real-time.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotLobbyLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text('Speed Draw Vs Bot 🤖', style: AppTheme.heading3),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.gray700),
          onPressed: () => setState(() => _selectedMode = null),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: Colors.pink.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
              ),
              child: Column(
                children: [
                  const Text('🤖⚡', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 12),
                  Text('Tantangan Offline Vs Bot', style: AppTheme.heading2.copyWith(color: Colors.white, fontSize: 24)),
                  const SizedBox(height: 4),
                  Text(
                    'Kalahkan 3 bot AI handal dalam menggambar cepat. Kamu memiliki waktu ${_formatTime(_getDrawingDuration(_selectedDifficulty))}!',
                    style: TextStyle(color: Colors.pink.shade100, fontSize: 13, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tingkat Kesulitan', style: AppTheme.heading3.copyWith(fontSize: 16)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildDifficultyButton('easy', 'Mudah 🟢', Colors.green),
                      const SizedBox(width: 8),
                      _buildDifficultyButton('medium', 'Sedang 🟡', Colors.orange),
                      const SizedBox(width: 8),
                      _buildDifficultyButton('hard', 'Sulit 🔴', Colors.red),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Daftar Penantang', style: AppTheme.heading3.copyWith(fontSize: 16)),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: CircleAvatar(backgroundColor: Colors.pink.shade100, child: const Text('🧒', style: TextStyle(fontSize: 20))),
                    title: const Text('Kamu (Seniman Cilik)', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Siap tanding', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.check_circle, color: Colors.green),
                  ),
                  const Divider(),
                  ..._botOpponents.map((opp) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: opp['color'].withOpacity(0.2),
                        child: Text(opp['avatar'], style: const TextStyle(fontSize: 20)),
                      ),
                      title: Text(opp['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Bot AI - Menunggu...', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      trailing: const Icon(Icons.smart_toy, color: Colors.purpleAccent),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _startBotPrep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 6,
                ),
                child: const Text('MULAI PERTANDINGAN 🚀', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnlineLobbyView() {
    final appState = context.read<AppState>();
    
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text('Lobby Online 👥', style: AppTheme.heading3),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.gray700),
          onPressed: _leaveOnlineRoom,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Room code banner
            Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)]),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  const Text('KODE ROOM', style: TextStyle(color: Colors.blueAccent, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  const SizedBox(height: 4),
                  Text(
                    _roomId!,
                    style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: 6),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Bagikan kode ini kepada teman Anda untuk bermain bersama!',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isHost ? 'Pilih Tingkat Kesulitan (Host)' : 'Tingkat Kesulitan (Dipilih Host)',
                    style: AppTheme.heading3.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildDifficultyButton('easy', 'Mudah 🟢', Colors.green, enabled: _isHost, onSelect: _updateOnlineRoomDifficulty),
                      const SizedBox(width: 8),
                      _buildDifficultyButton('medium', 'Sedang 🟡', Colors.orange, enabled: _isHost, onSelect: _updateOnlineRoomDifficulty),
                      const SizedBox(width: 8),
                      _buildDifficultyButton('hard', 'Sulit 🔴', Colors.red, enabled: _isHost, onSelect: _updateOnlineRoomDifficulty),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Connected players list
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Pemain Terkoneksi', style: AppTheme.heading3.copyWith(fontSize: 16)),
                      Text('${_onlinePlayers.length}/4', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _onlinePlayers.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final p = _onlinePlayers[index];
                      final bool isMe = p['uid'] == appState.uid;
                      final bool isHostPlayer = p['uid'] == _roomData['hostUid'];
                      
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade50,
                          child: Text(p['avatar'] ?? '🧒', style: const TextStyle(fontSize: 20)),
                        ),
                        title: Text(
                          isMe ? '${p['name']} (Kamu)' : p['name'],
                          style: TextStyle(fontWeight: isMe ? FontWeight.w900 : FontWeight.w600),
                        ),
                        subtitle: Text(
                          isHostPlayer ? 'Host Pembuat Room' : 'Pemain',
                          style: TextStyle(color: isHostPlayer ? Colors.orange : Colors.grey, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        trailing: p['ready'] == true 
                            ? const Icon(Icons.check_circle, color: Colors.green) 
                            : const Icon(Icons.hourglass_empty, color: Colors.grey),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            // Start online match triggers
            if (_isHost)
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _onlinePlayers.isNotEmpty ? _startOnlineMatch : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 6,
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: const Text('MULAI PERTANDINGAN 🚀', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.orange.shade200)),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange)),
                    SizedBox(width: 12),
                    Text('Menunggu Host memulai pertandingan...', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrepView() {
    return Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('TEMA GAMBAR:', style: TextStyle(color: Colors.blueAccent, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2)),
            const SizedBox(height: 16),
            Text(
              _currentPrompt['text']!,
              style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Text(
                '$_timeLeft',
                style: const TextStyle(color: Colors.orangeAccent, fontSize: 72, fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Bersiaplah menggambar di layar kosong!',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawingView() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Container(),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gambar: ${_currentPrompt['text']}', style: AppTheme.heading3.copyWith(fontSize: 18)),
            Text('Ayo buat sekreatif mungkin!', style: TextStyle(color: AppTheme.gray500, fontSize: 11)),
          ],
        ),
        actions: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: _timeLeft <= 5 ? Colors.red.shade50 : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _timeLeft <= 5 ? Colors.red.shade200 : Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.timer_outlined, color: _timeLeft <= 5 ? Colors.red : Colors.blue, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    _formatTime(_timeLeft),
                    style: TextStyle(
                      color: _timeLeft <= 5 ? Colors.red : Colors.blue,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: ElevatedButton(
              onPressed: _drawingSubmitted
                  ? null
                  : (_selectedMode == SpeedDrawMode.player ? _submitOnlineDrawing : _submitBotDrawing),
              style: ElevatedButton.styleFrom(
                backgroundColor: _drawingSubmitted ? Colors.grey : Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                elevation: 0,
              ),
              child: Text(
                _drawingSubmitted ? 'TERKIRIM' : 'SELESAI',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200, width: 2),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final w = constraints.maxWidth;
                        final h = constraints.maxHeight;
                        if (w != _lastCanvasWidth || h != _lastCanvasHeight) {
                          _lastCanvasWidth = w;
                          _lastCanvasHeight = h;
                          scheduleMicrotask(() {
                            if (mounted) {
                              _updateUserFilledPoints(w, h);
                            }
                          });
                        }

                        return GestureDetector(
                          onPanStart: _drawingSubmitted ? null : (details) {
                            if (_isBucketMode) {
                              final tapPos = details.localPosition;
                              final fillLine = DrawnLine(
                                points: [Offset(
                                  ((tapPos.dx / _lastCanvasWidth) * 150.0).floorToDouble().clamp(0, 149),
                                  ((tapPos.dy / _lastCanvasHeight) * 150.0).floorToDouble().clamp(0, 149),
                                )],
                                color: _selectedColor,
                                width: -99.0,
                              );
                              setState(() {
                                _userLines.add(fillLine);
                              });
                              _updateUserFilledPoints(_lastCanvasWidth, _lastCanvasHeight);
                              AudioService().playAchievement();
                              return;
                            }

                            setState(() {
                              _currentLine = DrawnLine(
                                points: [details.localPosition],
                                color: _selectedColor,
                                width: _brushWidth,
                              );
                              _userLines.add(_currentLine!);
                            });
                            AudioService().playClick();
                          },
                          onPanUpdate: _drawingSubmitted ? null : (details) {
                            if (_isBucketMode) return;
                            setState(() {
                              _currentLine?.points.add(details.localPosition);
                            });
                          },
                          onPanEnd: _drawingSubmitted ? null : (details) {
                            if (_isBucketMode) return;
                            setState(() {
                              _currentLine = null;
                            });
                            _updateUserFilledPoints(_lastCanvasWidth, _lastCanvasHeight);
                          },
                          child: CustomPaint(
                            painter: DrawingPainter(
                              lines: _userLines,
                              filledPoints: _userFilledPoints,
                              backgroundColor: Colors.grey.shade50,
                            ),
                            size: Size.infinite,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: crayonColors.map((color) {
                          final isSelected = _selectedColor == color;
                          return GestureDetector(
                            onTap: _drawingSubmitted ? null : () => setState(() => _selectedColor = color),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 12),
                              width: isSelected ? 44 : 36,
                              height: isSelected ? 44 : 36,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(color: isSelected ? Colors.black : Colors.grey.shade200, width: isSelected ? 3 : 1),
                                boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 6)] : [],
                              ),
                              child: color == Colors.white
                                  ? const Center(child: Icon(Icons.cleaning_services, size: 18, color: Colors.grey))
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.brush, color: !_isBucketMode ? Colors.blueAccent : Colors.grey),
                              onPressed: _drawingSubmitted ? null : () {
                                AudioService().playClick();
                                setState(() {
                                  _isBucketMode = false;
                                });
                              },
                              tooltip: 'Mode Kuas',
                            ),
                            IconButton(
                              icon: Icon(Icons.format_color_fill, color: _isBucketMode ? Colors.blueAccent : Colors.grey),
                              onPressed: _drawingSubmitted ? null : () {
                                AudioService().playClick();
                                setState(() {
                                  _isBucketMode = true;
                                });
                              },
                              tooltip: 'Mode Ember Cat',
                            ),
                            const SizedBox(width: 8),
                            if (!_isBucketMode) ...[
                              const Icon(Icons.line_weight, color: Colors.grey, size: 20),
                              Slider(
                                value: _brushWidth,
                                min: 3.0,
                                max: 15.0,
                                activeColor: Colors.blueAccent,
                                onChanged: _drawingSubmitted ? null : (val) {
                                  setState(() {
                                    _brushWidth = val;
                                  });
                                },
                              ),
                            ] else
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  'Mode Ember Cat Aktif 🪣',
                                  style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.undo, color: Colors.grey),
                              onPressed: _drawingSubmitted ? null : () {
                                if (_userLines.isNotEmpty) {
                                  setState(() => _userLines.removeLast());
                                  _updateUserFilledPoints(_lastCanvasWidth, _lastCanvasHeight);
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
                              onPressed: _drawingSubmitted ? null : () {
                                setState(() => _userLines = []);
                                _updateUserFilledPoints(_lastCanvasWidth, _lastCanvasHeight);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_drawingSubmitted)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 4))
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 64),
                      const SizedBox(height: 16),
                      const Text(
                        'Gambar Terkirim! 🎨',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Menunggu pemain lain menyelesaikan gambar mereka...',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                      const SizedBox(height: 20),
                      const CircularProgressIndicator(color: Colors.blueAccent),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVotingView() {
    final appState = context.read<AppState>();
    final bool isOnline = _selectedMode == SpeedDrawMode.player;
    
    // Determine active artist data
    String currentArtistName = '';
    List<DrawnLine> currentDrawingLines = [];
    Color artistThemeColor = Colors.blue;
    String targetUid = '';
    bool isOwnDrawing = false;

    if (isOnline) {
      final player = _onlinePlayers[_votingIndex];
      targetUid = player['uid'];
      isOwnDrawing = targetUid == appState.uid;
      currentArtistName = isOwnDrawing ? 'Karyamu 🧒' : player['name'];
      currentDrawingLines = isOwnDrawing ? _userLines : deserializeLines(player['lines'] ?? []);
      artistThemeColor = isOwnDrawing ? Colors.blue : Colors.orange;
    } else {
      isOwnDrawing = _votingIndex == 3;
      currentArtistName = isOwnDrawing ? 'Karyamu 🧒' : _botOpponents[_votingIndex]['name'];
      currentDrawingLines = isOwnDrawing ? _userLines : _botOpponents[_votingIndex]['lines'];
      artistThemeColor = isOwnDrawing ? Colors.blue : _botOpponents[_votingIndex]['color'];
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text('FASE VOTING 🗳️', style: AppTheme.heading3.copyWith(color: Colors.white)),
        centerTitle: true,
        actions: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
              child: Text('Next: $_timeLeft s', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 12),
              Text('Menggambar "${_currentPrompt['text']}"', style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: artistThemeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: artistThemeColor.withOpacity(0.5)),
                ),
                child: Text(currentArtistName, style: TextStyle(color: artistThemeColor, fontWeight: FontWeight.w900, fontSize: 16)),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15)]),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final w = constraints.maxWidth;
                        final h = constraints.maxHeight;
                        final fills = computeFilledGridPoints(currentDrawingLines, w, h);
                        return CustomPaint(
                          painter: DrawingPainter(
                            lines: currentDrawingLines,
                            filledPoints: fills,
                            backgroundColor: Colors.white,
                          ),
                          size: Size.infinite,
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: const BoxDecoration(
                  color: Color(0xFF0F172A),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                ),
                child: isOwnDrawing
                    ? _buildPlayerRevealingVoteSection()
                    : _buildVoteRatingSelectorSection(isOnline, targetUid),
              ),
            ],
          ),
          ..._floatingEmojis.map((fe) {
            return Positioned(
              left: fe.x,
              top: fe.y,
              child: Opacity(opacity: fe.opacity, child: Text(fe.emoji, style: const TextStyle(fontSize: 32))),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildVoteRatingSelectorSection(bool isOnline, String targetUid) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Beri Penilaianmu!', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            int starVal = index + 1;
            bool isHighlighted = starVal <= _selectedVoteStars;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedVoteStars = starVal);
                AudioService().playClick();
              },
              child: Icon(
                isHighlighted ? Icons.star_rounded : Icons.star_outline_rounded,
                color: isHighlighted ? Colors.amber : Colors.white24,
                size: 48,
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              if (isOnline) {
                _submitOnlineVote(targetUid);
              } else {
                _nextBotVotingStep();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('SUBMIT VOTE 👍', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerRevealingVoteSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
          child: Text('Lobby sedang menilai gambarmu...', style: TextStyle(color: Colors.greenAccent, fontSize: 14, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 16),
        Container(
          height: 90,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
          child: _voteLogs.isEmpty
              ? const Center(child: Text('Menunggu penilaian...', style: TextStyle(color: Colors.grey, fontSize: 13)))
              : ListView.builder(
                  itemCount: _voteLogs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(_voteLogs[index], style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildResultsView() {
    final playerRank = _standings.indexWhere((r) => r['isPlayer'] == true) + 1;
    String rankEmoji = playerRank == 1 ? '🏆' : (playerRank == 2 ? '🥈' : '🥉');

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text('HASIL PERTANDINGAN 🏁', style: TextStyle(color: Colors.blueAccent, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(
                playerRank == 1 ? 'Juara 1! Luar Biasa! $rankEmoji' : 'Peringkat #$playerRank! $rankEmoji',
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: _standings.length,
                  itemBuilder: (context, index) {
                    final item = _standings[index];
                    final rank = index + 1;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: item['isPlayer'] ? Colors.blue.shade900.withOpacity(0.4) : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: item['isPlayer'] ? Colors.blue : Colors.white.withOpacity(0.1), width: item['isPlayer'] ? 2 : 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(color: rank == 1 ? Colors.amber : (rank == 2 ? Colors.grey : Colors.brown.shade400), shape: BoxShape.circle),
                            child: Center(
                              child: Text(
                                rank.toString(),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(item['avatar'], style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item['name'],
                              style: TextStyle(color: Colors.white, fontWeight: item['isPlayer'] ? FontWeight.w900 : FontWeight.w600, fontSize: 15),
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                              const SizedBox(width: 4),
                              Text('${item['score']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Container(
                height: 110,
                width: 110,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10)]),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final w = constraints.maxWidth;
                      final h = constraints.maxHeight;
                      final fills = computeFilledGridPoints(_userLines, w, h);
                      return CustomPaint(
                        painter: DrawingPainter(
                          lines: _userLines,
                          filledPoints: fills,
                          backgroundColor: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text('Karyamu', style: TextStyle(color: Colors.grey, fontSize: 11)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_selectedMode == SpeedDrawMode.player) {
                            _leaveOnlineRoom();
                          } else {
                            _startBotLobby();
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.1), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        child: const Text('KEMBALI KE LOBBY', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_selectedMode == SpeedDrawMode.player) {
                            _leaveOnlineRoom().then((_) {
                              setState(() {
                                _selectedMode = SpeedDrawMode.player;
                              });
                            });
                          } else {
                            _startBotPrep();
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        child: const Text('MAIN LAGI 🔄', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Online Lobby Matchmaking view (when selected Online, but not yet joined a room) ---

  Widget _buildBotLobbyView() {
    if (_selectedMode == SpeedDrawMode.player) {
      return _buildOnlineMatchmakingView();
    }
    // Default bot lobby
    return _buildBotLobbyLayout();
  }

  Widget _buildOnlineMatchmakingView() {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text('Speed Draw Online 👥', style: AppTheme.heading3),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.gray700),
          onPressed: () => setState(() => _selectedMode = null),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: const Column(
                children: [
                  Text('👥⚡', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 8),
                  Text('Bermain Real-Time dengan Teman', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Gunakan koneksi internet untuk menggambar bersama teman dalam satu room.', style: TextStyle(color: Colors.white70, fontSize: 12), textAlign: TextAlign.center),
                ],
              ),
            ),
            const SizedBox(height: 36),

            // Join Room Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gabung ke Room', style: AppTheme.heading3.copyWith(fontSize: 16)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _roomCodeController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
                    decoration: InputDecoration(
                      hintText: '----',
                      hintStyle: const TextStyle(color: Colors.grey, letterSpacing: 8),
                      counterText: '',
                      filled: true,
                      fillColor: AppTheme.gray50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => _joinOnlineRoom(_roomCodeController.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('GABUNG ROOM', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Center(child: Text('ATAU', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
            const SizedBox(height: 24),

            // Create Room Section
            SizedBox(
              height: 56,
              child: OutlinedButton(
                onPressed: _createOnlineRoom,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.blueAccent, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('BUAT ROOM BARU ➕', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
