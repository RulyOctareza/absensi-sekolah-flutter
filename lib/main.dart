import 'dart:developer';

import 'package:absensi_sekolah/app/presentation/screens/home_screen.dart';
import 'package:absensi_sekolah/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  log('[main] Inisialisasi aplikasi...');
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  log('[main] Firebase initialized, menjalankan MainApp...');
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    log('[MainApp] build dipanggil');
    return const MaterialApp(home: HomeScreen());
  }
}
