import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // NEW: For clicking links
import 'auth_screen.dart'; // Needed for logout routing

class DashboardScreen extends StatelessWidget {
  final Map<String, dynamic> userData;

  const DashboardScreen({super.key, required this.userData});

  // --- FEATURE 1: Official Codeforces Colors ---
  Color _getColorForRating(int rating) {
    if (rating == 0) return Colors.white; // Unrated
    if (rating < 1200) return const Color(0xFF808080); // Gray
    if (rating < 1400) return const Color(0xFF008000); // Green
    if (rating < 1600) return const Color(0xFF03A89E); // Cyan
    if (rating < 1900) return const Color(0xFF0000FF); // Blue
    if (rating < 2100) return const Color(0xFFAA00AA); // Purple
    if (rating < 2400) return const Color(0xFFFF8C00); // Orange
    return const Color(0xFFFF0000);                    // Red
  }

  // --- FEATURE 2: Launch Web Links ---
  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $urlString');
    }
  }

  // --- FEATURE 3: Logout Confirmation Dialog ---
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('Log Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: const Text('Are you sure you want to return to the login screen?', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Just close the dialog
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const AuthScreen(startLogin: true)),
                  (Route<dynamic> route) => false, // Clears the history so they can't hit "Back"
                );
              },
              child: const Text('Log Out', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Extracting the data your Node.js server sent
    final String handle = userData['handle'] ?? 'Coder';
    final int rating = userData['currentRating'] ?? 0;
    final String weakestTopic = userData['weakestTopicIdentified'] ?? 'Unknown';
    final List recommendations = userData['recommendations'] ?? [];
    
    // Attempting to get total solved (fallback to 0 if backend doesn't send it yet)
    final int totalSolved = userData['totalSolved'] ?? 0; 
    
    final Color handleColor = _getColorForRating(rating);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Added your dark background back
      appBar: AppBar(
        automaticallyImplyLeading: false, // Hides the default back arrow
        title: Row(
          children: [
            Text(
              handle,
              style: TextStyle(fontWeight: FontWeight.bold, color: handleColor, fontSize: 24),
            ),
            const Text(
              "'s Dashboard",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Log Out',
            onPressed: () => _showLogoutDialog(context), // Triggers the safe dialog
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Header
            Row(
              children: [
                Text(
                  "Current Rating: $rating",
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6)),
                ),
                const SizedBox(width: 32), // Space between the two stats
                Text(
                  "Total Solved: $totalSolved", // --- FEATURE 4: Total Solved ---
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              "Primary Weakness: ${weakestTopic.toUpperCase()}",
              style: const TextStyle(fontSize: 20, color: Colors.orangeAccent),
            ),
            const SizedBox(height: 32),
            
            // Recommendations List
            const Text(
              "Recommended Problems (+100 Rating):",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            
            Expanded(
              child: ListView.builder(
                itemCount: recommendations.length,
                itemBuilder: (context, index) {
                  final problem = recommendations[index];
                  return Card(
                    color: const Color(0xFF1E293B),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(
                        problem['name'], 
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          "Rating: ${problem['rating']}  |  Tags: ${problem['tags'].join(', ')}",
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ),
                      trailing: const Icon(Icons.open_in_new, color: Color(0xFF3B82F6)), // Changed icon to represent a link
                      onTap: () {
                        // --- OPENS THE BROWSER ---
                        if (problem['link'] != null) {
                          _launchUrl(problem['link']);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Error: No link provided for this problem.')),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}