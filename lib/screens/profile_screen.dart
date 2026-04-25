import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
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
        title: const Text("Profile"),
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

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            name = data['name'] ?? "User";
            photoUrl = data['photo_url'] ?? "";
            email = data['email'] ?? "";
          }

          final List<dynamic> education = _analysisData?['education'] ?? [];
          final List<dynamic> experience = _analysisData?['experience'] ?? [];

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
                    color: Colors.white60,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem(context, "12", "Applied"),
                    _buildStatDivider(),
                    _buildStatItem(context, "28", "Saved"),
                    _buildStatDivider(),
                    _buildStatItem(context, "156", "Views"),
                  ],
                ),
                const SizedBox(height: 40),
                
                // Real Education Section
                _buildInfoSection(context, "Education", Icons.school_outlined, education),
                const SizedBox(height: 20),
                
                // Real Experience Section
                _buildInfoSection(context, "Experience", Icons.history_edu_rounded, experience),
                
                const SizedBox(height: 32),
                const Divider(color: Colors.white10),
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

  Widget _buildInfoSection(BuildContext context, String title, IconData icon, List<dynamic> items) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          const Text("No information found. Upload resume to populate.", style: TextStyle(color: Colors.white38, fontSize: 13))
        else
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0, left: 32),
            child: Text("• $item", style: const TextStyle(color: Colors.white70, fontSize: 14)),
          )).toList(),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white38,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.white10,
    );
  }

  Widget _buildProfileMenu(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    final color = isDestructive ? theme.colorScheme.error : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color.withOpacity(0.7)),
        title: Text(
          title,
          style: TextStyle(
            color: color.withOpacity(0.9),
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: color.withOpacity(0.3),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: theme.colorScheme.surface.withOpacity(0.5),
      ),
    );
  }
}
