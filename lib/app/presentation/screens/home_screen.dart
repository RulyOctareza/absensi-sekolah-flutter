import 'dart:developer';

import 'package:absensi_sekolah/app/data/services/attendance_service.dart';
import 'package:absensi_sekolah/app/data/services/firebase_service.dart';
import 'package:absensi_sekolah/app/presentation/screens/qr_scanner_screen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final AttendanceService _attendanceService = AttendanceService();
  bool _isLoading = false;

  void _scanQRCode() async {
    log('[HomeScreen] Mulai proses scan QR');
    final scannedId = await Navigator.push<String?>(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );
    log('[HomeScreen] Hasil scan QR: $scannedId');
    if (scannedId == null) return;

    setState(() => _isLoading = true);
    try {
      log('[HomeScreen] Mencari data siswa dengan ID: $scannedId');
      final studentData = await _firebaseService.getStudentById(scannedId);
      log('[HomeScreen] Data siswa ditemukan: $studentData');
      if (studentData == null) {
        if (mounted) {
          _showSnackbar(
            'Data siswa dengan ID "$scannedId" tidak ditemukan.',
            isError: true,
          );
        }
        return;
      }
      log('[HomeScreen] Submit absensi untuk siswa: $studentData');
      await _attendanceService.submitAttendance(
        studentData: studentData,
        attendanceType: 'masuk',
      );
      log('[HomeScreen] Absensi berhasil disubmit');
      if (mounted) {
        _showSnackbar(
          'Absensi untuk \\${studentData['nama_lengkap']} berhasil!',
          isError: false,
        );
      }
    } catch (e) {
      if (mounted) _showSnackbar(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Absensi Guru'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton.icon(
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan QR Siswa'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                onPressed: _scanQRCode,
              ),
      ),
    );
  }
}
