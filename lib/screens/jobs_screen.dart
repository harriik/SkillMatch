import 'package:flutter/material.dart';
import '../widgets/job_card.dart';
import '../services/auth_service.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  final AuthService _authService = AuthService();
  List<dynamic> _matchedJobs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMatchedJobs();
  }

  Future<void> _loadMatchedJobs() async {
    final analysis = await _authService.getLatestAnalysis();
    if (mounted) {
      setState(() {
        _matchedJobs = analysis?['matched_jobs'] ?? [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Recommended Jobs"),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: _loadMatchedJobs,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _matchedJobs.isEmpty
              ? _buildEmptyState(theme)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  itemCount: _matchedJobs.length,
                  itemBuilder: (context, index) {
                    final job = _matchedJobs[index];
                    return JobCard(
                      role: job['job_title'] ?? "Unknown Role",
                      match: "${job['match_score']}%",
                      company: "Matched Company", // We can add this to the dataset later
                      location: "Remote / On-site",
                      salary: "\$90k - \$140k",
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.work_off_outlined, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          const Text(
            "No recommended jobs yet.",
            style: TextStyle(color: Colors.white60, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            "Upload your resume to see matches.",
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
