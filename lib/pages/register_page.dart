import 'package:chat_app/services/auth/auth_service.dart';
import 'package:chat_app/components/my_button.dart';
import 'package:chat_app/components/my_textfield.dart';
import 'package:chat_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RegisterPage extends StatefulWidget {
  final void Function()? onTap;

  const RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool _isObscurepassword = true;
  bool _isObscureConfirm = true;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  void signUp() async {
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Passwords do not match!"),
        ),
      );
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      await authService.signUpWithEmailandPassword(
        emailController.text,
        passwordController.text,
      );
    } catch (e) {
      if (!context.mounted) return;
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
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 500,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Icon
                    const CircleAvatar(
                      radius: 60,
                      backgroundColor: AppTheme.orangeRed,
                      child: Icon(
                        Icons.message,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Heading
                    Text(
                      "Let's create an account for you!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        foreground: Paint()
                          ..shader = const LinearGradient(
                            colors: AppTheme.volcanoColors,
                          ).createShader(const Rect.fromLTWH(0, 0, 200, 50)),
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
                      obscureText: _isObscurepassword,
                      suffixIcon: IconButton(
                        icon: Icon(_isObscurepassword
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () {
                          setState(() {
                            _isObscurepassword = !_isObscurepassword;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Confirm password field
                    MyTextField(
                      controller: confirmPasswordController,
                      hintText: 'Confirm password',
                      obscureText: _isObscureConfirm,
                      suffixIcon: IconButton(
                        icon: Icon(_isObscureConfirm
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () {
                          setState(() {
                            _isObscureConfirm = !_isObscureConfirm;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 25),

                    // Sign Up button
                    MyButton(
                      onTap: signUp,
                      text: "Sign Up",
                    ),
                    const SizedBox(height: 30),

                    // Already a member? Login
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already a member?',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(width: 5),
                        GestureDetector(
                          onTap: widget.onTap,
                          child: const Text(
                            'Login now',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.tomato,
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
