import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'success_page.dart';

class CompletePage extends StatefulWidget {
  final String email;
  final String password;
  const CompletePage({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  State<CompletePage> createState() => _CompletePageState();
}

class _CompletePageState extends State<CompletePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _referralController = TextEditingController();

  bool _loading = false;
  final AuthService _authService = AuthService();

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      UserCredential cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: widget.email,
        password: widget.password,
      );

      User? user = cred.user;

      if (user != null) {
        await _authService.saveUserProfile(
          uid: user.uid,
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          phone: _phoneController.text,
          address: _addressController.text,
          referral: _referralController.text.isEmpty
              ? null
              : _referralController.text,
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SuccessPage()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menyimpan: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 30),
            decoration: const BoxDecoration(
              color: Color(0xFF5A57A0),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const Spacer(),
                const Text(
                  "Complete Profile",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    _buildField("First Name", _firstNameController,
                        icon: Icons.person),
                    _buildField("Last Name", _lastNameController,
                        icon: Icons.person_outline),
                    _buildField("Phone number", _phoneController,
                        type: TextInputType.phone, icon: Icons.phone_android),
                    _buildField("Address", _addressController,
                        icon: Icons.location_on),
                    _buildField("Referral code (optional)", _referralController,
                        required: false, icon: Icons.card_giftcard),

                    const SizedBox(height: 10),
                    const Text(
                      "If you fill this referral code, you can get points that can be changed for compensation",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(height: 30),

                    ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Sign Up",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "By continuing your confirm that you agree with our Term and Condition",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    bool required = true,
    TextInputType type = TextInputType.text,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        validator: (value) {
          if (required && (value == null || value.isEmpty)) {
            return "$label tidak boleh kosong";
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
