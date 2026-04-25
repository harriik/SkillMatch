import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/resume_upload_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  await Supabase.initialize(
    url: 'https://ksvegfckvystodowhcii.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtzdmVnZmNrdnlzdG9kb3doY2lpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQwNzA1MjEsImV4cCI6MjA4OTY0NjUyMX0._qLa3CqiIy9OUhg5OnpD-lBdGQwFPbbqJEe6PXqD_TM',
  );

  runApp(const SkillMatch());
}

class SkillMatch extends StatelessWidget {
  const SkillMatch({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AuthLandingPage(),
    );
  }
}

class AuthLandingPage extends StatefulWidget {
  const AuthLandingPage({super.key});

  @override
  State<AuthLandingPage> createState() => _AuthLandingPageState();
}

class _AuthLandingPageState extends State<AuthLandingPage> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        final user = snapshot.data;
        if (user != null) {
          return FutureBuilder<DocumentSnapshot>(
            // We use the UID to fetch the user doc
            future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              
              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                final data = userSnapshot.data!.data() as Map<String, dynamic>?;
                final String resumeUrl = data?['resume_url'] ?? '';
                
                if (resumeUrl.isNotEmpty) {
                  return const HomeScreen();
                }
              }
              
              // If no resume or document doesn't exist yet, go to upload
              return const ResumeUploadScreen();
            },
          );
        }
        
        return const LoginScreen();
      },
    );
  }
}
