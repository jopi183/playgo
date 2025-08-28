import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

// Data Model untuk Logic Puzzle (Tidak Berubah)
class LogicPuzzle {
  final int id;
  final String scenario;
  final String codeSnippet;
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String hint;

  LogicPuzzle({
    required this.id,
    required this.scenario,
    required this.codeSnippet,
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    required this.hint,
  });
}

class Level3Page extends StatefulWidget {
  const Level3Page({super.key});

  @override
  State<Level3Page> createState() => _Level3PageState();
}

class _Level3PageState extends State<Level3Page> with TickerProviderStateMixin {
  bool _isLoading = true;
  int currentPuzzleIndex = 0;
  int score = 0;
  final List<bool> puzzlesSolved = List.filled(20, false);
  final List<bool> puzzlesAttempted = List.filled(20, false);
  final List<int?> puzzlesSelectedAnswers = List.filled(20, null);
  bool showReward = false;

  late AnimationController _rewardController;
  late AnimationController _portalController;
  late AnimationController _sparkleController;
  late Animation<double> _rewardScaleAnimation;
  late Animation<double> _portalRotation;
  late Animation<double> _sparkleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeLevel();
  }

  @override
  void dispose() {
    _rewardController.dispose();
    _portalController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  Future<void> _initializeLevel() async {
    try {
      // ## PERBAIKAN 1: Tambahkan fungsi reset untuk memastikan kuis selalu dimulai dari awal.
      await _resetLevelProgress();
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
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _portalController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _rewardScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _rewardController,
      curve: Curves.elasticOut,
    ));

    _portalRotation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _portalController,
      curve: Curves.linear,
    ));

    _sparkleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sparkleController,
      curve: Curves.easeOut,
    ));
  }
  
  // ## PERBAIKAN 1.1: Buat fungsi baru untuk mereset semua data progres Level 3.
  // Fungsi ini akan dipanggil setiap kali halaman dibuka.
  Future<void> _resetLevelProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('level3_score', 0);
    await prefs.setInt('level3_current_puzzle', 0);
    for (int i = 0; i < _logicPuzzles.length; i++) {
      await prefs.setBool('level3_puzzle_${i}_solved', false);
      await prefs.setBool('level3_puzzle_${i}_attempted', false);
      await prefs.setInt('level3_puzzle_${i}_answer', -1); // -1 menandakan null
    }
  }


  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      score = prefs.getInt('level3_score') ?? 0;
      currentPuzzleIndex = prefs.getInt('level3_current_puzzle') ?? 0;
      for (int i = 0; i < _logicPuzzles.length; i++) {
        puzzlesSolved[i] = prefs.getBool('level3_puzzle_${i}_solved') ?? false;
        puzzlesAttempted[i] =
            prefs.getBool('level3_puzzle_${i}_attempted') ?? false;
        final savedAnswer = prefs.getInt('level3_puzzle_${i}_answer');
        puzzlesSelectedAnswers[i] = savedAnswer == -1 ? null : savedAnswer;
      }
    });
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('level3_score', score);
    await prefs.setInt('level3_current_puzzle', currentPuzzleIndex);
    for (int i = 0; i < _logicPuzzles.length; i++) {
      await prefs.setBool('level3_puzzle_${i}_solved', puzzlesSolved[i]);
      await prefs.setBool(
          'level3_puzzle_${i}_attempted', puzzlesAttempted[i]);
      await prefs.setInt(
          'level3_puzzle_${i}_answer', puzzlesSelectedAnswers[i] ?? -1);
    }
  }

  void _onPuzzleSolved(int selectedIndex, bool isCorrect) {
    if (puzzlesAttempted[currentPuzzleIndex]) return;

    setState(() {
      puzzlesAttempted[currentPuzzleIndex] = true;
      puzzlesSelectedAnswers[currentPuzzleIndex] = selectedIndex;
      if (isCorrect) {
        if (!puzzlesSolved[currentPuzzleIndex]) {
          score += 15;
          puzzlesSolved[currentPuzzleIndex] = true;
        }
        _sparkleController.forward(from: 0);
      }
    });

    _playFeedback(isCorrect);
    _saveProgress();
    _checkMilestone();
    _showFeedback(isCorrect);

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      _sparkleController.reset();

      if (isCorrect) {
        if (currentPuzzleIndex == _logicPuzzles.length - 1) {
          _showCompletionScreen();
        } else {
          _nextPuzzle();
        }
      }
    });
  }

  void _playFeedback(bool isCorrect) {
    if (isCorrect) {
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  void _showFeedback(bool isCorrect) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isCorrect ? Icons.emoji_events : Icons.lightbulb_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              isCorrect
                  ? "LOGIKA TEPAT! +15 poin"
                  : "Belum Tepat. Periksa kembali logikanya!",
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor:
            isCorrect ? Colors.green.shade600 : Colors.orange.shade600,
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
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
      int nextLevel = 4;
      await prefs.setInt(
          'unlocked_level', math.max(currentUnlockedLevel, nextLevel));
    }

    if (percentage >= 95) {
      title = "MASTER LOGIKA!";
      message =
          "Kamu menguasai If-Else dengan sempurna! Logika programming kamu luar biasa!";
      cardColor = Colors.purple;
      icon = Icons.psychology;
    } else if (percentage >= 85) {
      title = "LOGIC EXPERT!";
      message =
          "Pemahaman If-Else kamu sangat solid! Siap untuk tantangan berikutnya!";
      cardColor = Colors.indigo;
      icon = Icons.account_tree;
    } else if (percentage >= 75) {
      title = "GREAT LOGICIAN!";
      message = "Kamu sudah memahami dasar-dasar percabangan dengan baik!";
      cardColor = Colors.blue;
      icon = Icons.extension;
    } else if (percentage >= 70) {
      title = "LOGIC LEARNER!";
      message = "Terus berlatih dengan If-Else, kamu pasti akan lebih mahir!";
      cardColor = Colors.teal;
      icon = Icons.school;
    } else {
      title = "KEEP CODING!";
      message =
          "Logika If-Else memang tricky, jangan menyerah terus berlatih!";
      cardColor = Colors.orange;
      icon = Icons.code;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
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
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [cardColor, cardColor.withOpacity(0.8)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
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
                    "Level 3: Percabangan Selesai!",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _buildStatRow("Skor Total:", "$score poin", cardColor),
                        const SizedBox(height: 12),
                        _buildStatRow("Puzzle Terpecahkan:",
                            "$solvedPuzzles/${_logicPuzzles.length}", Colors.green),
                        const SizedBox(height: 12),
                        _buildStatRow("Tingkat Keberhasilan:",
                            "${percentage.toStringAsFixed(0)}%", cardColor),
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
                      height: 1.4,
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
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        "Kembali ke Peta Level",
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

  Widget _buildStatRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  void _checkMilestone() {
    int solvedCount = puzzlesSolved.where((solved) => solved).length;
    if ([5, 10, 15, 20].contains(solvedCount) && solvedCount > 0) {
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
      _saveProgress(); 
    }
  }

  void _previousPuzzle() {
    if (currentPuzzleIndex > 0) {
      setState(() {
        currentPuzzleIndex--;
      });
      _saveProgress();
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
              Color(0xFF2E1065),
              Color(0xFF5B21B6),
              Color(0xFF7C3AED),
              Color(0xFFDDD6FE),
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
              _buildSparkles(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingElements() {
    return AnimatedBuilder(
      animation: _portalRotation,
      builder: (context, child) {
        return Positioned.fill(
          child: Stack(
            children: [
              Positioned(
                top: 80,
                left: 30,
                child: Transform.rotate(
                  angle: _portalRotation.value,
                  child: Container(
                    width: 25,
                    height: 25,
                    decoration: BoxDecoration(
                      color: Colors.cyan.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 150,
                right: 40,
                child: Transform.rotate(
                  angle: -_portalRotation.value,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
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
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const Expanded(
            child: Column(
              children: [
                Text(
                  "Level 3: Logic Puzzles",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  "Percabangan If-Else Interactive",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.purple, Colors.indigo],
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.psychology, color: Colors.white, size: 20),
                const SizedBox(width: 6),
                Text(
                  '$score',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 18,
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
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Puzzle ${currentPuzzleIndex + 1} dari ${_logicPuzzles.length}",
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: Colors.white70,
                ),
              ),
              Text(
                "${puzzlesSolved.where((solved) => solved).length}/${_logicPuzzles.length} Terpecahkan",
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: (currentPuzzleIndex + 1) / _logicPuzzles.length,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple),
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPuzzleArea() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Card(
        elevation: 12,
        shadowColor: Colors.purple.withOpacity(0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6366F1),
                Color(0xFF8B5CF6),
              ],
            ),
          ),
          child: _buildCurrentPuzzle(),
        ),
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
      previouslySelectedAnswer: puzzlesSelectedAnswers[currentPuzzleIndex],
    );
  }

  Widget _buildNavigationButtons() {
    final isLastPuzzle = currentPuzzleIndex == _logicPuzzles.length - 1;

    // ## PERBAIKAN 2: Ubah kondisi untuk mengaktifkan tombol "Lanjut".
    // Tombol aktif jika soal sudah pernah dicoba (puzzlesAttempted), bukan hanya jika benar (puzzlesSolved).
    bool canGoNext = puzzlesAttempted[currentPuzzleIndex] && !isLastPuzzle;
    
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton.icon(
            onPressed: currentPuzzleIndex > 0 ? _previousPuzzle : null,
            icon: const Icon(Icons.arrow_back),
            label: const Text("Sebelumnya"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.9),
              foregroundColor: const Color(0xFF5B21B6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            ),
          ),
          ElevatedButton.icon(
            onPressed: isLastPuzzle && puzzlesAttempted[currentPuzzleIndex]
                ? () => _showCompletionScreen()
                : (canGoNext ? _nextPuzzle : null), // Gunakan kondisi baru di sini
            icon: Icon(isLastPuzzle ? Icons.emoji_events : Icons.arrow_forward),
            label: Text(isLastPuzzle ? "Selesai" : "Lanjut"),
            style: ElevatedButton.styleFrom(
              backgroundColor: isLastPuzzle ? Colors.green : Colors.purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardOverlay() {
    int solvedCount = puzzlesSolved.where((solved) => solved).length;
    String rewardText = "Milestone $solvedCount Puzzle!";

    return Container(
      color: Colors.black54,
      child: Center(
        child: AnimatedBuilder(
          animation: _rewardScaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _rewardScaleAnimation.value,
              child: Container(
                margin: const EdgeInsets.all(40),
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.6),
                      blurRadius: 25,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.purple, Colors.indigo],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.psychology,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      rewardText,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5B21B6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Logic Master!",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
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

  Widget _buildSparkles() {
    return AnimatedBuilder(
      animation: _sparkleAnimation,
      builder: (context, child) {
        return Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: SparklePainter(_sparkleAnimation.value),
            ),
          ),
        );
      },
    );
  }

  final List<LogicPuzzle> _logicPuzzles = [
    LogicPuzzle(
        id: 1,
        scenario: "Sebuah lampu akan menyala jika tombol 'power' ditekan.",
        codeSnippet: "bool isPowerOn = true;\nString lampState = \"Mati\";",
        question: "Pilih kondisi IF yang tepat untuk menyalakan lampu:",
        options: [
          "if (isPowerOn == false)",
          "if (isPowerOn == true)",
          "if (lampState == \"Nyala\")",
          "if (isPowerOn != true)"
        ],
        correctAnswerIndex: 1,
        hint: "Lampu menyala ketika kondisi 'power' adalah 'true'."),
    LogicPuzzle(
        id: 2,
        scenario:
            "Sebuah pintu otomatis akan terbuka jika berat di depannya lebih dari 10 kg.",
        codeSnippet: "int weight = 25;\nString doorStatus = \"Tertutup\";",
        question: "Pilih kondisi IF yang tepat untuk membuka pintu:",
        options: [
          "if (weight < 10)",
          "if (weight == 10)",
          "if (weight > 10)",
          "if (doorStatus == \"Terbuka\")"
        ],
        correctAnswerIndex: 2,
        hint: "Gunakan operator 'lebih besar dari' (>) untuk membandingkan berat."),
    LogicPuzzle(
        id: 3,
        scenario:
            "Sistem AC akan menyala jika suhu ruangan di atas 28°C, jika tidak, AC akan mati.",
        codeSnippet: "int temperature = 30;\nString acStatus;",
        question: "Pilih struktur IF-ELSE yang tepat:",
        options: [
          "if (temperature <= 28) { acStatus = 'Nyala'; } else { acStatus = 'Mati'; }",
          "if (temperature > 28) { acStatus = 'Nyala'; }",
          "if (temperature > 28) { acStatus = 'Nyala'; } else { acStatus = 'Mati'; }",
          "if (temperature < 28) { acStatus = 'Mati'; } else { acStatus = 'Nyala'; }"
        ],
        correctAnswerIndex: 2,
        hint: "Blok 'if' untuk kondisi panas, dan blok 'else' untuk sebaliknya."),
    LogicPuzzle(
        id: 4,
        scenario:
            "Seorang siswa dinyatakan lulus jika nilainya 75 atau lebih. Jika kurang, ia dinyatakan gagal.",
        codeSnippet: "int score = 80;\nString result;",
        question: "Pilih logika IF-ELSE untuk menentukan kelulusan:",
        options: [
          "if (score > 75) { result = 'Lulus'; } else { result = 'Gagal'; }",
          "if (score < 75) { result = 'Lulus'; } else { result = 'Gagal'; }",
          "if (score >= 75) { result = 'Lulus'; } else { result = 'Gagal'; }",
          "if (score <= 75) { result = 'Gagal'; } else { result = 'Lulus'; }"
        ],
        correctAnswerIndex: 2,
        hint: "Ingat, nilai 75 itu sendiri sudah termasuk lulus. Gunakan '>='."),
    LogicPuzzle(
        id: 5,
        scenario:
            "Alarm keamanan akan berbunyi jika sensor gerak aktif DAN saat itu adalah malam hari.",
        codeSnippet:
            "bool motionDetected = true;\nbool isNightTime = true;\nString alarmStatus = \"Mati\";",
        question:
            "Pilih kondisi IF dengan operator AND (&&) yang benar:",
        options: [
          "if (motionDetected == true || isNightTime == true)",
          "if (motionDetected == true && isNightTime == true)",
          "if (motionDetected == false && isNightTime == true)",
          "if (motionDetected == true)"
        ],
        correctAnswerIndex: 1,
        hint: "Operator AND (&&) berarti kedua kondisi harus terpenuhi."),
    LogicPuzzle(
        id: 6,
        scenario:
            "Kamu bisa masuk ke wahana jika tinggimu di atas 140 cm DAN usiamu di atas 12 tahun.",
        codeSnippet: "int height = 150;\nint age = 15;\nbool canEnter;",
        question: "Pilih logika IF yang paling tepat:",
        options: [
          "if (height > 140 || age > 12)",
          "if (height >= 140 && age >= 12)",
          "if (height > 140 && age > 12)",
          "if (height < 140 && age < 12)"
        ],
        correctAnswerIndex: 2,
        hint: "Dua syarat wajib: tinggi 'di atas' 140 DAN usia 'di atas' 12."),
    LogicPuzzle(
        id: 7,
        scenario:
            "Kamu mendapat diskon jika kamu adalah member ATAU total belanjaanmu lebih dari Rp 200.000.",
        codeSnippet:
            "bool isMember = false;\nint totalPurchase = 250000;\nbool hasDiscount;",
        question:
            "Pilih kondisi IF dengan operator OR (||) yang benar:",
        options: [
          "if (isMember == true && totalPurchase > 200000)",
          "if (isMember == false || totalPurchase < 200000)",
          "if (isMember == true || totalPurchase > 200000)",
          "if (isMember == true)"
        ],
        correctAnswerIndex: 2,
        hint: "Operator OR (||) berarti cukup salah satu kondisi terpenuhi."),
    LogicPuzzle(
        id: 8,
        scenario:
            "Lampu darurat akan menyala jika listrik padam ATAU tombol darurat ditekan.",
        codeSnippet:
            "bool isPowerOut = false;\nbool isEmergencyButtonPressed = true;\nString emergencyLight;",
        question: "Pilih logika IF yang paling sesuai:",
        options: [
          "if (isPowerOut == true && isEmergencyButtonPressed == true)",
          "if (isPowerOut == true || isEmergencyButtonPressed == true)",
          "if (isPowerOut == false || isEmergencyButtonPressed == false)",
          "if (isEmergencyButtonPressed == false)"
        ],
        correctAnswerIndex: 1,
        hint: "Salah satu dari dua kejadian ini sudah cukup untuk menyalakan lampu."),
     LogicPuzzle(
      id: 9,
      scenario: "Robot penyiram tanaman akan aktif jika tanahnya kering DAN tidak sedang hujan.",
      codeSnippet: "bool isSoilDry = true;\nbool isRaining = false;\nString sprinklerStatus;",
      question: "Pilih kondisi IF yang paling akurat:",
      options: [
        "if (isSoilDry == true || isRaining == true)",
        "if (isSoilDry == true && isRaining == true)",
        "if (isSoilDry == false && isRaining == false)",
        "if (isSoilDry == true && isRaining == false)"
      ],
      correctAnswerIndex: 3,
      hint: "Robot hanya boleh menyiram saat kering (true) dan tidak hujan (false)."
    ),
    LogicPuzzle(
      id: 10,
      scenario: "Sebuah game memberikan bonus jika pemain mencapai level 10 ATAU memiliki skor di atas 5000.",
      codeSnippet: "int playerLevel = 8;\nint playerScore = 6000;\nbool getBonus;",
      question: "Pilih kondisi IF untuk memberikan bonus:",
      options: [
        "if (playerLevel > 10 && playerScore > 5000)",
        "if (playerLevel >= 10 || playerScore > 5000)",
        "if (playerLevel == 10 && playerScore == 5000)",
        "if (playerLevel < 10 || playerScore < 5000)"
      ],
      correctAnswerIndex: 1,
      hint: "Cukup salah satu pencapaian (level atau skor) untuk mendapatkan bonus."
    ),
    LogicPuzzle(
      id: 11,
      scenario: "Akses ke file rahasia diberikan jika pengguna adalah 'admin' DAN memasukkan password yang benar.",
      codeSnippet: "String userRole = \"admin\";\nbool isPasswordCorrect = true;\nbool grantAccess;",
      question: "Pilih logika IF yang paling aman:",
      options: [
        "if (userRole == \"admin\" || isPasswordCorrect == true)",
        "if (userRole != \"admin\" && isPasswordCorrect == true)",
        "if (userRole == \"admin\" && isPasswordCorrect == true)",
        "if (userRole == \"admin\")"
      ],
      correctAnswerIndex: 2,
      hint: "Keamanan menuntut kedua syarat (peran dan password) harus benar."
    ),
    LogicPuzzle(
      id: 12,
      scenario: "Peringatan cuaca buruk ditampilkan jika kecepatan angin > 70 km/jam ATAU turun hujan lebat.",
      codeSnippet: "int windSpeed = 60;\nbool isHeavyRain = true;\nbool showWarning;",
      question: "Pilih kondisi IF yang tepat untuk peringatan:",
      options: [
        "if (windSpeed > 70 && isHeavyRain == true)",
        "if (windSpeed < 70 || isHeavyRain == false)",
        "if (windSpeed > 70 || isHeavyRain == true)",
        "if (isHeavyRain == false)"
      ],
      correctAnswerIndex: 2,
      hint: "Adanya salah satu kondisi cuaca ekstrem sudah cukup untuk memicu peringatan."
    ),
    LogicPuzzle(
      id: 13,
      scenario: "Seorang karyawan mendapat bonus jika masa kerjanya lebih dari 5 tahun DAN performanya 'Baik'.",
      codeSnippet: "int yearsOfService = 6;\nString performance = \"Baik\";\nbool receiveBonus;",
      question: "Pilih logika IF yang sesuai dengan aturan perusahaan:",
      options: [
        "if (yearsOfService >= 5 && performance == \"Baik\")",
        "if (yearsOfService > 5 || performance == \"Baik\")",
        "if (yearsOfService > 5 && performance == \"Baik\")",
        "if (yearsOfService < 5 && performance != \"Baik\")"
      ],
      correctAnswerIndex: 2,
      hint: "Perhatikan kata 'lebih dari 5 tahun', artinya 5 tahun pas belum termasuk."
    ),
     LogicPuzzle(
      id: 14,
      scenario: "Sistem pengereman darurat mobil aktif jika jarak dengan objek di depan kurang dari 5 meter DAN kecepatan mobil di atas 30 km/jam.",
      codeSnippet: "int distance = 3;\nint speed = 50;\nbool emergencyBrake;",
      question: "Pilih kondisi IF untuk mengaktifkan rem darurat:",
      options: [
        "if (distance < 5 || speed > 30)",
        "if (distance > 5 && speed < 30)",
        "if (distance <= 5 || speed >= 30)",
        "if (distance < 5 && speed > 30)"
      ],
      correctAnswerIndex: 3,
      hint: "Rem darurat hanya aktif jika kedua kondisi berbahaya (jarak dekat dan kecepatan tinggi) terpenuhi bersamaan."
    ),
    LogicPuzzle(
      id: 15,
      scenario: "Kamu bisa meminjam buku jika kamu adalah anggota perpustakaan DAN tidak punya denda.",
      codeSnippet: "bool isMember = true;\nbool hasFine = false;\nbool canBorrow;",
      question: "Pilih logika IF yang benar:",
      options: [
        "if (isMember == true && hasFine == true)",
        "if (isMember == true && hasFine == false)",
        "if (isMember == false || hasFine == true)",
        "if (isMember == true || hasFine == false)"
      ],
      correctAnswerIndex: 1,
      hint: "Untuk bisa meminjam, status keanggotaan harus 'true' dan status denda harus 'false'."
    ),
    LogicPuzzle(
      id: 16,
      scenario: "Sebuah drone akan kembali ke markas jika baterainya di bawah 20% ATAU kehilangan sinyal.",
      codeSnippet: "int batteryLevel = 15;\nbool signalLost = false;\nbool returnToBase;",
      question: "Pilih kondisi IF yang tepat untuk drone kembali:",
      options: [
        "if (batteryLevel < 20 || signalLost == true)",
        "if (batteryLevel > 20 && signalLost == false)",
        "if (batteryLevel < 20 && signalLost == true)",
        "if (batteryLevel >= 20 || signalLost == false)"
      ],
      correctAnswerIndex: 0,
      hint: "Salah satu dari dua kondisi darurat ini (baterai lemah atau sinyal hilang) sudah cukup untuk memicu drone kembali."
    ),
    LogicPuzzle(
      id: 17,
      scenario: "Lampu lalu lintas akan berwarna kuning jika timer_hijau kurang dari 3 detik ATAU ada pejalan kaki menekan tombol.",
      codeSnippet: "int greenTimer = 2;\nbool pedestrianButton = false;\nbool isYellowLight;",
      question: "Pilih logika IF untuk lampu kuning:",
      options: [
          "if (greenTimer < 3 && pedestrianButton == true)",
          "if (greenTimer > 3 || pedestrianButton == false)",
          "if (greenTimer < 3 || pedestrianButton == true)",
          "if (greenTimer == 3)"
      ],
      correctAnswerIndex: 2,
      hint: "Lampu kuning menyala jika salah satu dari dua kondisi ini terpenuhi."
    ),
    LogicPuzzle(
      id: 18,
      scenario: "Filter email akan menandai email sebagai SPAM jika pengirimnya tidak dikenal DAN email mengandung kata 'promo'.",
      codeSnippet: "bool isSenderUnknown = true;\nbool containsPromoWord = true;\nbool markAsSpam;",
      question: "Pilih kondisi IF untuk filter SPAM:",
      options: [
        "if (isSenderUnknown == false || containsPromoWord == false)",
        "if (isSenderUnknown == true || containsPromoWord == true)",
        "if (isSenderUnknown == true && containsPromoWord == false)",
        "if (isSenderUnknown == true && containsPromoWord == true)"
      ],
      correctAnswerIndex: 3,
      hint: "Kedua 'red flag' (pengirim tak dikenal dan kata kunci promo) harus ada untuk menandai sebagai SPAM."
    ),
    LogicPuzzle(
      id: 19,
      scenario: "Mesin kopi akan membuat kopi jika ada cukup air (> 50ml) DAN ada cukup biji kopi (> 10g).",
      codeSnippet: "int waterLevel = 100;\nint coffeeBeanLevel = 5;\nbool makeCoffee;",
      question: "Pilih logika IF yang tepat:",
      options: [
        "if (waterLevel > 50 || coffeeBeanLevel > 10)",
        "if (waterLevel > 50 && coffeeBeanLevel > 10)",
        "if (waterLevel < 50 && coffeeBeanLevel < 10)",
        "if (waterLevel >= 50 && coffeeBeanLevel >= 10)"
      ],
      correctAnswerIndex: 1,
      hint: "Mesin tidak bisa bekerja jika salah satu bahan kurang. Keduanya harus terpenuhi."
    ),
    LogicPuzzle(
      id: 20,
      scenario: "Ponsel akan masuk mode hemat daya jika baterai di bawah 15% DAN tidak sedang diisi daya.",
      codeSnippet: "int battery = 14;\nbool isCharging = false;\nbool powerSavingMode;",
      question: "Pilih kondisi IF untuk mode hemat daya:",
      options: [
        "if (battery < 15 && isCharging == false)",
        "if (battery < 15 || isCharging == false)",
        "if (battery > 15 && isCharging == true)",
        "if (battery < 15 && isCharging == true)"
      ],
      correctAnswerIndex: 0,
      hint: "Mode hemat daya tidak akan aktif jika ponsel sedang diisi daya, meskipun baterainya lemah."
    ),
  ];
}

class LogicPuzzleWidget extends StatefulWidget {
  final LogicPuzzle puzzle;
  final Function(int, bool) onPuzzleSolved;
  final bool isAttempted;
  final bool wasSolved;
  final int? previouslySelectedAnswer;

  const LogicPuzzleWidget({
    super.key,
    required this.puzzle,
    required this.onPuzzleSolved,
    required this.isAttempted,
    required this.wasSolved,
    this.previouslySelectedAnswer,
  });

  @override
  State<LogicPuzzleWidget> createState() => _LogicPuzzleWidgetState();
}

class _LogicPuzzleWidgetState extends State<LogicPuzzleWidget> {
  int? _selectedOptionIndex;

  @override
  void initState() {
    super.initState();
    _selectedOptionIndex = widget.previouslySelectedAnswer;
  }

  // ## PERBAIKAN 3: Pastikan widget diperbarui saat soal berganti
  @override
  void didUpdateWidget(covariant LogicPuzzleWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.puzzle.id != oldWidget.puzzle.id) {
      setState(() {
        _selectedOptionIndex = widget.previouslySelectedAnswer;
      });
    }
  }


  void _handleOptionSelected(int index) {
    if (!widget.isAttempted) {
      setState(() {
        _selectedOptionIndex = index;
      });
      HapticFeedback.lightImpact();
    }
  }

  void _submitAnswer() {
    if (_selectedOptionIndex != null) {
      bool isCorrect =
          _selectedOptionIndex == widget.puzzle.correctAnswerIndex;
      widget.onPuzzleSolved(_selectedOptionIndex!, isCorrect);
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
                _buildCodeSnippet(),
                const SizedBox(height: 16),
                _buildQuestion(),
                const SizedBox(height: 16),
                _buildOptions(),
                const SizedBox(height: 24),
                if (!widget.isAttempted) _buildSolveButton(),
                if (widget.isAttempted) _buildResult(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPuzzleHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description_outlined, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Skenario:",
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.puzzle.scenario,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              color: Colors.white70,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeSnippet() {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo.shade300, width: 1),
      ),
      child: Text(
        widget.puzzle.codeSnippet,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
          color: Colors.white,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildQuestion() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lightbulb_outline,
            color: Colors.amber,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.puzzle.question,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptions() {
    return Column(
      children:
          widget.puzzle.options.asMap().entries.map((entry) {
        int idx = entry.key;
        String text = entry.value;

        Color borderColor = Colors.transparent;
        IconData? trailingIcon;
        Color? iconColor;

        bool isThisTheCorrectAnswer = idx == widget.puzzle.correctAnswerIndex;
        bool isThisTheSelectedAnswer = _selectedOptionIndex == idx;

        if (widget.isAttempted) {
          if (isThisTheCorrectAnswer) {
            borderColor = Colors.green;
            trailingIcon = Icons.check_circle;
            iconColor = Colors.green;
          }
          else if (isThisTheSelectedAnswer && !isThisTheCorrectAnswer) {
            borderColor = Colors.red;
            trailingIcon = Icons.cancel;
            iconColor = Colors.red;
          }
        } else {
          if (isThisTheSelectedAnswer) {
            borderColor = Colors.purple.shade200;
          }
        }

        return GestureDetector(
          onTap: () => _handleOptionSelected(idx),
          child: Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            color: Colors.white.withOpacity(0.15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: borderColor, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      text,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (trailingIcon != null)
                    Icon(trailingIcon, color: iconColor, size: 24),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSolveButton() {
    return ElevatedButton.icon(
      onPressed: _selectedOptionIndex != null ? _submitAnswer : null,
      icon: const Icon(Icons.check),
      label: const Text("Kunci Jawaban"),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 18,
          fontWeight: FontWeight.bold,
        )
      ),
    );
  }

  Widget _buildResult() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.wasSolved
            ? Colors.green.withOpacity(0.2)
            : Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.wasSolved ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            widget.wasSolved ? Icons.check_circle : Icons.cancel,
            color: widget.wasSolved ? Colors.green : Colors.red,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.wasSolved
                  ? "Logika Sempurna! Jawabanmu Tepat!"
                  : "Belum Tepat. Cermati petunjuknya!",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: widget.wasSolved
                    ? Colors.green.shade100
                    : Colors.red.shade100,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter untuk Sparkle Effect (Tidak berubah)
class SparklePainter extends CustomPainter {
  final double progress;
  SparklePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;

    final paint = Paint()..style = PaintingStyle.fill;
    final random = math.Random(123);

    for (int i = 0; i < 30; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height * progress;

      paint.color = [
        Colors.purple,
        Colors.indigo,
        Colors.cyan,
        Colors.pink,
        Colors.amber,
        Colors.white,
      ][random.nextInt(6)]
          .withOpacity(1.0 - progress * 0.7);

      final sparkleSize = 6.0;
      final path = Path();
      path.moveTo(x, y - sparkleSize);
      path.lineTo(x + sparkleSize, y);
      path.lineTo(x, y + sparkleSize);
      path.lineTo(x - sparkleSize, y);
      path.close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}