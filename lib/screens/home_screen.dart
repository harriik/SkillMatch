import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'jobs_screen.dart';
import 'resume_screen.dart';
import 'profile_screen.dart';
import '../services/auth_service.dart';
import '../widgets/job_card.dart';

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
    setState(() => _isLoading = true);
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

          return RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
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
                          Row(
                            children: [
                              Image.asset('assets/icon/logo.png', height: 32, width: 32),
                              const SizedBox(width: 8),
                              Text(
                                "Hello $userName 👋",
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Find your next big opportunity",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("No new notifications")),
                          );
                        },
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.notifications_none_rounded, color: theme.colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  Text("Top Job Match", style: theme.textTheme.titleLarge),
                  const SizedBox(height: 16),
                  if (topJob != null)
                    JobCard(
                      role: topJob['job_title'] ?? "Unknown Role",
                      match: "${topJob['match_score']}% Match",
                      company: "Based on your skills",
                      location: "Remote / On-site",
                    )
                  else
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(Icons.description_outlined, size: 48, color: theme.colorScheme.onSurface.withOpacity(0.1)),
                            const SizedBox(height: 16),
                            Text(
                              "No matches found yet. Upload your resume in the ATS Matcher section!",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 32),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Extracted Skills", style: theme.textTheme.titleLarge),
                      TextButton(onPressed: _loadData, child: const Text("Refresh")),
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
                    Text("No skills extracted yet.", style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.3))),

                  const SizedBox(height: 32),
                  Text("Recent Activity", style: theme.textTheme.titleLarge),
                  const SizedBox(height: 16),
                  if (_latestAnalysis != null)
                    _buildActivityItem(
                      context, 
                      "Resume Analysis Completed", 
                      "Latest analysis ready", 
                      Icons.analytics_rounded,
                      color: theme.colorScheme.primary,
                    )
                  else
                    Text("No recent activity found.", style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.3))),
                  
                  _buildActivityItem(
                    context, 
                    "Joined TalentBridge", 
                    "Account created", 
                    Icons.person_add_rounded,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkillChip(BuildContext context, String label) {
    final theme = Theme.of(context);
    return Chip(
      label: Text(label),
      backgroundColor: theme.colorScheme.surface,
      side: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.1)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _buildActivityItem(BuildContext context, String title, String time, IconData icon, {Color? color}) {
    final theme = Theme.of(context);
    final iconColor = color ?? theme.colorScheme.onSurface.withOpacity(0.6);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1), 
              shape: BoxShape.circle
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                Text(time, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.3))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
