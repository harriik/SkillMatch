import 'package:flutter/material.dart';
import 'skill_gap_screen.dart';
import '../widgets/job_card.dart';

class RecommendationScreen extends StatelessWidget {
  const RecommendationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final jobs = [
      {"role": "Flutter Developer", "match": "85%", "company": "Google Inc.", "location": "Remote"},
      {"role": "Backend Developer", "match": "70%", "company": "Amazon", "location": "Seattle, WA"},
      {"role": "Data Analyst", "match": "60%", "company": "Meta", "location": "Remote"},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Recommendations"),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        itemCount: jobs.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Best Matches for You",
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Based on your profile and resume analysis",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            );
          }
          
          final job = jobs[index - 1];
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SkillGapScreen(role: job["role"]!),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: JobCard(
              role: job["role"]!,
              match: job["match"]!,
              company: job["company"],
              location: job["location"],
            ),
          );
        },
      ),
    );
  }
}
