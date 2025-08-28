import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  bool _emailHasFocus = false;
  bool _sending = false;

  Future<void> _sendReset() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your email")),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      // Success: tell the user and go back to login
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Password reset link sent to $email")),
      );
      Navigator.pop(context); // back to Login
    } on FirebaseAuthException catch (e) {
      String msg = "Failed to send reset link";
      if (e.code == 'invalid-email') msg = "Invalid email format";
      if (e.code == 'user-not-found') msg = "No user found with this email";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0F0F2),
        elevation: 0,
        foregroundColor: const Color(0xFF1F1F39),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Forgot Password",
                    style: TextStyle(
                      fontFamily: "Poppins",
                      fontWeight: FontWeight.w700,
                      fontSize: 32,
                      color: Color(0xFF1F1F39),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Enter your email and we’ll send you a reset link.",
                    style: TextStyle(
                      fontFamily: "Poppins",
                      fontSize: 16,
                      color: Color(0xFF858597),
                    ),
                  ),
                ],
              ),
            ),
            // White rounded container
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Your Email",
                      style: TextStyle(
                        fontFamily: "Poppins",
                        fontWeight: FontWeight.w500,
                        fontSize: 18,
                        color: Color(0xFF858597),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Focus(
                      onFocusChange: (hasFocus) {
                        if (hasFocus != _emailHasFocus) {
                          setState(() => _emailHasFocus = hasFocus);
                        }
                      },
                      child: TextField(
                        controller: emailController,
                        style: const TextStyle(
                          fontFamily: "Poppins",
                          color: Color(0xFF1F1F39),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: _emailHasFocus ? "" : "example@email.com",
                          hintStyle: const TextStyle(
                            fontFamily: "Poppins",
                            color: Color(0xFF858597),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3D5CFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _sending ? null : _sendReset,
                        child: _sending
                            ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                            : const Text(
                          "Send reset link",
                          style: TextStyle(
                            fontFamily: "Poppins",
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
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
}