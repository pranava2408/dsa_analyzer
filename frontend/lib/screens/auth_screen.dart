import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dashboard_screen.dart'; // Import the new screen

class AuthScreen extends StatefulWidget {
  final bool startLogin; // NEW: Accepts the mode from the Landing Page

  const AuthScreen({super.key, this.startLogin = true});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late bool isLogin; // NEW: Use late initialization
  bool isLoading = false; // Add this line
  @override
  void initState() {
    super.initState();
    isLogin =
        widget.startLogin; // NEW: Set initial state based on what was clicked
  }

  // bool isLogin = true;
  final TextEditingController handleController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> submitForm() async {
    final handle = handleController.text.trim();
    if (handle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your Codeforces Handle')),
      );
      return;
    }

    // Turn on the loading spinner
    setState(() {
      isLoading = true;
    });

    try {
      // 1. Ask the Node.js backend for the data
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/recommend/$handle'),
      );

      if (response.statusCode == 200) {
        // 2. Convert the text response into a Dart Map (JSON)
        final data = jsonDecode(response.body);

        // 3. Navigate to the Dashboard and pass the data
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardScreen(userData: data),
            ),
          );
        }
      } else {
        // Handle backend errors (like a 404 User Not Found)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: Could not find user or analyze profile.'),
            ),
          );
        }
      }
    } catch (e) {
      // Handle network errors (like if your Node server isn't running)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network Error: Make sure backend is running. ($e)'),
          ),
        );
      }
    } finally {
      // Turn off the loading spinner
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 400,
          ), // Keeps it looking like a clean web form
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.code, size: 48, color: Color(0xFF3B82F6)),
                const SizedBox(height: 16),
                Text(
                  isLogin ? 'Welcome Back' : 'Join DSA Helper',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your details to analyze your profile.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
                const SizedBox(height: 32),

                if (!isLogin) ...[
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      hintText: 'Email Address',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(hintText: 'Password'),
                  ),
                  const SizedBox(height: 16),
                ],

                TextField(
                  controller: handleController,
                  decoration: const InputDecoration(
                    hintText: 'Codeforces Handle (e.g. tourist)',
                    prefixIcon: Icon(Icons.person_outline, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: isLoading ? null : submitForm,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          isLogin
                              ? 'Analyze Profile'
                              : 'Create Account & Analyze',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 16),

                TextButton(
                  onPressed: () {
                    setState(() {
                      isLogin = !isLogin;
                    });
                  },
                  child: Text(
                    isLogin
                        ? "Don't have an account? Sign Up"
                        : "Already have an account? Log In",
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
