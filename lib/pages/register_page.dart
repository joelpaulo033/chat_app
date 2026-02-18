import 'package:chat_app/services/auth/auth_service.dart';
import 'package:chat_app/components/my_button.dart';
import 'package:chat_app/components/my_textfield.dart';
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

  // Volcano Fire colors
  final List<Color> volcanoColors = [
    const Color(0xFFFF4500), // OrangeRed
    const Color(0xFFFF6347), // Tomato
    const Color(0xFFFF8C00), // DarkOrange
    const Color(0xFFFFD700), // Gold
  ];

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: volcanoColors[0],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: volcanoColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 500, // maximum width for larger screens
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Icon
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: volcanoColors[0],
                      child: const Icon(
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        foreground: Paint()
                          ..shader = LinearGradient(
                            colors:volcanoColors,
                          ).createShader(const Rect.fromLTWH(0, 0, 200, 0)),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Email field
                    MyTextField(
                      controller: emailController,
                      hintText: 'fredymichael@gmail.com',
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
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [volcanoColors[0], volcanoColors[2]],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: MyButton(
                        onTap: signUp,
                        text: "Sign Up",
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Already a member? Login
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already a member?',
                          style: TextStyle(color: Colors.white),
                        ),
                        const SizedBox(width: 5),
                        GestureDetector(
                          onTap: widget.onTap,
                          child: Text(
                            'Login now',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: volcanoColors[3], // Tomato
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
