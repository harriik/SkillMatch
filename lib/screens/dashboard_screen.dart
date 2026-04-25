import 'package:flutter/material.dart';
import 'resume_upload_screen.dart';
import 'recommendation_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SkillMatch Dashboard"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            Card(
              child: ListTile(
                leading: const Icon(Icons.upload_file),
                title: const Text("Upload Resume"),
                subtitle: const Text("Extract skills automatically"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ResumeUploadScreen()),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            Card(
              child: ListTile(
                leading: const Icon(Icons.work),
                title: const Text("View Job Recommendations"),
                subtitle: const Text("AI-based job role suggestions"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const RecommendationScreen()),
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