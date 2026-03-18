import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dashboard_screen.dart'; // Import the new screen

class AuthScreen extends StatefulWidget {
  final bool startLogin; // Accepts the mode from the Landing Page

  const AuthScreen({super.key, this.startLogin = true});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late bool isLogin;
  bool isLoading = false;

  // --- NEW: Password Visibility State ---
  bool isPasswordVisible = false;

  // --- OTP Variables ---
  bool isOtpMode = false;
  final TextEditingController otpController = TextEditingController();

  final TextEditingController handleController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    isLogin = widget.startLogin;
  }

  Future<void> submitForm() async {
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
      final String baseUrl = 'https://dsa-analyzer-9zt3.onrender.com';
      // final String baseUrl =
      //     'http://127.0.0.1:5000'; // Kept as local for your testing!
      final String endpoint = isLogin ? 'login' : 'signup';
      final Uri authUrl = Uri.parse('$baseUrl/api/$endpoint');

      final Map<String, dynamic> requestBody = {
        'email': emailController.text.trim(),
        'password': passwordController.text,
      };
      if (!isLogin) {
        requestBody['codeforcesHandle'] = handleController.text.trim();
      }

      final authResponse = await http.post(
        authUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      final authData = jsonDecode(authResponse.body);

      if (authResponse.statusCode == 200 || authResponse.statusCode == 201) {
        if (authData['requireOtp'] == true) {
          if (mounted) {
            setState(() {
              isOtpMode = true;
              isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  authData['message'] ?? 'Check your email for the OTP!',
                ),
              ),
            );
          }
          return;
        }

        final String userHandle = authData['handle'];
        final recommendResponse = await http.get(
          Uri.parse('$baseUrl/api/analyze/$userHandle'),
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

  Future<void> verifyOtp() async {
    if (otpController.text.trim().length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the 6-digit code')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final String baseUrl = 'https://dsa-analyzer-9zt3.onrender.com';
      // final String baseUrl = 'http://127.0.0.1:5000';

      final verifyResponse = await http.post(
        Uri.parse('$baseUrl/api/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': emailController.text.trim(),
          'otp': otpController.text.trim(),
        }),
      );

      final verifyData = jsonDecode(verifyResponse.body);

      if (verifyResponse.statusCode == 200) {
        final String userHandle = verifyData['handle'];
        final recommendResponse = await http.get(
          Uri.parse('$baseUrl/api/analyze/$userHandle'),
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${verifyData['error']}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Network Error: $e')));
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
          constraints: const BoxConstraints(maxWidth: 400),
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
                  isOtpMode
                      ? 'Verify Your Email'
                      : (isLogin ? 'Welcome Back' : 'Join DSA Helper'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isOtpMode
                      ? 'Enter the 6-digit code sent to ${emailController.text}'
                      : (isLogin
                            ? 'Log in to view your targeted problem sets.'
                            : 'Enter your details to analyze your profile.'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
                const SizedBox(height: 32),

                if (isOtpMode) ...[
                  TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, letterSpacing: 8),
                    decoration: const InputDecoration(
                      hintText: '000000',
                      counterText: "",
                      prefixIcon: Icon(Icons.security, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: isLoading ? null : verifyOtp,
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Verify Email',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        isOtpMode = false;
                        otpController.clear();
                      });
                    },
                    child: const Text(
                      "Go Back",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ] else ...[
                  // 1. Email
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      hintText: 'Email Address',
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Password (UPDATED WITH EYE ICON)
                  TextField(
                    controller: passwordController,
                    obscureText: !isPasswordVisible, // Toggles based on state
                    decoration: InputDecoration(
                      hintText: 'Password',
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: Colors.grey,
                      ),
                      // NEW: The eye icon button
                      suffixIcon: IconButton(
                        icon: Icon(
                          isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            isPasswordVisible =
                                !isPasswordVisible; // Flips the state
                          });
                        },
                      ),
                    ),
                  ),

                  // --- NEW: Forgot Password Placeholder (Only visible in Login mode) ---
                  if (isLogin)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Forgot Password feature coming in the next update!',
                              ),
                            ),
                          );
                        },
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: Colors.blue[400],
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),

                  // Add a little extra spacing if we aren't showing the forgot password button
                  if (!isLogin) const SizedBox(height: 16),

                  // 3. Handle (ONLY visible during Sign Up)
                  if (!isLogin) ...[
                    TextField(
                      controller: handleController,
                      decoration: const InputDecoration(
                        hintText: 'Codeforces Handle (e.g. tourist)',
                        prefixIcon: Icon(
                          Icons.person_outline,
                          color: Colors.grey,
                        ),
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
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            isLogin ? 'Log In' : 'Create Account',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),

                  // 5. Toggle State Button
                  TextButton(
                    onPressed: () {
                      setState(() {
                        isLogin = !isLogin;
                        emailController.clear();
                        passwordController.clear();
                        handleController.clear();
                        isPasswordVisible =
                            false; // Reset eye icon when switching
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
