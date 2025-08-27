import 'dart:async';
import 'package:flutter/material.dart';
import 'login_page.dart';
import 'dashboard_page.dart';

class SuccessLoginPage extends StatefulWidget {
  final String userName; // 👈 terima nama user

  const SuccessLoginPage({Key? key, required this.userName}) : super(key: key);

  @override
  State<SuccessLoginPage> createState() => _SuccessLoginPageState();
}

class _SuccessLoginPageState extends State<SuccessLoginPage> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardPage()), // 👈 pindah ke dashboard
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF56569A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green[400],
              ),
              padding: const EdgeInsets.all(20),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 80,
              ),
            ),
            const SizedBox(height: 30),
            Text(
              "Login Successful!",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Welcome back, ${widget.userName}.", // 👈 pesan personal
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Enjoy exploring the features!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
