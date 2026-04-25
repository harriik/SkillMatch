import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'resume_upload_screen.dart';

class ResumeScreen extends StatefulWidget {
  const ResumeScreen({super.key});

  @override
  State<ResumeScreen> createState() => _ResumeScreenState();
}

class _ResumeScreenState extends State<ResumeScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _jdController = TextEditingController();
  bool _isAnalyzing = false;
  
  Map<String, dynamic>? _analysisData;
  double? _matchScore;
  List<dynamic> _matchingSkills = [];
  List<dynamic> _missingSkills = [];

  @override
  void initState() {
    super.initState();
    _loadStoredAnalysis();
  }

  Future<void> _loadStoredAnalysis() async {
    final data = await _authService.getLatestAnalysis();
    if (mounted && data != null) {
      setState(() {
        _analysisData = data;
      });
    }
  }

  void _analyzeJobMatch() async {
    if (_jdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please paste a job description first")),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _matchScore = null;
    });

    try {
      // For the "ATS Matcher" tab, we can use the skills already extracted from the resume
      // and compare them with the pasted JD.
      // For now, let's look for keywords in the JD that match our SKILLS_DB
      final List<dynamic> resumeSkills = _analysisData?['extracted_skills'] ?? [];
      final String jd = _jdController.text.toLowerCase();
      
      // Simulated JD matching logic
      List<String> matching = [];
      List<String> missing = [];

      for (var skill in resumeSkills) {
        if (jd.contains(skill.toString().toLowerCase())) {
          matching.add(skill.toString());
        }
      }

      // Calculate missing from a few hardcoded common JD requirements for simulation
      final commonRequirements = ["Communication", "Teamwork", "Problem Solving", "Agile"];
      for (var req in commonRequirements) {
        if (!jd.contains(req.toLowerCase())) {
          missing.add(req);
        }
      }

      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _isAnalyzing = false;
        _matchingSkills = matching;
        _missingSkills = missing;
        _matchScore = matching.isEmpty ? 0 : (matching.length / (matching.length + 2) * 100).roundToDouble();
      });
    } catch (e) {
      setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("ATS Job Matcher"),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _authService.getUserStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data?.data() as Map<String, dynamic>?;
          final String resumeUrl = userData?['resume_url'] ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildResumeStatusCard(theme, resumeUrl),
                const SizedBox(height: 32),
                
                Text(
                  "ATS Real-time Matcher",
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "Paste any job description to see how your uploaded resume matches.",
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white60),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _jdController,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText: "Paste job description here...",
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.all(20),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: (resumeUrl.isEmpty || _isAnalyzing) ? null : _analyzeJobMatch,
                  child: _isAnalyzing
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(resumeUrl.isEmpty ? "Upload Resume to Analyze" : "Calculate Match Score"),
                ),
                if (_matchScore != null) ...[
                  const SizedBox(height: 40),
                  _buildMatchReport(theme),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildResumeStatusCard(ThemeData theme, String resumeUrl) {
    final hasResume = resumeUrl.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(
            hasResume ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded,
            color: hasResume ? Colors.greenAccent : Colors.orangeAccent,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(hasResume ? "Resume Ready" : "No Resume", style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(hasResume ? "Extracted ${_analysisData?['extracted_skills']?.length ?? 0} skills" : "Upload to start", style: const TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const ResumeUploadScreen()));
              if (result == true) _loadStoredAnalysis();
            },
            child: Text(hasResume ? "Update" : "Upload"),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchReport(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Match Result", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text("$_matchScore%", style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 20)),
            ],
          ),
          const SizedBox(height: 24),
          const Text("Skills Found in JD", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _matchingSkills.map((s) => Chip(label: Text(s.toString(), style: const TextStyle(fontSize: 12)), backgroundColor: Colors.green.withOpacity(0.1), side: BorderSide.none)).toList(),
          ),
          const SizedBox(height: 24),
          const Text("Missing Recommendations", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _missingSkills.map((s) => Chip(label: Text(s.toString(), style: const TextStyle(fontSize: 12)), backgroundColor: Colors.orange.withOpacity(0.1), side: BorderSide.none)).toList(),
          ),
        ],
      ),
    );
  }
}
