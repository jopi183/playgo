import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:collection/collection.dart'; 
import 'dart:math' as math;

class Level1Page extends StatefulWidget {
  const Level1Page({super.key});

  @override
  State<Level1Page> createState() => _Level1PageState();
}

class _Level1PageState extends State<Level1Page> with TickerProviderStateMixin {
  bool _isLoading = true;
  int currentQuestionIndex = 0;
  int score = 0;
  final List<bool> answeredCorrectly = List.filled(20, false);
  final List<bool> questionsAnswered = List.filled(20, false);
  bool showReward = false;

  late AnimationController _rewardController;
  late AnimationController _nodeGlowController;
  late AnimationController _confettiController;
  late AnimationController _shakeController;
  late AnimationController _floatingController;
  late Animation<double> _rewardScaleAnimation;
  late Animation<double> _nodeGlowAnimation;
  late Animation<double> _confettiAnimation;
  late Animation<double> _shakeAnimation;
  late Animation<double> _floatingAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeLevel();
  }

  @override
  void dispose() {
    _rewardController.dispose();
    _nodeGlowController.dispose();
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
    _nodeGlowController = AnimationController(
      duration: const Duration(milliseconds: 3000),
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

    _nodeGlowAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _nodeGlowController,
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
      score = prefs.getInt('level1_score') ?? 0;
      for (int i = 0; i < _questions.length; i++) {
        answeredCorrectly[i] =
            prefs.getBool('level1_question_${i}_correct') ?? false;
        questionsAnswered[i] =
            prefs.getBool('level1_question_${i}_answered') ?? false;
      }
    });
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('level1_score', score);
    for (int i = 0; i < _questions.length; i++) {
      await prefs.setBool('level1_question_${i}_correct', answeredCorrectly[i]);
      await prefs.setBool('level1_question_${i}_answered', questionsAnswered[i]);
    }
  }

  void _playSound(bool isCorrect) {
    if (isCorrect) {
      SystemSound.play(SystemSoundType.click);
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  void _onAnswerSelected(bool isCorrect) {
    if (questionsAnswered[currentQuestionIndex]) return;

    setState(() {
      questionsAnswered[currentQuestionIndex] = true;
      if (isCorrect) {
        if (!answeredCorrectly[currentQuestionIndex]) {
          score += 10;
          answeredCorrectly[currentQuestionIndex] = true;
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

      if (currentQuestionIndex == _questions.length - 1) {
        _showCompletionScreen();
      } else {
        setState(() {
          currentQuestionIndex++;
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
              isCorrect ? "BENAR! +10 poin 🎉" : "SALAH! Jangan menyerah! 💪",
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

  void _showCompletionScreen() async{
    int correctAnswers = answeredCorrectly.where((answer) => answer).length;
    double percentage = (correctAnswers / _questions.length) * 100;
    String title;
    String message;
    Color cardColor;
    IconData icon;
      if (percentage >= 60) {
    final prefs = await SharedPreferences.getInstance();
    int currentUnlockedLevel = prefs.getInt('unlocked_level') ?? 1;
    int nextLevel = 2; 

    await prefs.setInt('unlocked_level', math.max(currentUnlockedLevel, nextLevel));
  }


    if (percentage >= 90) {
      title = "LUAR BIASA!";
      message = "Kamu adalah Master Computational Thinking! Sempurna banget!";
      cardColor = Colors.amber;
      icon = Icons.emoji_events;
    } else if (percentage >= 80) {
      title = "HEBAT SEKALI!";
      message = "Pemahaman kamu tentang Computational Thinking sangat bagus!";
      cardColor = Colors.green;
      icon = Icons.star;
    } else if (percentage >= 70) {
      title = "BAGUS!";
      message = "Kamu sudah menguasai dasar-dasar Computational Thinking!";
      cardColor = Colors.blue;
      icon = Icons.thumb_up;
    } else if (percentage >= 60) {
      title = "CUKUP BAIK!";
      message = "Terus belajar, kamu pasti bisa lebih baik lagi!";
      cardColor = Colors.orange;
      icon = Icons.lightbulb;
    } else {
      title = "TETAP SEMANGAT!";
      message = "Computational Thinking memang challenging, jangan menyerah!";
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
                    "Level 1 Selesai!",
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
                              "Jawaban Benar:",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              "$correctAnswers/${_questions.length}",
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
    int correctAnswers = answeredCorrectly.where((answer) => answer).length;
    if ([5, 10, 15, 20].contains(correctAnswers) && correctAnswers > 0) {
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

  void _nextQuestion() {
    if (currentQuestionIndex < _questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
      });
    }
  }

  void _previousQuestion() {
    if (currentQuestionIndex > 0) {
      setState(() {
        currentQuestionIndex--;
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
              Color(0xFF5A4FCF),
              Color(0xFF886AE2),
              Color(0xFFEDE7FF),
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
                    child: _buildQuestionArea(),
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
                    color: Colors.yellow.withOpacity(0.3),
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
                    color: Colors.pink.withOpacity(0.3),
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
                    color: Colors.cyan.withOpacity(0.3),
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
          Expanded(
            child: Column(
              children: const [
                Text(
                  "Level 1",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  "Pengenalan Computational Thinking",
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
                "Soal ${currentQuestionIndex + 1} dari ${_questions.length}",
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
              Text(
                "${answeredCorrectly.where((answer) => answer).length}/${_questions.length} Benar",
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
              value: (currentQuestionIndex + 1) / _questions.length,
              backgroundColor: Colors.white30,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionArea() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: AnimatedBuilder(
        animation: Listenable.merge([_nodeGlowAnimation, _shakeAnimation]),
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(
              _shakeAnimation.value * 10 * math.sin(_shakeAnimation.value * math.pi * 8),
              0,
            ),
            child: Transform.scale(
              scale: _nodeGlowAnimation.value,
              child: Card(
                elevation: 8,
                shadowColor: Colors.purple.withOpacity(0.3),
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
                        Color(0xFF6A5ACD),
                        Color(0xFF9370DB),
                      ],
                    ),
                  ),
                  child: _buildCurrentQuestion(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentQuestion() {
    return QuestionWidget(
      key: ValueKey(currentQuestionIndex),
      question: _questions[currentQuestionIndex],
      onAnswerSelected: _onAnswerSelected,
      isAnswered: questionsAnswered[currentQuestionIndex],
      wasCorrect: answeredCorrectly[currentQuestionIndex],
    );
  }

  Widget _buildNavigationButtons() {
    final isLastQuestion = currentQuestionIndex == _questions.length - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton.icon(
            onPressed: currentQuestionIndex > 0 ? _previousQuestion : null,
            icon: const Icon(Icons.arrow_back),
            label: const Text("Sebelumnya"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.9),
              foregroundColor: const Color(0xFF5A4FCF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
          ElevatedButton.icon(
            onPressed: isLastQuestion
                ? (questionsAnswered[currentQuestionIndex] ? () => _showCompletionScreen() : null)
                : _nextQuestion,
            icon: Icon(isLastQuestion ? Icons.flag : Icons.arrow_forward),
            label: Text(isLastQuestion ? "Selesai" : "Selanjutnya"),
            style: ElevatedButton.styleFrom(
              backgroundColor: isLastQuestion ? Colors.green : Colors.amber,
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
    int correctAnswers = answeredCorrectly.where((answer) => answer).length;
    String rewardText = "Milestone $correctAnswers Soal!";

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
                        Icons.card_giftcard,
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
                        color: Color(0xFF5A4FCF),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Kerja Bagus!",
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

  final List<Question> _questions = [
     Question(
      id: 1,
      title: "🍳 Urutkan langkah 'Siapkan sarapan'",
      type: QuestionType.dragDrop,
      pillarCT: "Algorithm Design",
      icon: "🥞",
      dragItems: [
        "🥘 Siapkan bahan-bahan makanan",
        "🔥 Nyalakan kompor atau alat masak",
        "👨‍🍳 Masak makanan sesuai resep",
        "⏹️ Matikan kompor setelah selesai",
        "🍽️ Sajikan makanan di piring"
      ],
    ),
    Question(
      id: 2,
      title: "🔢 Temukan pola angka",
      type: QuestionType.multipleChoice,
      pillarCT: "Pattern Recognition",
      icon: "🧩",
      question: "Pola: 2, 4, 6, 8, ... Angka selanjutnya adalah?",
      options: ["9", "10", "11", "12"],
      correctAnswer: 1,
    ),
    Question(
      id: 3,
      title: "🎯 Pilih info penting dari teks",
      type: QuestionType.multipleChoice,
      pillarCT: "Abstraction",
      icon: "📝",
      question:
          "Dari teks 'Hari ini cuaca cerah, suhu 25°C, cocok untuk piknik di taman', info penting untuk kegiatan piknik adalah:",
      options: [
        "Hari ini cuaca cerah",
        "Suhu 25°C saja",
        "Cuaca cerah dan suhu 25°C",
        "Cocok untuk piknik"
      ],
      correctAnswer: 2,
    ),
    Question(
      id: 4,
      title: "🚿 Buat algoritma 'Mandi pagi'",
      type: QuestionType.dragDrop,
      pillarCT: "Algorithm Design",
      icon: "🧼",
      dragItems: [
        "🚪 Masuk ke kamar mandi",
        "👕 Lepas pakaian kotor",
        "🚿 Nyalakan shower atau keran air",
        "💧 Basahi tubuh dengan air",
        "🧴 Gunakan sabun dan keramas",
        "🫧 Bilas hingga bersih",
        "🏖️ Keringkan tubuh dengan handuk",
        "👔 Kenakan pakaian bersih"
      ],
    ),
    Question(
      id: 5,
      title: "🌈 Susun warna dari terang ke gelap",
      type: QuestionType.sequenceClick,
      pillarCT: "Pattern Recognition",
      icon: "🎨",
      question:
          "Klik warna sesuai urutan dari yang paling terang ke paling gelap:",
      sequenceItems: ["⚪ Putih", "🟡 Krem", "🔘 Abu-abu", "⚫ Hitam"],
      correctSequence: [0, 1, 2, 3],
    ),
    Question(
      id: 6,
      title: "🧩 Pemecahan masalah yang benar",
      type: QuestionType.multipleChoice,
      pillarCT: "Decomposition",
      icon: "🔨",
      question: "Cara terbaik memecahkan masalah besar adalah:",
      options: [
        "Langsung selesaikan semua",
        "Bagi menjadi bagian kecil",
        "Abaikan yang sulit",
        "Minta bantuan orang lain"
      ],
      correctAnswer: 1,
    ),
    Question(
      id: 7,
      title: "🏠 Algoritma membersihkan kamar",
      type: QuestionType.dragDrop,
      pillarCT: "Algorithm Design",
      icon: "🧹",
      dragItems: [
        "📦 Kumpulkan barang yang berserakan",
        "📚 Susun barang di tempatnya",
        "🪶 Bersihkan debu dari furniture",
        "🛏️ Rapikan tempat tidur",
        "🧹 Sapu atau vacuum lantai",
        "🧽 Pel lantai jika perlu",
      ],
    ),
    Question(
      id: 8,
      title: "💡 Ide utama dari paragraf",
      type: QuestionType.multipleChoice,
      pillarCT: "Abstraction",
      icon: "🎯",
      question:
          "Dari paragraf tentang 'Manfaat olahraga untuk kesehatan jantung, menurunkan berat badan, dan meningkatkan mood', ide utamanya adalah:",
      options: [
        "Kesehatan jantung",
        "Menurunkan berat badan",
        "Manfaat olahraga",
        "Meningkatkan mood"
      ],
      correctAnswer: 2,
    ),
    Question(
      id: 9,
      title: "☕ Algoritma membuat teh hangat",
      type: QuestionType.dragDrop,
      pillarCT: "Algorithm Design",
      icon: "🫖",
      dragItems: [
        "🫖 Siapkan cangkir atau gelas",
        "🔥 Rebus air hingga mendidih",
        "🏷️ Masukkan kantong teh ke cangkir",
        "💧 Tuangkan air panas ke cangkir",
        "⏰ Diamkan selama 3-5 menit",
        "🎣 Angkat kantong teh",
        "🍯 Tambahkan gula jika suka"
      ],
    ),
    Question(
      id: 10,
      title: "🏫 Rute tercepat ke sekolah",
      type: QuestionType.multipleChoice,
      pillarCT: "Decomposition",
      icon: "🗺️",
      question: "Untuk memilih rute tercepat, yang perlu dipertimbangkan:",
      options: [
        "Jarak saja",
        "Kondisi jalan saja",
        "Jarak dan kondisi jalan",
        "Pemandangan terindah"
      ],
      correctAnswer: 2,
    ),
    Question(
      id: 11,
      title: "🎵 Urutan aktivitas bermain musik",
      type: QuestionType.sequenceClick,
      pillarCT: "Algorithm Design",
      icon: "🎸",
      question: "Klik urutan yang benar untuk bermain musik:",
      sequenceItems: [
        "🎸 Ambil alat musik",
        "🪑 Setel posisi duduk",
        "🎶 Mainkan lagu",
        "📦 Simpan alat musik"
      ],
      correctSequence: [0, 1, 2, 3],
    ),
    Question(
      id: 12,
      title: "🚫 Info tidak penting",
      type: QuestionType.multipleChoice,
      pillarCT: "Abstraction",
      icon: "🔍",
      question:
          "Dari instruksi 'Masak nasi dengan air bersih, gunakan panci favorit warna biru, masak 20 menit', info tidak penting adalah:",
      options: [
        "Air bersih",
        "Warna panci biru",
        "Waktu 20 menit",
        "Menggunakan panci"
      ],
      correctAnswer: 1,
    ),
    Question(
      id: 13,
      title: "🍽️ Algoritma mencuci piring",
      type: QuestionType.dragDrop,
      pillarCT: "Algorithm Design",
      icon: "🧽",
      dragItems: [
        "📦 Kumpulkan piring kotor",
        "🧴 Siapkan sabun dan spons",
        "💧 Bilas piring dengan air",
        "🧽 Gosok dengan sabun dan spons",
        "🫧 Bilas hingga bersih",
        "🌬️ Keringkan atau tiriskan"
      ],
    ),
    Question(
      id: 14,
      title: "💻 Menyiapkan komputer",
      type: QuestionType.multipleChoice,
      pillarCT: "Algorithm Design",
      icon: "🖥️",
      question: "Langkah pertama menyiapkan komputer adalah:",
      options: [
        "Buka aplikasi",
        "Colokkan kabel power",
        "Tekan tombol power",
        "Login akun"
      ],
      correctAnswer: 1,
    ),
    Question(
      id: 15,
      title: "📊 Urutan menyiapkan presentasi",
      type: QuestionType.sequenceClick,
      pillarCT: "Algorithm Design",
      icon: "📈",
      question: "Klik urutan yang tepat menyiapkan presentasi:",
      sequenceItems: [
        "📝 Buat outline",
        "📚 Kumpulkan materi",
        "💻 Buat slide",
        "🗣️ Latihan presentasi"
      ],
      correctSequence: [1, 0, 2, 3],
    ),
    Question(
      id: 16,
      title: "📖 Singkatkan instruksi",
      type: QuestionType.multipleChoice,
      pillarCT: "Abstraction",
      icon: "✂️",
      question:
          "Instruksi panjang 'Ambil buku dari tas, buka halaman 50, baca paragraf pertama, tutup buku, simpan di tas' dapat disingkat menjadi:",
      options: [
        "Baca buku halaman 50",
        "Buka halaman 50 saja",
        "Baca paragraf pertama",
        "Buka buku dan baca"
      ],
      correctAnswer: 0,
    ),
    Question(
      id: 17,
      title: "📚 Algoritma belajar untuk ujian",
      type: QuestionType.dragDrop,
      pillarCT: "Algorithm Design",
      icon: "🎓",
      dragItems: [
        "📖 Siapkan materi pelajaran",
        "📅 Buat jadwal belajar",
        "🧠 Baca dan pahami materi",
        "📝 Buat catatan penting",
        "✏️ Latihan soal-soal",
        "🔄 Review materi sulit"
      ],
    ),
    Question(
      id: 18,
      title: "🪑 Alat membersihkan meja",
      type: QuestionType.multipleChoice,
      pillarCT: "Decomposition",
      icon: "🧼",
      question: "Alat yang tepat untuk membersihkan meja kayu:",
      options: [
        "Sapu dan sekop",
        "Kain lap dan pembersih",
        "Sikat dan deterjen",
        "Vacuum cleaner"
      ],
      correctAnswer: 1,
    ),
    Question(
      id: 19,
      title: "🌅 Urutan kegiatan pagi hari",
      type: QuestionType.sequenceClick,
      pillarCT: "Algorithm Design",
      icon: "☀️",
      question: "Klik urutan kegiatan pagi hari yang logis:",
      sequenceItems: [
        "😴 Bangun tidur",
        "🚿 Mandi",
        "🍳 Sarapan",
        "🎒 Berangkat sekolah"
      ],
      correctSequence: [0, 1, 2, 3],
    ),
    Question(
      id: 20,
      title: "📋 Algoritma menyelesaikan tugas",
      type: QuestionType.dragDrop,
      pillarCT: "Algorithm Design",
      icon: "✅",
      dragItems: [
        "📖 Baca dan pahami tugas",
        "🔍 Kumpulkan informasi yang diperlukan",
        "📝 Buat rencana pengerjaan",
        "⚙️ Kerjakan tugas step by step",
        "🔍 Review dan perbaiki hasil",
        "📤 Submit tugas tepat waktu"
      ],
    ),
  ];
}

enum QuestionType {
  multipleChoice,
  dragDrop,
  sequenceClick,
}

class Question {
  final int id;
  final String title;
  final QuestionType type;
  final String pillarCT;
  final String? icon;
  final String? question;
  final List<String>? options;
  final int? correctAnswer;
  final List<String>? dragItems;
  final List<String>? sequenceItems;
  final List<int>? correctSequence;

  Question({
    required this.id,
    required this.title,
    required this.type,
    required this.pillarCT,
    this.icon,
    this.question,
    this.options,
    this.correctAnswer,
    this.dragItems,
    this.sequenceItems,
    this.correctSequence,
  });
}

class QuestionWidget extends StatefulWidget {
  final Question question;
  final Function(bool) onAnswerSelected;
  final bool isAnswered;
  final bool wasCorrect;

  const QuestionWidget({
    super.key,
    required this.question,
    required this.onAnswerSelected,
    required this.isAnswered,
    required this.wasCorrect,
  });

  @override
  State<QuestionWidget> createState() => _QuestionWidgetState();
}

class _QuestionWidgetState extends State<QuestionWidget> with TickerProviderStateMixin {
  List<String>? reorderedItems;
  List<int> sequenceClicked = [];
  int? selectedAnswer;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    if (widget.question.type == QuestionType.dragDrop && widget.question.dragItems != null) {
      reorderedItems = List.from(widget.question.dragItems!)..shuffle();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ## STRUKTUR UTAMA WIDGET SOAL ##
    // Menggunakan Column agar widget tersusun dari atas ke bawah.
    // Expanded di bagian akhir memastikan konten soal (seperti list)
    // bisa di-scroll dan mengisi sisa ruang yang tersedia.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Widget untuk info Pillar CT & Ikon
        _buildPillarInfo(),
        const SizedBox(height: 16),

        // Widget untuk Judul Soal
        Text(
          widget.question.title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),

        // Widget untuk Detail Pertanyaan (jika ada)
        if (widget.question.question != null) ...[
          Text(
            widget.question.question!,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ## PERBAIKAN UTAMA: KONTEN SOAL DIBUNGKUS EXPANDED ##
        // Ini adalah kunci agar area scroll tidak sempit.
        // Expanded akan "memaksa" child-nya (ListView, GridView, dll.)
        // untuk mengisi semua sisa ruang vertikal yang ada di dalam Column.
        Expanded(child: _buildQuestionContent()),

        // Widget untuk Feedback (Benar/Salah) setelah dijawab
        if (widget.isAnswered) _buildFeedback(),
      ],
    );
  }

  Widget _buildPillarInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.15),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(
            _getPillarIcon(widget.question.pillarCT),
            color: Colors.amber,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.question.pillarCT,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _getPillarDescription(widget.question.pillarCT),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          if (widget.question.icon != null)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Text(
                    widget.question.icon!,
                    style: const TextStyle(fontSize: 32),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildQuestionContent() {
    switch (widget.question.type) {
      case QuestionType.multipleChoice:
        return _buildMultipleChoice();
      case QuestionType.dragDrop:
        return _buildDragDrop();
      case QuestionType.sequenceClick:
        return _buildSequenceClick();
    }
  }

  Widget _buildMultipleChoice() {
    return ListView.builder(
      padding: EdgeInsets.zero, // Menghilangkan padding default
      itemCount: widget.question.options?.length ?? 0,
      itemBuilder: (context, index) {
        bool isSelected = selectedAnswer == index;
        bool isCorrect = widget.question.correctAnswer == index;
        bool showResult = widget.isAnswered;

        Color cardColor = Colors.white;
        Color textColor = Colors.grey[800]!;
        if (showResult) {
          if (isCorrect) {
            cardColor = Colors.green;
            textColor = Colors.white;
          } else if (isSelected && !isCorrect) {
            cardColor = Colors.red;
            textColor = Colors.white;
          }
        }

        return Card(
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isSelected && !showResult
              ? const BorderSide(color: Colors.amber, width: 2)
              : BorderSide.none,
          ),
          color: cardColor,
          child: InkWell(
            onTap: widget.isAnswered ? null : () {
              setState(() {
                selectedAnswer = index;
              });
              HapticFeedback.lightImpact();
              widget.onAnswerSelected(index == widget.question.correctAnswer);
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.question.options![index],
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (showResult)
                    Icon(
                      isCorrect ? Icons.check_circle : (isSelected ? Icons.cancel : null),
                      color: Colors.white,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDragDrop() {
    return Column(
      children: [
        // Petunjuk
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: const [
              Icon(Icons.drag_indicator, color: Colors.white70, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Seret untuk mengurutkan",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ## AREA DRAG & DROP YANG SUDAH DIPERBAIKI ##
        // Dibungkus Expanded agar mengisi sisa ruang.
        Expanded(
          child: ReorderableListView.builder(
            itemCount: reorderedItems?.length ?? 0,
            onReorder: widget.isAnswered ? (oldIndex, newIndex) {} : (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex -= 1;
                final String item = reorderedItems!.removeAt(oldIndex);
                reorderedItems!.insert(newIndex, item);
              });
              HapticFeedback.mediumImpact();
            },
            itemBuilder: (context, index) {
              bool isCorrectPosition = false;
              if (widget.isAnswered) {
                isCorrectPosition =
                    reorderedItems![index] == widget.question.dragItems![index];
              }
              Color cardColor = widget.isAnswered
                  ? (isCorrectPosition ? Colors.green : Colors.red)
                  : Colors.white;

              return Card(
                key: ValueKey(reorderedItems![index]),
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 4,
                color: cardColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      color: widget.isAnswered ? Colors.white : Colors.purple,
                      fontSize: 18,
                    ),
                  ),
                  title: Text(
                    reorderedItems![index],
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      color: widget.isAnswered ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: widget.isAnswered
                      ? null
                      : const Icon(Icons.drag_handle, color: Colors.grey),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        if (!widget.isAnswered)
          ElevatedButton.icon(
            onPressed: () {
              widget.onAnswerSelected(_checkDragDropAnswer());
            },
            icon: const Icon(Icons.check_circle_outline),
            label: const Text("Periksa Jawaban"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black87,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSequenceClick() {
    // Implementasi Sequence Click tidak diubah karena sudah baik
    return SingleChildScrollView(
      child: Column(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
            ),
            itemCount: widget.question.sequenceItems?.length ?? 0,
            itemBuilder: (context, index) {
               bool isClicked = sequenceClicked.contains(index);
              int? sequencePosition;
              if (isClicked) {
                sequencePosition = sequenceClicked.indexOf(index) + 1;
              }

              bool isCorrectPosition = false;
              if (widget.isAnswered) {
                int correctIndex = sequenceClicked.indexOf(index);
                if (correctIndex != -1) {
                  isCorrectPosition = widget.question.correctSequence![correctIndex] == index;
                }
              }

              Color cardColor = Colors.white;
              Color textColor = Colors.black87;
              if (widget.isAnswered) {
                  if (isClicked) {
                    cardColor = isCorrectPosition ? Colors.green : Colors.red;
                    textColor = Colors.white;
                  }
              } else if (isClicked) {
                  cardColor = Colors.amber.shade100;
              }

              return Card(
                 elevation: 4,
                 color: cardColor,
                 shape: RoundedRectangleBorder(
                   borderRadius: BorderRadius.circular(16),
                   side: isClicked && !widget.isAnswered ? const BorderSide(color: Colors.amber, width: 2) : BorderSide.none
                 ),
                 child: InkWell(
                  onTap: widget.isAnswered || isClicked ? null : () {
                    setState(() {
                      sequenceClicked.add(index);
                    });
                    if (sequenceClicked.length == widget.question.sequenceItems!.length) {
                      widget.onAnswerSelected(_checkSequenceAnswer());
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        widget.question.sequenceItems![index],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                           fontFamily: 'Poppins',
                           fontSize: 15,
                           color: textColor,
                           fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                 ),
              );
            },
          ),
        ],
      ),
    );
  }

  bool _checkDragDropAnswer() {
    return const DeepCollectionEquality().equals(reorderedItems, widget.question.dragItems);
  }

  bool _checkSequenceAnswer() {
    return const DeepCollectionEquality().equals(sequenceClicked, widget.question.correctSequence);
  }

  Widget _buildFeedback() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.wasCorrect ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        widget.wasCorrect ? "Jawaban Benar! Kerja bagus!" : "Jawaban kurang tepat. Coba lagi di lain waktu!",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: widget.wasCorrect ? Colors.green.shade100 : Colors.red.shade100,
        ),
      ),
    );
  }

  IconData _getPillarIcon(String pillar) {
    switch (pillar) {
      case 'Decomposition': return Icons.scatter_plot;
      case 'Pattern Recognition': return Icons.pattern;
      case 'Abstraction': return Icons.filter_list;
      case 'Algorithm Design': return Icons.account_tree;
      default: return Icons.psychology;
    }
  }

  String _getPillarDescription(String pillar) {
    switch (pillar) {
      case 'Decomposition': return 'Memecah masalah besar';
      case 'Pattern Recognition': return 'Mengenali pola dan keteraturan';
      case 'Abstraction': return 'Fokus pada hal penting';
      case 'Algorithm Design': return 'Membuat langkah sistematis';
      default: return 'Computational Thinking';
    }
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
        Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.purple, Colors.orange,
      ][random.nextInt(6)].withOpacity(1.0 - progress * 0.5);

      final rect = Rect.fromCenter(center: Offset(x, y), width: 8, height: 12);
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}