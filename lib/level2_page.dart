import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

class Level2Page extends StatefulWidget {
  const Level2Page({super.key});

  @override
  State<Level2Page> createState() => _Level2PageState();
}

class _Level2PageState extends State<Level2Page> with TickerProviderStateMixin {
  bool _isLoading = true;
  int currentPuzzleIndex = 0;
  int score = 0;
  final List<bool> puzzlesSolved = List.filled(20, false);
  final List<bool> puzzlesAttempted = List.filled(20, false);
  bool showReward = false;

  late AnimationController _rewardController;
  late AnimationController _pulseController;
  late AnimationController _confettiController;
  late AnimationController _shakeController;
  late AnimationController _floatingController;
  late Animation<double> _rewardScaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _confettiAnimation;
  late Animation<double> _shakeAnimation;
  late Animation<double> _floatingAnimation;

  // Kunci baru untuk SharedPreferences untuk mereset progres lama
  static const String _storageVersion = "_v2";

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeLevel();
  }

  @override
  void dispose() {
    _rewardController.dispose();
    _pulseController.dispose();
    _confettiController.dispose();
    _shakeController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  Future<void> _initializeLevel() async {
    try {
      await _loadProgress();
    } catch (e) {
      debugPrint("Gagal memuat progres: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _setupAnimations() {
    _rewardController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _floatingController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _rewardScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _rewardController,
      curve: Curves.elasticOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _confettiAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _confettiController,
      curve: Curves.easeOut,
    ));

    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticOut,
    ));

    _floatingAnimation = Tween<double>(
      begin: 0.0,
      end: 15.0,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      score = prefs.getInt('level2_score$_storageVersion') ?? 0;
      for (int i = 0; i < _logicPuzzles.length; i++) {
        puzzlesSolved[i] =
            prefs.getBool('level2_puzzle_${i}_solved$_storageVersion') ?? false;
        puzzlesAttempted[i] =
            prefs.getBool('level2_puzzle_${i}_attempted$_storageVersion') ?? false;
      }
    });
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('level2_score$_storageVersion', score);
    for (int i = 0; i < _logicPuzzles.length; i++) {
      await prefs.setBool('level2_puzzle_${i}_solved$_storageVersion', puzzlesSolved[i]);
      await prefs.setBool('level2_puzzle_${i}_attempted$_storageVersion', puzzlesAttempted[i]);
    }
  }

  void _playSound(bool isCorrect) {
    if (isCorrect) {
      SystemSound.play(SystemSoundType.click);
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  void _onPuzzleSolved(bool isCorrect) {
    if (puzzlesAttempted[currentPuzzleIndex]) return;

    setState(() {
      puzzlesAttempted[currentPuzzleIndex] = true;
      if (isCorrect) {
        if (!puzzlesSolved[currentPuzzleIndex]) {
          score += 15;
          puzzlesSolved[currentPuzzleIndex] = true;
        }
        _confettiController.forward(from: 0);
      } else {
        _shakeController.forward(from: 0);
      }
    });

    _playSound(isCorrect);
    _saveProgress();
    _checkMilestone();
    _showFeedback(isCorrect);

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;

      _confettiController.reset();
      _shakeController.reset();

      if (currentPuzzleIndex == _logicPuzzles.length - 1) {
        _showCompletionScreen();
      } else {
        setState(() {
          currentPuzzleIndex++;
        });
      }
    });
  }

  void _showFeedback(bool isCorrect) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isCorrect ? Icons.check_circle : Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              isCorrect ? "BENAR! +15 poin" : "SALAH! Coba lagi!",
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: isCorrect ? Colors.green.shade600 : Colors.red.shade600,
        duration: const Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showCompletionScreen() async {
    int solvedPuzzles = puzzlesSolved.where((solved) => solved).length;
    double percentage = (solvedPuzzles / _logicPuzzles.length) * 100;
    String title;
    String message;
    Color cardColor;
    IconData icon;

    if (percentage >= 70) {
      final prefs = await SharedPreferences.getInstance();
      int currentUnlockedLevel = prefs.getInt('unlocked_level') ?? 1;
      int nextLevel = 3;

      await prefs.setInt('unlocked_level', math.max(currentUnlockedLevel, nextLevel));
    }

    if (percentage >= 90) {
      title = "MASTER LOGIKA!";
      message = "Kamu adalah ahli logika boolean! Sempurna!";
      cardColor = Colors.amber;
      icon = Icons.emoji_events;
    } else if (percentage >= 80) {
      title = "HEBAT SEKALI!";
      message = "Pemahaman logika boolean kamu sangat bagus!";
      cardColor = Colors.green;
      icon = Icons.star;
    } else if (percentage >= 70) {
      title = "BAGUS!";
      message = "Kamu sudah menguasai dasar-dasar logika boolean!";
      cardColor = Colors.blue;
      icon = Icons.thumb_up;
    } else if (percentage >= 60) {
      title = "CUKUP BAIK!";
      message = "Terus berlatih dengan operasi logika!";
      cardColor = Colors.orange;
      icon = Icons.lightbulb;
    } else {
      title = "TETAP SEMANGAT!";
      message = "Logika boolean memang tricky, jangan menyerah!";
      cardColor = Colors.red;
      icon = Icons.favorite;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: cardColor.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: cardColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: cardColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Level 2 Selesai!",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Skor Total:",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              "$score poin",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: cardColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Puzzle Terpecahkan:",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              "$solvedPuzzles/${_logicPuzzles.length}",
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Persentase:",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              "${percentage.toStringAsFixed(0)}%",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: cardColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    message,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cardColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        "Kembali ke Peta",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
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
      },
    );
  }

  void _checkMilestone() {
    int solvedPuzzles = puzzlesSolved.where((solved) => solved).length;
    if ([5, 10, 15, 20].contains(solvedPuzzles) && solvedPuzzles > 0) {
      setState(() {
        showReward = true;
      });
      _rewardController.forward().then((_) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              showReward = false;
            });
            _rewardController.reset();
          }
        });
      });
    }
  }

  void _nextPuzzle() {
    if (currentPuzzleIndex < _logicPuzzles.length - 1) {
      setState(() {
        currentPuzzleIndex++;
      });
    }
  }

  void _previousPuzzle() {
    if (currentPuzzleIndex > 0) {
      setState(() {
        currentPuzzleIndex--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2E7D32),
              Color(0xFF4CAF50),
              Color(0xFFE8F5E8),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              _buildFloatingElements(),
              Column(
                children: [
                  _buildHeader(),
                  _buildProgressBar(),
                  Expanded(
                    child: _buildPuzzleArea(),
                  ),
                  _buildNavigationButtons(),
                ],
              ),
              if (showReward) _buildRewardOverlay(),
              _buildConfetti(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingElements() {
    return AnimatedBuilder(
      animation: _floatingAnimation,
      builder: (context, child) {
        return Positioned.fill(
          child: Stack(
            children: [
              Positioned(
                top: 100 + _floatingAnimation.value,
                left: 50,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                top: 200 - _floatingAnimation.value,
                right: 60,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              Positioned(
                top: 300 + _floatingAnimation.value * 0.5,
                left: 30,
                child: Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const Expanded(
            child: Column(
              children: [
                Text(
                  "Level 2",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  "Logika Kombinasi",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.amber, Colors.orange],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.white, size: 18),
                const SizedBox(width: 4),
                Text(
                  '$score',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Puzzle ${currentPuzzleIndex + 1} dari ${_logicPuzzles.length}",
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
              Text(
                "${puzzlesSolved.where((solved) => solved).length}/${_logicPuzzles.length} Terpecahkan",
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (currentPuzzleIndex + 1) / _logicPuzzles.length,
              backgroundColor: Colors.white30,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPuzzleArea() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseAnimation, _shakeAnimation]),
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(
              _shakeAnimation.value * 10 * math.sin(_shakeAnimation.value * math.pi * 8),
              0,
            ),
            child: Transform.scale(
              scale: _pulseAnimation.value,
              child: Card(
                elevation: 8,
                shadowColor: Colors.green.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF388E3C),
                        Color(0xFF66BB6A),
                      ],
                    ),
                  ),
                  child: _buildCurrentPuzzle(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentPuzzle() {
    return LogicPuzzleWidget(
      key: ValueKey(currentPuzzleIndex),
      puzzle: _logicPuzzles[currentPuzzleIndex],
      onPuzzleSolved: _onPuzzleSolved,
      isAttempted: puzzlesAttempted[currentPuzzleIndex],
      wasSolved: puzzlesSolved[currentPuzzleIndex],
    );
  }

  Widget _buildNavigationButtons() {
    final isLastPuzzle = currentPuzzleIndex == _logicPuzzles.length - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton.icon(
            onPressed: currentPuzzleIndex > 0 ? _previousPuzzle : null,
            icon: const Icon(Icons.arrow_back),
            label: const Text("Sebelumnya"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.9),
              foregroundColor: const Color(0xFF2E7D32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
          ElevatedButton.icon(
            onPressed: isLastPuzzle
                ? (puzzlesAttempted[currentPuzzleIndex] ? () => _showCompletionScreen() : null)
                : _nextPuzzle,
            icon: Icon(isLastPuzzle ? Icons.flag : Icons.arrow_forward),
            label: Text(isLastPuzzle ? "Selesai" : "Selanjutnya"),
            style: ElevatedButton.styleFrom(
              backgroundColor: isLastPuzzle ? Colors.green : Colors.amber,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardOverlay() {
    int solvedPuzzles = puzzlesSolved.where((solved) => solved).length;
    String rewardText = "Milestone $solvedPuzzles Puzzle!";

    return Container(
      color: Colors.black54,
      child: Center(
        child: AnimatedBuilder(
          animation: _rewardScaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _rewardScaleAnimation.value,
              child: Container(
                margin: const EdgeInsets.all(32),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.amber, Colors.orange],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.psychology,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      rewardText,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Logika Keren!",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildConfetti() {
    return AnimatedBuilder(
      animation: _confettiAnimation,
      builder: (context, child) {
        return Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: ConfettiPainter(_confettiAnimation.value),
            ),
          ),
        );
      },
    );
  }

  final List<LogicPuzzle> _logicPuzzles = [
    LogicPuzzle(
      id: 1,
      title: "Gerbang Keamanan Ganda",
      description:
          "Pintu hanya terbuka jika kedua sensor (input 1 & 2) aktif. Dapatkan output TRUE.",
      inputs: [true, true],
      correctOutput: true,
      visualCue: "lock",
    ),
    LogicPuzzle(
      id: 2,
      title: "Sistem Alarm Darurat",
      description:
          "Alarm berbunyi jika salah satu dari dua sensor (input 1 atau 2) mendeteksi bahaya. Dapatkan output TRUE.",
      inputs: [false, true],
      correctOutput: true,
      visualCue: "alarm",
    ),
    LogicPuzzle(
      id: 3,
      title: "Inverter Sinyal",
      description:
          "Sistem membutuhkan sinyal yang berlawanan dari input yang diberikan untuk berfungsi. Dapatkan output TRUE.",
      inputs: [false],
      correctOutput: true,
      visualCue: "signal",
    ),
    LogicPuzzle(
      id: 4,
      title: "Validasi Tiga Tahap",
      description:
          "Sistem memerlukan tiga sinyal positif untuk aktif. Proses dua input pertama, lalu gabungkan hasilnya dengan input ketiga. Dapatkan output TRUE.",
      inputs: [true, true, true],
      correctOutput: true,
      visualCue: "security",
    ),
    LogicPuzzle(
      id: 5,
      title: "Sistem Cadangan (Backup)",
      description:
          "Sistem utama (input 1) mati, tapi sistem cadangan (input 2) aktif. Aktifkan sistem jika salah satunya berjalan. Dapatkan output TRUE.",
      inputs: [false, true],
      correctOutput: true,
      visualCue: "backup",
    ),
    LogicPuzzle(
      id: 6,
      title: "Logika Eksklusif",
      description:
          "Lampu akan menyala jika HANYA SATU dari dua saklar yang aktif, tidak keduanya. Gunakan operator yang tepat. Dapatkan output TRUE.",
      inputs: [true, false],
      correctOutput: true,
      visualCue: "lightbulb",
    ),
    LogicPuzzle(
      id: 7,
      title: "Gerbang Terbalik (NAND)",
      description:
          "Output akan SALAH hanya jika kedua input BENAR. Dapatkan output FALSE.",
      inputs: [true, true],
      correctOutput: false,
      visualCue: "power_off",
    ),
    LogicPuzzle(
      id: 8,
      title: "Kondisi Kompleks 1",
      description:
          "Aktifkan sistem jika (input 1 DAN input 2) BENAR, ATAU input 3 BENAR. Dapatkan output TRUE.",
      inputs: [true, true, false],
      correctOutput: true,
      visualCue: "master_control",
    ),
    LogicPuzzle(
      id: 9,
      title: "Kondisi Kompleks 2",
      description:
          "Sistem aktif jika input 1 TIDAK aktif DAN input 2 aktif. Dapatkan output TRUE.",
      inputs: [false, true],
      correctOutput: true,
      visualCue: "dual_lock",
    ),
    LogicPuzzle(
      id: 10,
      title: "Rangkaian Logika Panjang",
      description:
          "Urutkan operasi: (input 1 OR input 2), lalu hasilnya di-AND-kan dengan input 3. Dapatkan output FALSE.",
      inputs: [true, false, false],
      correctOutput: false,
      visualCue: "network_hub",
    ),
    LogicPuzzle(
      id: 11,
      title: "Pembatalan Keamanan",
      description:
          "Sistem aman jika (sensor 1 AKTIF) ATAU (sensor 2 TIDAK aktif). Dapatkan output TRUE.",
      inputs: [true, true],
      correctOutput: true,
      visualCue: "shield",
    ),
    LogicPuzzle(
      id: 12,
      title: "Logika XOR Bertingkat",
      description:
          "Proses (input 1 XOR input 2), lalu hasilnya di-XOR-kan dengan input 3. Dapatkan output FALSE.",
      inputs: [true, false, true],
      correctOutput: false,
      visualCue: "psychology",
    ),
    LogicPuzzle(
      id: 13,
      title: "Prioritas Operator",
      description:
          "Sistem aktif jika BUKAN (input 1 DAN input 2) yang terjadi. Gunakan gerbang yang sesuai. Dapatkan output FALSE.",
      inputs: [true, true],
      correctOutput: false,
      visualCue: "emergency_override",
    ),
    LogicPuzzle(
      id: 14,
      title: "Filter Sinyal",
      description:
          "Sinyal lolos jika (input 1 DAN input 2) keduanya SALAH. Dapatkan output TRUE.",
      inputs: [false, false],
      correctOutput: true,
      visualCue: "filter_alt",
    ),
    LogicPuzzle(
      id: 15,
      title: "Sistem Kontrol Rudal",
      description:
          "Luncurkan jika (target terkunci (I1) DAN sistem senjata siap (I2)) ATAU ada perintah manual (I3). Dapatkan output TRUE.",
      inputs: [true, false, true],
      correctOutput: true,
      visualCue: "rocket_launch",
    ),
    LogicPuzzle(
      id: 16,
      title: "AI Decision Core",
      description:
          "AI memilih tindakan A jika (data 1 XOR data 2) adalah BENAR. Dapatkan output TRUE.",
      inputs: [false, true],
      correctOutput: true,
      visualCue: "ai_brain",
    ),
    LogicPuzzle(
      id: 17,
      title: "Enkripsi Data",
      description:
          "Proses enkripsi: (data 1 XOR kunci 1), lalu hasilnya di-AND-kan dengan kunci 2. Dapatkan output FALSE.",
      inputs: [true, false, false],
      correctOutput: false,
      visualCue: "enhanced_encryption",
    ),
    LogicPuzzle(
      id: 18,
      title: "Reaktor Fusi",
      description:
          "Reaktor stabil jika (plasma terkendali (I1)) DAN (suhu di bawah batas (I2 TIDAK aktif)). Dapatkan output TRUE.",
      inputs: [true, false],
      correctOutput: true,
      visualCue: "local_fire_department",
    ),
    LogicPuzzle(
      id: 19,
      title: "Cek Paritas Ganjil",
      description:
          "Output TRUE jika jumlah input TRUE adalah ganjil. Gunakan operasi bertingkat. Dapatkan output TRUE.",
      inputs: [true, true, true],
      correctOutput: true,
      visualCue: "checklist",
    ),
    LogicPuzzle(
      id: 20,
      title: "Tantangan Master Logika",
      description:
          "Evaluasi ekspresi: NOT ( (I1 OR I2) AND (I3 XOR I4) ). Dapatkan output TRUE.",
      inputs: [false, false, true, true],
      correctOutput: true,
      visualCue: "emoji_events",
    ),
  ];
}

class LogicPuzzle {
  final int id;
  final String title;
  final String description;
  final List<bool> inputs;
  final bool correctOutput;
  final String visualCue;

  LogicPuzzle({
    required this.id,
    required this.title,
    required this.description,
    required this.inputs,
    required this.correctOutput,
    required this.visualCue,
  });
}

class LogicPuzzleWidget extends StatefulWidget {
  final LogicPuzzle puzzle;
  final Function(bool) onPuzzleSolved;
  final bool isAttempted;
  final bool wasSolved;

  const LogicPuzzleWidget({
    super.key,
    required this.puzzle,
    required this.onPuzzleSolved,
    required this.isAttempted,
    required this.wasSolved,
  });

  @override
  State<LogicPuzzleWidget> createState() => _LogicPuzzleWidgetState();
}

class _LogicPuzzleWidgetState extends State<LogicPuzzleWidget>
    with TickerProviderStateMixin {
  bool? currentOutput;
  List<String> appliedOperators = [];
  final List<String> availableOperators = const [
    'AND',
    'OR',
    'NOT',
    'XOR',
  ];

  late AnimationController _pulseController;
  late AnimationController _glowController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _onOperatorTapped(String operator) {
    setState(() {
      appliedOperators.add(operator);
      _calculateOutput();
    });
    HapticFeedback.lightImpact();
  }

  void _undoLastOperation() {
    if (appliedOperators.isNotEmpty) {
      setState(() {
        appliedOperators.removeLast();
        _calculateOutput();
      });
      HapticFeedback.mediumImpact();
    }
  }

  void _calculateOutput() {
    List<bool> inputs = List.from(widget.puzzle.inputs);
    if (inputs.isEmpty) {
      setState(() => currentOutput = null);
      return;
    }

    bool runningTotal = inputs.removeAt(0);
    int inputIndex = 0;

    for (String op in appliedOperators) {
      if (op == "NOT") {
        runningTotal = !runningTotal;
      } else {
        if (inputIndex < inputs.length) {
          bool nextOperand = inputs[inputIndex];
          inputIndex++;

          switch (op) {
            case "AND":
              runningTotal = runningTotal && nextOperand;
              break;
            case "OR":
              runningTotal = runningTotal || nextOperand;
              break;
            case "XOR":
              runningTotal = runningTotal ^ nextOperand;
              break;
          }
        } else {
          setState(() => currentOutput = null);
          return;
        }
      }
    }

    if (inputIndex == inputs.length) {
      setState(() => currentOutput = runningTotal);
    } else {
      setState(() => currentOutput = null);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPuzzleHeader(),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildVisualArea(),
                const SizedBox(height: 20),
                _buildInputArea(),
                const SizedBox(height: 20),
                _buildOperationChain(),
                const SizedBox(height: 20),
                _buildOperatorArea(),
                const SizedBox(height: 20),
                _buildOutputArea(), // Tetap dipanggil tapi isinya kosong
                const SizedBox(height: 16),
                if (!widget.isAttempted) _buildActionButtons(),
              ],
            ),
          ),
        ),
        if (widget.isAttempted) _buildFeedback(),
      ],
    );
  }

  Widget _buildPuzzleHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.15),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getVisualIcon(widget.puzzle.visualCue),
                color: Colors.amber,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.puzzle.title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.puzzle.description,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualArea() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors:
                    currentOutput == widget.puzzle.correctOutput && currentOutput != null
                        ? [Colors.green.shade300, Colors.green.shade600]
                        : [Colors.grey.shade300, Colors.grey.shade500],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (currentOutput == widget.puzzle.correctOutput &&
                          currentOutput != null)
                      ? Colors.green.withOpacity(0.5)
                      : Colors.grey.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _glowAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _glowAnimation.value,
                        child: Icon(
                          _getVisualIcon(widget.puzzle.visualCue),
                          size: 60,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Input Awal:",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: widget.puzzle.inputs.map((value) {
            return Container(
              width: 80,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: value
                      ? [Colors.green.shade400, Colors.green.shade600]
                      : [Colors.red.shade400, Colors.red.shade600],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: value
                        ? Colors.green.withOpacity(0.4)
                        : Colors.red.withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  value ? "TRUE" : "FALSE",
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildOperationChain() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Rangkaian Operasi Anda:",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (appliedOperators.isNotEmpty && !widget.isAttempted)
              IconButton(
                icon: const Icon(Icons.undo, color: Colors.amber),
                onPressed: _undoLastOperation,
                tooltip: "Hapus Operator Terakhir",
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: appliedOperators.isEmpty
              ? const Text(
                  "Pilih operator di bawah...",
                  style:
                      TextStyle(color: Colors.white54, fontStyle: FontStyle.italic),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: appliedOperators
                      .map((op) => Chip(
                            label: Text(op),
                            backgroundColor: Colors.amber.shade300,
                            labelStyle: const TextStyle(
                                fontWeight: FontWeight.bold, color: Colors.black87),
                          ))
                      .toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildOperatorArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Pilih Operator:",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availableOperators.map((operator) {
            return ElevatedButton(
              onPressed: widget.isAttempted ? null : () => _onOperatorTapped(operator),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Colors.white30, width: 1),
                ),
              ),
              child: Text(
                operator,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildOutputArea() {
    // Mengembalikan widget kosong untuk menyembunyikan output
    return const SizedBox.shrink();
  }

  Widget _buildActionButtons() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: currentOutput != null && !widget.isAttempted
            ? () {
                widget.onPuzzleSolved(currentOutput == widget.puzzle.correctOutput);
              }
            : null,
        icon: const Icon(Icons.check_circle_outline),
        label: const Text("Kunci Jawaban"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber,
          foregroundColor: Colors.black87,
          minimumSize: const Size(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedback() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.wasSolved
            ? Colors.green.withOpacity(0.2)
            : Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        widget.wasSolved
            ? "Puzzle Terpecahkan! Logika yang luar biasa!"
            : "Jawaban salah. Coba lagi dengan rangkaian yang berbeda!",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: widget.wasSolved
              ? Colors.green.shade100
              : Colors.red.shade100,
        ),
      ),
    );
  }

  IconData _getVisualIcon(String visualCue) {
    switch (visualCue) {
      case "portal": return Icons.wb_twilight;
      case "led": return Icons.lightbulb;
      case "alarm": return Icons.alarm;
      case "signal": return Icons.signal_cellular_alt;
      case "lock": return Icons.lock;
      case "emergency": return Icons.emergency;
      case "dual_lock": return Icons.lock_outline;
      case "backup": return Icons.backup;
      case "triple_gate": return Icons.network_check;
      case "switch_inverter": return Icons.swap_horiz;
      case "master_control": return Icons.settings_remote;
      case "emergency_override": return Icons.warning;
      case "security_matrix": return Icons.security;
      case "power_grid": return Icons.electrical_services;
      case "defense_system": return Icons.shield;
      case "network_hub": return Icons.hub;
      case "quantum_gate": return Icons.psychology;
      case "ai_brain": return Icons.smart_toy;
      case "space_station": return Icons.rocket_launch;
      case "master_puzzle": return Icons.emoji_events;
      case "power_off": return Icons.power_off;
      case "filter_alt": return Icons.filter_alt_outlined;
      case "enhanced_encryption": return Icons.enhanced_encryption;
      case "local_fire_department": return Icons.local_fire_department;
      case "checklist": return Icons.checklist;
      default: return Icons.device_hub;
    }
  }

  String _getVisualStatus() {
     if (widget.isAttempted) {
      return widget.wasSolved ? "BERHASIL" : "GAGAL";
    }
    return "MENUNGGU JAWABAN";
  }
}

class ConfettiPainter extends CustomPainter {
  final double progress;
  ConfettiPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;
    final paint = Paint()..style = PaintingStyle.fill;
    final random = math.Random(42);

    for (int i = 0; i < 50; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height * progress - size.height * 0.2;
      paint.color = [
        Colors.red,
        Colors.blue,
        Colors.green,
        Colors.yellow,
        Colors.purple,
        Colors.orange,
      ][random.nextInt(6)]
          .withOpacity(1.0 - progress * 0.5);

      final rect = Rect.fromCenter(center: Offset(x, y), width: 8, height: 12);
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}