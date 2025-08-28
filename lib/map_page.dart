import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'level1_page.dart';
import 'level2_page.dart';
import 'level3_page.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final double _itemHeight = 120;
  final double _connectorHeight = 60;
  final double _nodeSize = 70;
  final double _sidePadding = 40;

  int unlockedLevel = 1; 
  final int totalLevels = 20;

  final List<String> levelTitles = [
    "Level 1: Pengenalan Computational Thinking",
    "Level 2: Logika Dasar (AND, OR, NOT)",
    "Level 3: Percabangan (If-Else)",
    "Level 4: Perulangan (For, While)",
    "Level 5: Searching Linear",
    "Level 5: Searching Biner",
    "Level 6: Sorting Bubble",
    "Level 7: Sorting Selection",
    "Level 8:Sorting Insertion",
    "Level 9: Array 1 Dimensi",
    "Level 10: Array 2 Dimensi",
    "Level 11: Manipulasi Karakter",
    "Level 12: Manipulasi String",
    "Level 13: Fungsi & Prosedur",
    "Level 14: Rekursi Dasar",
    "Level 15: Algoritma Greedy Knapsack 0-1",
    "Level 16: Coin Change",
    "Level 17: Stack",
    "Level 18: Queue",
  ];

  @override
  void initState() {
    super.initState();
    _loadUnlockedLevel();
  }

  Future<void> _loadUnlockedLevel() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        unlockedLevel = prefs.getInt('unlocked_level') ?? 1;
      });
    }
  }

  void _showLevelConfirmation(BuildContext context, int level) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.deepPurple.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '⚔️ Level $level siap ditaklukkan!',
          style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Apakah kamu yakin ingin masuk ke Level $level sekarang? Siapkan strategimu!',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Batal',
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              switch (level) {
                case 1:
                  await Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const Level1Page()));
                  break;
                case 2:
                  await Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const Level2Page()));
                case 3:
                  await Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const Level3Page()));
                  break;
                default:
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Level $level belum tersedia.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  break;
              }
              _loadUnlockedLevel();
            },
            child: const Text(
              'Ayo!',
              style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF5A4FCF), Color(0xFF886AE2), Color(0xFFEDE7FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // HEADER
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Peta',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: LinearProgressIndicator(
                    minHeight: 10,
                    value: (unlockedLevel-1) / (totalLevels-1), // Perhitungan progress yang lebih akurat
                    backgroundColor: Colors.white.withOpacity(.25),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Color(0xFFFF9A62)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Progress: ${unlockedLevel-1} / ${totalLevels-1} Level Selesai',
                style: TextStyle(
                  color: Colors.white.withOpacity(.95),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),

              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;

                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 40, top: 8),
                      itemCount: totalLevels * 2 - 1,
                      itemBuilder: (ctx, idx) {
                        if (idx.isEven) {
                          final level = (idx ~/ 2) + 1;
                          final isUnlocked = level <= unlockedLevel;
                          final isLeft = level.isEven;
                          final isMilestone = level % 5 == 0;

                          return SizedBox(
                            height: _itemHeight,
                            child: Stack(
                              children: [
                                Align(
                                  alignment: isLeft
                                      ? Alignment.centerLeft
                                      : Alignment.centerRight,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: _sidePadding,
                                    ),
                                    child: _LevelNode(
                                      level: level,
                                      title: levelTitles[level - 1],
                                      isUnlocked: isUnlocked,
                                      isCurrent: level == unlockedLevel,
                                      isCompleted: level < unlockedLevel,
                                      isLeft: isLeft,
                                      size: _nodeSize,
                                      onTap: isUnlocked
                                          ? () => _showLevelConfirmation(
                                              context, level)
                                          : null,
                                    ),
                                  ),
                                ),
                                if (isMilestone)
                                  Align(
                                    alignment: isLeft
                                        ? Alignment.centerLeft
                                        : Alignment.centerRight,
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        left: isLeft
                                            ? _sidePadding + _nodeSize + 12
                                            : 0,
                                        right: isLeft
                                            ? 0
                                            : _sidePadding + _nodeSize + 12,
                                      ),
                                      child: const _GiftBadge(),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        } else {
                          final currentLevel = (idx ~/ 2) + 1;
                          final fromLeft = currentLevel.isEven;
                          final toLeft = (currentLevel + 1).isEven;

                          return SizedBox(
                            height: _connectorHeight,
                            width: width,
                            child: CustomPaint(
                              painter: _ConnectorPainter(
                                fromLeft: fromLeft,
                                toLeft: toLeft,
                                sidePadding: _sidePadding,
                                nodeSize: _nodeSize,
                                dash: 10,
                                gap: 6,
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelNode extends StatelessWidget {
  final int level;
  final String title;
  final bool isUnlocked;
  final bool isCurrent;
  final bool isCompleted;
  final bool isLeft;
  final double size;
  final VoidCallback? onTap;

  const _LevelNode({
    required this.level,
    required this.title,
    required this.isUnlocked,
    required this.isCurrent,
    required this.isCompleted,
    required this.isLeft,
    required this.size,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (isUnlocked && onTap != null) {
          onTap!();
        } else if (!isUnlocked) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "💀 Level $level terkunci! Selesaikan level sebelumnya dulu, pahlawan!",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.red.shade800,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          // Node
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: isCompleted
                  ? const LinearGradient(
                      colors: [Colors.greenAccent, Colors.green],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : isUnlocked
                      ? (isCurrent
                          ? const LinearGradient(
                              colors: [Colors.orangeAccent, Colors.deepOrange],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : LinearGradient(
                              colors: [Colors.white, Colors.grey.shade300],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ))
                      : LinearGradient(
                          colors: [Colors.grey.shade700, Colors.grey.shade900],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black26, width: 2),
              boxShadow: [
                if (isUnlocked || isCompleted)
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: isCurrent ? 12 : 6,
                    spreadRadius: isCurrent ? 2 : 0,
                    offset: const Offset(0, 3),
                  ),
              ],
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, size: 32, color: Colors.white)
                  : isUnlocked
                      ? Text(
                          '$level',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isCurrent ? Colors.white : Colors.black87,
                          ),
                        )
                      : const Icon(Icons.lock,
                          size: 32, color: Colors.yellowAccent),
            ),
          ),
          const SizedBox(height: 6),

          // Label level
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isUnlocked || isCompleted
                    ? [Colors.purple.shade400, Colors.purple.shade700]
                    : [Colors.grey.shade600, Colors.grey.shade800],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: SizedBox(
              width: 200,
              child: Text(
                title,
                textAlign: isLeft ? TextAlign.left : TextAlign.right,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black45,
                      offset: Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GiftBadge extends StatefulWidget {
  const _GiftBadge();

  @override
  State<_GiftBadge> createState() => _GiftBadgeState();
}

class _GiftBadgeState extends State<_GiftBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: const Icon(
        Icons.card_giftcard,
        color: Colors.amber,
        size: 40,
        shadows: [
          Shadow(
            color: Colors.yellow,
            blurRadius: 8,
            offset: Offset(0, 0),
          ),
        ],
      ),
    );
  }
}

class _ConnectorPainter extends CustomPainter {
  final bool fromLeft;
  final bool toLeft;
  final double sidePadding;
  final double nodeSize;
  final double dash;
  final double gap;

  _ConnectorPainter({
    required this.fromLeft,
    required this.toLeft,
    required this.sidePadding,
    required this.nodeSize,
    required this.dash,
    required this.gap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final fromX = fromLeft
        ? sidePadding + nodeSize / 2
        : size.width - sidePadding - nodeSize / 2;
    final toX = toLeft
        ? sidePadding + nodeSize / 2
        : size.width - sidePadding - nodeSize / 2;

    final path = Path()
      ..moveTo(fromX, 0)
      ..lineTo(toX, size.height);

    // Gambar garis putus-putus
    double distance = 0.0;
    for (final metric in path.computeMetrics()) {
      while (distance < metric.length) {
        final next = distance + dash;
        final extractPath =
            metric.extractPath(distance, next.clamp(0, metric.length));
        canvas.drawPath(extractPath, paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}