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
    // 1. Basic validation
    if (!isLogin && handleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a Codeforces Handle')),
      );
      return;
    }
    if (emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Email and Password')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // 2. Decide if we are hitting /api/login or /api/signup
      final String endpoint = isLogin ? 'login' : 'signup';
      final Uri authUrl = Uri.parse('http://localhost:5000/api/$endpoint');

      // 3. Prepare the data to send to Node.js
      final Map<String, dynamic> requestBody = {
        'email': emailController.text.trim(),
        'password': passwordController.text,
      };
      if (!isLogin) {
        requestBody['codeforcesHandle'] = handleController.text.trim();
      }

      // 4. Send the POST request to your database
      final authResponse = await http.post(
        authUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      final authData = jsonDecode(authResponse.body);

      if (authResponse.statusCode == 200 || authResponse.statusCode == 201) {
        // SUCCESS! The database verified them and gave us their handle
        final String userHandle = authData['handle'];

        // 5. Now fetch their Codeforces stats using that handle!
        final recommendResponse = await http.get(
          Uri.parse('http://localhost:5000/api/recommend/$userHandle'),
        );

        if (recommendResponse.statusCode == 200) {
          final dashboardData = jsonDecode(recommendResponse.body);

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => DashboardScreen(userData: dashboardData),
              ),
            );
          }
        }
      } else {
        // Failed Login/Signup (e.g. wrong password, email already exists)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${authData['error']}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network Error: Check if backend is running. ($e)'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
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
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  isLogin 
                    ? 'Log in to view your targeted problem sets.' 
                    : 'Enter your details to analyze your profile.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
                const SizedBox(height: 32),
                
                // 1. Email (Always visible)
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    hintText: 'Email Address',
                    prefixIcon: Icon(Icons.email_outlined, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 16),
                
                // 2. Password (Always visible)
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Handle (ONLY visible during Sign Up!)
                if (!isLogin) ...[
                  TextField(
                    controller: handleController,
                    decoration: const InputDecoration(
                      hintText: 'Codeforces Handle (e.g. tourist)',
                      prefixIcon: Icon(Icons.person_outline, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                const SizedBox(height: 8),
                
                // 4. Submit Button
                ElevatedButton(
                  onPressed: isLoading ? null : submitForm,
                  child: isLoading 
                    ? const SizedBox(
                        height: 20, 
                        width: 20, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      )
                    : Text(
                        isLogin ? 'Log In' : 'Create Account',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                ),
                const SizedBox(height: 16),
                
                // 5. Toggle State Button
                TextButton(
                  onPressed: () {
                    setState(() {
                      isLogin = !isLogin;
                      // Clear fields when switching modes
                      emailController.clear();
                      passwordController.clear();
                      handleController.clear();
                    });
                  },
                  child: Text(
                    isLogin ? "Don't have an account? Sign Up" : "Already have an account? Log In",
                    style: const TextStyle(color: Colors.grey),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
