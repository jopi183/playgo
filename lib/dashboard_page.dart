import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'login_page.dart'; 

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal logout: $e")),
      );
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: const Color(0xFF2C2C54),
          title: const Text(
            "Konfirmasi Logout",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "Apakah kamu yakin ingin keluar?",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Batal", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.pop(ctx); 
                _signOut(context);
              },
              child: const Text("Ya, Keluar"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF56569A),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Expanded(
                  flex: 3,
                  child: Center(
                    child: Image.asset(
                      "assets/logo.png",
                      width: 500,
                      height: 500,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildMenuButton(
                          text: "Mulai Petualangan",
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6A5B), Color(0xFFE14A1B)],
                          ),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Mulai Petualangan diklik")),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildMenuButton(
                          text: "Tanya Master",
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                          ),
                          onTap: () {},
                        ),
                        const SizedBox(height: 20),
                        _buildMenuButton(
                          text: "Peringkat",
                          gradient: const LinearGradient(
                            colors: [Color(0xFF89F7FE), Color(0xFF66A6FF)],
                          ),
                          onTap: () {},
                        ),
                        const SizedBox(height: 20),
                        _buildMenuButton(
                          text: "Profil",
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF5F6D), Color(0xFFFC466B)],
                          ),
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            Positioned(
              top: 20,
              right: 20,
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: () {
                  _showLogoutDialog(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF512F), Color(0xFFDD2476)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.power_settings_new,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required String text,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: double.infinity,
        height: 55,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
