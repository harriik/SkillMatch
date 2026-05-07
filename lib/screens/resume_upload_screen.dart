import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home_screen.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';

class ResumeUploadScreen extends StatefulWidget {
  final bool canSkip;
  const ResumeUploadScreen({super.key, this.canSkip = false});

  @override
  State<ResumeUploadScreen> createState() => _ResumeUploadScreenState();
}

class _ResumeUploadScreenState extends State<ResumeUploadScreen> {
  final AuthService _authService = AuthService();
  bool _isUploading = false;
  File? _selectedFile;

  // IMPORTANT: Replace this with your public server URL (e.g. from Render or Ngrok)
  // Local IPs like 172.28.x.x ONLY work on the same Wi-Fi.
  final String backendUrl = "https://skillmatch-backend-q27s.onrender.com/analyze_resume";

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _uploadAndAnalyze() async {
    if (_selectedFile == null) return;

    setState(() => _isUploading = true);

    try {
      // 1. Upload to Supabase Storage
      String resumeUrl = await _authService.uploadResume(_selectedFile!);
      
      // 2. Call FastAPI Backend for AI Analysis
      final user = _authService.currentUser;
      if (user != null) {
        final response = await http.post(
          Uri.parse(backendUrl),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "user_id": user.uid,
            "resume_url": resumeUrl,
          }),
        ).timeout(const Duration(seconds: 60));

        if (response.statusCode != 200) {
          throw "Backend Analysis Failed: ${response.body}";
        }
      }

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      String msg = "Upload failed. ";
      if (e is SocketException || e.toString().contains("Connection refused")) {
        msg += "Cannot reach the backend server. If you are using a local IP (172.28.x.x), ensure your phone is on the SAME Wi-Fi as your laptop and the firewall is off.";
      } else {
        msg += e.toString();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            duration: const Duration(seconds: 10),
            action: SnackBarAction(label: "Retry", onPressed: _uploadAndAnalyze),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _logout() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!Navigator.canPop(context))
            TextButton.icon(
              onPressed: _logout,
              icon: Icon(Icons.logout, size: 18, color: theme.colorScheme.onSurface.withOpacity(0.7)),
              label: Text("Logout", style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7))),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome_rounded, size: 80, color: theme.colorScheme.primary),
              const SizedBox(height: 32),
              const Text(
                "AI Resume Analysis",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                "Upload your PDF resume to extract skills and match jobs.",
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
              ),
              const SizedBox(height: 48),
              InkWell(
                onTap: _isUploading ? null : _pickFile,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedFile != null ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.1),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _selectedFile != null ? Icons.check_circle_rounded : Icons.cloud_upload_outlined,
                        size: 40,
                        color: _selectedFile != null ? Colors.green : theme.colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _selectedFile != null ? _selectedFile!.path.split(Platform.pathSeparator).last : "Select Resume (PDF Only)",
                        style: TextStyle(color: _selectedFile != null ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withOpacity(0.3)),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: (_selectedFile == null || _isUploading) ? null : _uploadAndAnalyze,
                  child: _isUploading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                            SizedBox(width: 12),
                            Text("AI is Analyzing..."),
                          ],
                        )
                      : const Text("Analyze & Continue"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
