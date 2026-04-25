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

  // UPDATED: Using your actual Wi-Fi IPv4 address from ipconfig
  final String backendUrl = "http://10.224.64.23:8000/analyze_resume";

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
        ).timeout(const Duration(seconds: 30));

        if (response.statusCode != 200) {
          throw "Backend Error: ${response.statusCode}\n${response.body}";
        }
      }

      if (mounted) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context, true);
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      String msg = e.toString();
      if (e is SocketException) {
        msg = "Connection Failed: Ensure your PC and phone are on the SAME Wi-Fi (10.36.15.x) and Port 8000 is open in your firewall.";
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), duration: const Duration(seconds: 5)),
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
              icon: const Icon(Icons.logout, size: 18, color: Colors.white70),
              label: const Text("Logout", style: TextStyle(color: Colors.white70)),
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
              const Text(
                "Upload your PDF resume to extract skills and match jobs.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 48),
              InkWell(
                onTap: _isUploading ? null : _pickFile,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedFile != null ? theme.colorScheme.primary : Colors.white10,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _selectedFile != null ? Icons.check_circle_rounded : Icons.cloud_upload_outlined,
                        size: 40,
                        color: _selectedFile != null ? Colors.green : Colors.white38,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _selectedFile != null ? _selectedFile!.path.split(Platform.pathSeparator).last : "Select Resume (PDF Only)",
                        style: TextStyle(color: _selectedFile != null ? Colors.white : Colors.white38),
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
