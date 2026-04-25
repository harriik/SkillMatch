import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'jobs_screen.dart';
import 'resume_screen.dart';
import 'profile_screen.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;

  final pages = [
    const Dashboard(),
    const JobsScreen(),
    const ResumeScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: "Home",
          ),
          NavigationDestination(
            icon: Icon(Icons.work_outline_rounded),
            selectedIcon: Icon(Icons.work_rounded),
            label: "Jobs",
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics_rounded),
            label: "ATS Matcher",
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _latestAnalysis;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final analysis = await _authService.getLatestAnalysis();
    if (mounted) {
      setState(() {
        _latestAnalysis = analysis;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: StreamBuilder<DocumentSnapshot>(
        stream: _authService.getUserStream(),
        builder: (context, snapshot) {
          String userName = "User";
          if (snapshot.hasData && snapshot.data!.exists) {
            userName = snapshot.data!.get('name') ?? "User";
          }

          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final List<dynamic> skills = _latestAnalysis?['extracted_skills'] ?? [];
          final List<dynamic> matchedJobs = _latestAnalysis?['matched_jobs'] ?? [];
          final topJob = matchedJobs.isNotEmpty ? matchedJobs[0] : null;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Hello $userName 👋",
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Find your next big opportunity",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                      child: const Icon(Icons.notifications_none_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                // Top Job Match
                Text("Top Job Match", style: theme.textTheme.titleLarge),
                const SizedBox(height: 16),
                if (topJob != null)
                  _buildJobCard(theme, topJob)
                else
                  const Card(child: Padding(padding: EdgeInsets.all(16), child: Text("No matches found yet. Upload a resume to get started!"))),

                const SizedBox(height: 32),
                
                // Skills
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Extracted Skills", style: theme.textTheme.titleLarge),
                    TextButton(onPressed: _loadData, child: const Icon(Icons.refresh, size: 20)),
                  ],
                ),
                const SizedBox(height: 12),
                if (skills.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: skills.map((s) => _buildSkillChip(context, s.toString())).toList(),
                  )
                else
                  const Text("No skills extracted yet.", style: TextStyle(color: Colors.white38)),

                const SizedBox(height: 32),
                Text("Recent Activity", style: theme.textTheme.titleLarge),
                const SizedBox(height: 16),
                _buildActivityItem(context, "Resume Analysis Completed", "Just now", Icons.analytics_rounded),
                _buildActivityItem(context, "Applied to Senior Mobile Engineer", "2 days ago", Icons.send_rounded),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildJobCard(ThemeData theme, dynamic job) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.work_rounded, color: theme.colorScheme.primary, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job['job_title'] ?? "Unknown Role",
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Text("Based on your skills", style: TextStyle(color: Colors.white60, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "${job['match_score']}% Match",
                style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillChip(BuildContext context, String label) {
    return Chip(
      label: Text(label),
      backgroundColor: Theme.of(context).colorScheme.surface,
      side: BorderSide(color: Colors.white.withOpacity(0.1)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _buildActivityItem(BuildContext context, String title, String time, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: Colors.white60),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                Text(time, style: const TextStyle(fontSize: 12, color: Colors.white38)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
