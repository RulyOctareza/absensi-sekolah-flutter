// lib/app/presentation/screens/auth_gate.dart
import 'package:absensi_sekolah/app/data/services/auth_service.dart';
import 'package:absensi_sekolah/app/presentation/screens/home_screen.dart';
import 'package:absensi_sekolah/app/presentation/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().user,
      builder: (context, snapshot) {
        // Jika user sudah login, tampilkan HomeScreen
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        // Jika belum, tampilkan LoginScreen
        else {
          return const LoginScreen();
        }
      },
    );
  }
}
