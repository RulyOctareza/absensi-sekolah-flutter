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

  void _processAttendance(String attendanceType) async {
    // Jangan lakukan apa-apa jika sedang loading
    if (_isLoading) return;

    final scannedId = await Navigator.push<String?>(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );

    if (scannedId == null) return;

    setState(() => _isLoading = true);

    try {
      final studentData = await _firebaseService.getStudentById(scannedId);

      if (studentData == null) {
        throw 'Data siswa dengan ID "$scannedId" tidak ditemukan.';
      }

      await _attendanceService.submitAttendance(
        studentData: studentData,
        attendanceType: attendanceType,
      );

      final successMessage =
          'Absen ${attendanceType == 'masuk' ? 'MASUK' : 'PULANG'} untuk ${studentData['nama_lengkap']} berhasil!';
      _showSnackbar(successMessage, isError: false);
    } catch (e) {
      _showSnackbar(e.toString(), isError: true);
    } finally {
      setState(() => _isLoading = false);
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
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Tombol Absen Masuk
                  ElevatedButton.icon(
                    icon: const Icon(Icons.login),
                    label: const Text('Absen Masuk'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 20,
                      ),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                    // Tambahkan pengecekan _isLoading di sini
                    onPressed: _isLoading
                        ? null
                        : () => _processAttendance('masuk'),
                  ),
                  const SizedBox(height: 20),
                  // Tombol Absen Pulang
                  ElevatedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: const Text('Absen Pulang'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 20,
                      ),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                    // Tambahkan pengecekan _isLoading di sini
                    onPressed: _isLoading
                        ? null
                        : () => _processAttendance('pulang'),
                  ),
                ],
              ),
      ),
    );
  }
}
