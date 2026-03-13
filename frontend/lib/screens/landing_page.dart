import 'package:flutter/material.dart';
import 'auth_screen.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  // Helper method for navigation
  void _navigateToAuth(BuildContext context, bool isLogin) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AuthScreen(startLogin: isLogin),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.code, color: Color(0xFF3B82F6), size: 32),
            SizedBox(width: 12),
            Text(
              "DSA Helper",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => _navigateToAuth(context, true),
            child: const Text("Log In", style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 24.0, top: 8, bottom: 8),
            child: ElevatedButton(
              onPressed: () => _navigateToAuth(context, false),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Sign Up", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 60.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // HERO SECTION
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
                  ),
                  child: const Text(
                    "🚀 The Ultimate Tool for Competitive Programmers",
                    style: TextStyle(color: Color(0xFF60A5FA), fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  "Stop Solving Random Problems.\nStart Leveling Up.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 56, fontWeight: FontWeight.w900, height: 1.1),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 600,
                  child: Text(
                    "Connect your Codeforces handle. Our engine analyzes your submission history, finds your weakest tags, and recommends the exact +100 rated problems you need to reach your target rating.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.grey[400], height: 1.5),
                  ),
                ),
                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: () => _navigateToAuth(context, false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    "Start Analyzing Your Profile",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 80),

                // FEATURES SECTION
                Wrap(
                  spacing: 32,
                  runSpacing: 32,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildFeatureCard(
                      Icons.analytics_outlined,
                      "Deep Weakness Detection",
                      "We calculate your win-rate across all CP tags to find exactly where you are bleeding rating points.",
                    ),
                    _buildFeatureCard(
                      Icons.gps_fixed,
                      "Targeted Problem Sets",
                      "No more guessing. Get 5 custom-picked problems tailored to push you just outside your comfort zone.",
                    ),
                    _buildFeatureCard(
                      Icons.auto_graph,
                      "Track Your Growth",
                      "Visualize your progress with beautiful charts as you clear out your weak topics and climb the ranks.",
                    ),
                  ],
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget for the feature cards
  Widget _buildFeatureCard(IconData icon, String title, String description) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF60A5FA), size: 32),
          ),
          const SizedBox(height: 24),
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(description, style: TextStyle(color: Colors.grey[400], height: 1.5)),
        ],
      ),
    );
  }
}