import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

final GoogleSignIn _gSignIn = GoogleSignIn();

Future<void> _signInWithGoogle(BuildContext context) async {
  try {
    // Force the account chooser every time
    await _gSignIn.signOut();
    await _gSignIn.disconnect().catchError((_) {});

    final GoogleSignInAccount? googleUser = await _gSignIn.signIn();
    if (googleUser == null) return; // user canceled

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCred =
    await FirebaseAuth.instance.signInWithCredential(credential);


    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  } on FirebaseAuthException catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Google login failed: ${e.message}")),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Something went wrong: $e")),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _emailHasFocus = false;
  bool _passwordHasFocus = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F2),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Top section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Log In",
                    style: TextStyle(
                      fontFamily: "Poppins",
                      fontWeight: FontWeight.w700,
                      fontSize: 35,
                      color: Color(0xFF1F1F39),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Enter your details below to log in",
                    style: TextStyle(
                      fontFamily: "Poppins",
                      fontWeight: FontWeight.w400,
                      fontSize: 17,
                      color: Color(0xFF858597),
                    ),
                  ),
                ],
              ),
            ),

            // 🔹 White rounded container
            Expanded(
              child: Container(
                width: double.infinity,
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 45),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Email
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
                          decoration: InputDecoration(
                            hintText: _emailHasFocus ? "" : "example@email.com",
                            hintStyle: const TextStyle(
                              fontFamily: "Poppins",
                              color: Color(0xFF858597),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Password
                      const Text(
                        "Password",
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
                          if (hasFocus != _passwordHasFocus) {
                            setState(() => _passwordHasFocus = hasFocus);
                          }
                        },
                        child: TextField(
                          controller: passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(
                            fontFamily: "Poppins",
                            color: Color(0xFF1F1F39),
                          ),
                          decoration: InputDecoration(
                            hintText:
                            _passwordHasFocus ? "" : "Enter your password",
                            hintStyle: const TextStyle(
                              fontFamily: "Poppins",
                              color: Color(0xFF858597),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: const Color(0xFF1F1F39),
                              ),
                              onPressed: () {
                                setState(() =>
                                _obscurePassword = !_obscurePassword);
                              },
                            ),
                          ),
                        ),
                      ),

                      // Forgot password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/forgot');
                          },
                          child: const Text(
                            "Forgot password?",
                            style: TextStyle(
                              fontFamily: "Poppins",
                              fontSize: 15,
                              color: Color(0xFF858597),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Log In button
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
                          onPressed: () async {
                            final email = emailController.text.trim();
                            final password = passwordController.text.trim();

                            if (email.isEmpty || password.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("Please fill all fields")),
                              );
                              return;
                            }

                            try {
                              await FirebaseAuth.instance
                                  .signInWithEmailAndPassword(
                                email: email,
                                password: password,
                              );

                              Navigator.pushReplacementNamed(
                                  context, '/home');
                            } on FirebaseAuthException catch (e) {
                              String message = "Login failed";
                              if (e.code == 'user-not-found') {
                                message = "No user found with this email.";
                              } else if (e.code == 'wrong-password') {
                                message = "Incorrect password.";
                              } else if (e.code == 'invalid-email') {
                                message = "Invalid email format.";
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(message)),
                              );
                            }
                          },
                          child: const Text(
                            "Log In",
                            style: TextStyle(
                              fontFamily: "Poppins",
                              fontWeight: FontWeight.w600,
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Don't have an account? Sign up
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don’t have an account? ",
                            style: TextStyle(
                              fontFamily: "Poppins",
                              fontSize: 15,
                              color: Color(0xFF858597),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, '/signup');
                            },
                            child: const Text(
                              "Sign up",
                              style: TextStyle(
                                fontFamily: "Poppins",
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF3D5CFF),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Divider
                      Row(
                        children: const [
                          Expanded(
                              child: Divider(thickness: 1, color: Color(0xFFEEEEEE))),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              "Or login with",
                              style: TextStyle(
                                fontFamily: "Poppins",
                                fontSize: 14,
                                color: Color(0xFF858597),
                              ),
                            ),
                          ),
                          Expanded(
                              child: Divider(thickness: 1, color: Color(0xFFEEEEEE))),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Google login button
                      Center(
                        child: GestureDetector(
                          onTap: () => _signInWithGoogle(context),
                          child: Container(
                            width: 56,
                            height: 56,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border:
                              Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.white,
                            ),
                            child: Image.asset("assets/images/google_icon.png"),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}