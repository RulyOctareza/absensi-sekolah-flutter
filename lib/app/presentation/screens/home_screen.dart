import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:absensi_sekolah/app/data/services/attendance_service.dart';
import 'package:absensi_sekolah/app/data/services/auth_service.dart';
import 'package:absensi_sekolah/app/data/services/firebase_service.dart';
import 'package:absensi_sekolah/app/presentation/screens/qr_scanner_screen.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final AttendanceService _attendanceService = AttendanceService();
  final AuthService _authService = AuthService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  bool _isLoading = false;
  String? _teacherName;
  String? _assignedClass;

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
  }

  void _loadTeacherData() async {
    if (currentUser?.email == null) return;

    final teacherData = await _firebaseService.getTeacherData(
      currentUser!.email!,
    );
    if (teacherData != null) {
      setState(() {
        _teacherName = teacherData['nama_guru'].toString();
        _assignedClass = teacherData['kelas_yang_diajar'].toString();
      });
    }
  }

  void _downloadReport() async {
    setState(() => _isLoading = true);
    try {
      // 1. Ambil data absensi
      final now = DateTime.now();
      final date =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final attendanceData = await _firebaseService.getDailyAttendance(date);

      if (attendanceData == null || attendanceData.isEmpty) {
        throw 'Tidak ada data absensi untuk hari ini.';
      }

      // 2. Buat data CSV
      List<List<dynamic>> rowsAsListOfValues = [];
      rowsAsListOfValues.add(attendanceData.first.keys.toList());
      for (var map in attendanceData) {
        rowsAsListOfValues.add(map.values.toList());
      }
      String csv = const ListToCsvConverter().convert(rowsAsListOfValues);

      // 3. Pilih lokasi simpan file (gunakan FileSaver, bukan FilePicker, dan gunakan bytes)
      final Uint8List bytes = Uint8List.fromList(utf8.encode(csv));
      final String filePath = await FileSaver.instance.saveFile(
        name: 'absensi_$date',
        bytes: bytes,
        fileExtension: 'csv',
        mimeType: MimeType.csv,
      );

      _showSnackbar('Laporan berhasil disimpan di: $filePath', isError: false);
      OpenFile.open(filePath);
    } catch (e) {
      _showSnackbar(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _processAttendance(String attendanceType) async {
    if (_isLoading) return;

    // Cek apakah data kelas sudah dimuat
    if (_assignedClass == null) {
      _showSnackbar('Data kelas guru tidak ditemukan.', isError: true);
      return;
    }

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

      // Validasi: Pastikan siswa berada di kelas yang diajar guru
      // Ubah 'Kelas 1' menjadi 'Kelas_1' untuk perbandingan
      final studentClass = 'Kelas_${studentData['kelas']}';
      if (studentClass != _assignedClass!.replaceAll(' ', '_')) {
        throw 'Error: Siswa ini bukan dari kelas Anda (${_assignedClass!}).';
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
        title: Text(
          _teacherName == null
              ? 'Memuat...'
              : 'Selamat Datang, ${_teacherName!}',
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          // Tombol Logout
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              // AuthGate akan otomatis handle navigasi ke login screen
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_assignedClass != null)
                    Text(
                      'Anda mengajar: $_assignedClass',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  const SizedBox(height: 30),
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
                    onPressed: _isLoading
                        ? null
                        : () => _processAttendance('masuk'),
                  ),
                  const SizedBox(height: 20),
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
                    onPressed: _isLoading
                        ? null
                        : () => _processAttendance('pulang'),
                  ),

                  const SizedBox(height: 40),
                  TextButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text('Unduh Laporan Hari Ini'),
                    onPressed: _isLoading ? null : _downloadReport,
                  ),
                ],
              ),
      ),
    );
  }
}
