import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../main.dart'; // Import themeNotifier
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  bool _isUpdatingPhoto = false;
  Map<String, dynamic>? _analysisData;
  bool _isLoadingAnalysis = true;

  @override
  void initState() {
    super.initState();
    _loadAnalysis();
  }

  Future<void> _loadAnalysis() async {
    final data = await _authService.getLatestAnalysis();
    if (mounted) {
      setState(() {
        _analysisData = data;
        _isLoadingAnalysis = false;
      });
    }
  }

  Future<void> _updatePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() => _isUpdatingPhoto = true);
      try {
        await _authService.updateProfilePhoto(File(image.path));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile photo updated successfully")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      } finally {
        if (mounted) setState(() => _isUpdatingPhoto = false);
      }
    }
  }

  void _showEditNameDialog(String currentName) {
    final TextEditingController nameController = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Name"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: "Full Name"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                try {
                  await _authService.updateDisplayName(nameController.text.trim());
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Name updated successfully")),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                }
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showJobPreferencesDialog(Map<String, dynamic> currentPrefs) {
    final TextEditingController locationController = TextEditingController(text: currentPrefs['location'] ?? '');
    final TextEditingController salaryController = TextEditingController(text: currentPrefs['expected_salary'] ?? '');
    String jobType = currentPrefs['job_type'] ?? 'Full-time';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Edit Job Preferences"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: "Preferred Location", prefixIcon: Icon(Icons.location_on_outlined)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: salaryController,
                  decoration: const InputDecoration(labelText: "Expected Salary", prefixIcon: Icon(Icons.payments_outlined)),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: jobType,
                  decoration: const InputDecoration(labelText: "Job Type", prefixIcon: Icon(Icons.work_outline)),
                  items: ['Full-time', 'Part-time', 'Contract', 'Internship']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) => setDialogState(() => jobType = val!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _authService.updateUserPreferences({
                    ...currentPrefs,
                    'location': locationController.text.trim(),
                    'expected_salary': salaryController.text.trim(),
                    'job_type': jobType,
                  });
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Preferences updated!")));
                  }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final TextEditingController currentPass = TextEditingController();
    final TextEditingController newPass = TextEditingController();
    final TextEditingController confirmPass = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Change Password"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: currentPass, obscureText: true, decoration: const InputDecoration(labelText: "Current Password")),
            TextField(controller: newPass, obscureText: true, decoration: const InputDecoration(labelText: "New Password")),
            TextField(controller: confirmPass, obscureText: true, decoration: const InputDecoration(labelText: "Confirm New Password")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (newPass.text != confirmPass.text) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passwords don't match")));
                return;
              }
              try {
                await _authService.changePassword(currentPass.text, newPass.text);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password changed successfully!")));
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text("Change"),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(Map<String, dynamic> currentPrefs) {
    bool notificationsEnabled = currentPrefs['notifications_enabled'] ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Settings"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text("Notifications"),
                value: notificationsEnabled,
                onChanged: (val) async {
                  setDialogState(() => notificationsEnabled = val);
                  try {
                    await _authService.updateUserPreferences({
                      ...currentPrefs,
                      'notifications_enabled': val,
                    });
                  } catch (e) {
                    print("Error updating notification setting: $e");
                  }
                },
              ),
              SwitchListTile(
                title: const Text("Dark Mode"),
                value: themeNotifier.value == ThemeMode.dark,
                onChanged: (val) {
                  setDialogState(() {
                    themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Done")),
          ],
        ),
      ),
    );
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
        title: const Text("My Account"),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadAnalysis,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _authService.getUserStream(),
        builder: (context, snapshot) {
          String name = "User";
          String photoUrl = "";
          String email = "";
          Map<String, dynamic> prefs = {};

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            name = data['name'] ?? "User";
            photoUrl = data['photo_url'] ?? "";
            email = data['email'] ?? "";
            prefs = data['preferences'] ?? {};
          }

          final List<dynamic> skills = _analysisData?['extracted_skills'] ?? [];
          final int matchCount = (_analysisData?['matched_jobs'] as List?)?.length ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                      backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                      child: photoUrl.isEmpty
                          ? Icon(Icons.person, size: 60, color: theme.colorScheme.primary)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _isUpdatingPhoto ? null : _updatePhoto,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: theme.scaffoldBackgroundColor, width: 3),
                          ),
                          child: _isUpdatingPhoto
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.camera_alt_rounded, size: 20, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem(context, matchCount.toString(), "Matches"),
                    _buildStatDivider(theme),
                    _buildStatItem(context, skills.length.toString(), "Skills"),
                    _buildStatDivider(theme),
                    _buildStatItem(context, "100%", "Profile"),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                if (skills.isNotEmpty) ...[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Extracted Skills", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: skills.map((skill) => Chip(
                        label: Text(skill.toString(), style: const TextStyle(fontSize: 12)),
                        backgroundColor: theme.colorScheme.primary.withOpacity(0.05),
                        side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.1)),
                      )).toList(),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                _buildProfileMenu(context, "Personal Information", Icons.person_outline_rounded, () => _showEditNameDialog(name)),
                _buildProfileMenu(context, "Job Preferences", Icons.work_outline_rounded, () => _showJobPreferencesDialog(prefs)),
                _buildProfileMenu(context, "Security & Password", Icons.lock_outline_rounded, _showChangePasswordDialog),
                _buildProfileMenu(context, "Settings", Icons.settings_outlined, () => _showSettingsDialog(prefs)),
                
                const SizedBox(height: 16),
                Divider(color: theme.dividerColor),
                const SizedBox(height: 16),
                
                _buildProfileMenu(
                  context,
                  "Log Out",
                  Icons.logout_rounded,
                  _logout,
                  isDestructive: true,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String value, String label) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.4))),
      ],
    );
  }

  Widget _buildStatDivider(ThemeData theme) => Container(height: 30, width: 1, color: theme.dividerColor);

  Widget _buildProfileMenu(BuildContext context, String title, IconData icon, VoidCallback onTap, {bool isDestructive = false}) {
    final theme = Theme.of(context);
    final color = isDestructive ? theme.colorScheme.error : theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color.withOpacity(0.7)),
        title: Text(title, style: TextStyle(color: color.withOpacity(0.9), fontWeight: FontWeight.w500)),
        trailing: Icon(Icons.chevron_right_rounded, color: color.withOpacity(0.3)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
      ),
    );
  }
}
