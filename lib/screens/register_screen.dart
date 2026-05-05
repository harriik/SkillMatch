import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';
import 'resume_upload_screen.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _salaryController = TextEditingController();
  String _jobType = 'Full-time';

  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _register() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = await _authService.signUpWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
      );
      
      if (user != null) {
        await _authService.updateUserPreferences({
          'location': _locationController.text.trim(),
          'expected_salary': _salaryController.text.trim(),
          'job_type': _jobType,
        });

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const ResumeUploadScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                "Create Account",
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Join SkillMatch and start your career journey",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white60,
                ),
              ),
              const SizedBox(height: 32),
              
              const Text("Personal Information", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Full Name *",
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "Email Address *",
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password *",
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Confirm Password *",
                  prefixIcon: Icon(Icons.lock_reset_rounded),
                ),
              ),
              
              const SizedBox(height: 32),
              const Text("Job Preferences", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: "Preferred Location",
                  prefixIcon: Icon(Icons.location_on_outlined),
                  hintText: "e.g. Remote, Bangalore",
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _salaryController,
                decoration: const InputDecoration(
                  labelText: "Expected Salary",
                  prefixIcon: Icon(Icons.payments_outlined),
                  hintText: "e.g. ₹10 LPA",
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _jobType,
                decoration: const InputDecoration(
                  labelText: "Job Type",
                  prefixIcon: Icon(Icons.work_outline),
                ),
                items: ['Full-time', 'Part-time', 'Contract', 'Internship']
                    .map((label) => DropdownMenuItem(
                          value: label,
                          child: Text(label),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _jobType = value!;
                  });
                },
              ),

              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text("Sign Up"),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
