import 'package:chat_app/services/auth/auth_service.dart';
import 'package:chat_app/components/my_button.dart';
import 'package:chat_app/components/my_textfield.dart';
import 'package:chat_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  final void Function()? onTap;

  const LoginPage({super.key, required this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isObscure = true;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void signIn() async {
    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      await authService.signInWithEmailandPassword(
        emailController.text,
        passwordController.text,
      );
      // Navigator will be handled by AuthGate automatically
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppTheme.fireBrick,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.volcanoGradient,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 500,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Icon
                    Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black38,
                            blurRadius: 15,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [AppTheme.gold, AppTheme.orangeRed],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.transparent,
                          child: Icon(
                            Icons.chat_bubble,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // App Name
                    Text(
                      "Let's Chat",
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        foreground: Paint()
                          ..shader = const LinearGradient(
                            colors: AppTheme.volcanoColors,
                          ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      "Welcome back, you've been missed!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Email field
                    MyTextField(
                      controller: emailController,
                      hintText: 'Email',
                      obscureText: false,
                    ),
                    const SizedBox(height: 15),

                    // Password field
                    MyTextField(
                      controller: passwordController,
                      hintText: 'Password',
                      obscureText: _isObscure,
                      suffixIcon: IconButton(
                        icon: Icon(_isObscure
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () {
                          setState(() {
                            _isObscure = !_isObscure;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 25),

                    // Sign In button
                    MyButton(
                      onTap: signIn,
                      text: "Sign In",
                    ),
                    const SizedBox(height: 30),

                    // Register link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Not a member?',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(width: 5),
                        GestureDetector(
                          onTap: widget.onTap,
                          child: const Text(
                            'Register now',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.gold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
