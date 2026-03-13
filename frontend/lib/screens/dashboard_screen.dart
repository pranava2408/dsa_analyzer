import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  // This will hold the JSON data we get from the backend
  final Map<String, dynamic> userData;

  const DashboardScreen({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    // Extracting the data your Node.js server sent
    final String handle = userData['handle'];
    final int rating = userData['currentRating'];
    final String weakestTopic = userData['weakestTopicIdentified'];
    final List recommendations = userData['recommendations'];

    return Scaffold(
      appBar: AppBar(
        title: Text('$handle\'s Dashboard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Header
            Text(
              "Current Rating: $rating",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6)),
            ),
            const SizedBox(height: 8),
            Text(
              "Primary Weakness: ${weakestTopic.toUpperCase()}",
              style: const TextStyle(fontSize: 20, color: Colors.redAccent),
            ),
            const SizedBox(height: 32),
            
            // Recommendations List
            const Text(
              "Recommended Problems (+100 Rating):",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
                      title: Text(problem['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("Rating: ${problem['rating']} | Tags: ${problem['tags'].join(', ')}"),
                      trailing: const Icon(Icons.arrow_forward_ios, color: Color(0xFF3B82F6)),
                      onTap: () {
                        // Later, we will make this open the Codeforces link
                        print("Clicked ${problem['link']}");
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