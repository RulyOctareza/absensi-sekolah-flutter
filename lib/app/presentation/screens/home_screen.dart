import 'dart:io';

import 'package:absensi_sekolah/app/data/services/attendance_service.dart';
import 'package:absensi_sekolah/app/data/services/auth_service.dart';
import 'package:absensi_sekolah/app/data/services/firebase_service.dart';
import 'package:absensi_sekolah/app/presentation/screens/qr_scanner_screen.dart';
import 'package:csv/csv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

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
    // Tampilkan loading indicator di UI
    setState(() => _isLoading = true);
    _showSnackbar('Mempersiapkan laporan...', isError: false);

    try {
      final now = DateTime.now();
      final date =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      // 1. Ambil data dari Firebase (sama seperti sebelumnya)
      final attendanceData = await _firebaseService.getDailyAttendance(date);

      if (attendanceData == null || attendanceData.isEmpty) {
        throw 'Tidak ada data absensi untuk hari ini.';
      }

      // 2. Buat data CSV (sama seperti sebelumnya)
      List<List<dynamic>> rowsAsListOfValues = [];
      rowsAsListOfValues.add(attendanceData.first.keys.toList()); // Headers
      for (var map in attendanceData) {
        rowsAsListOfValues.add(map.values.toList());
      }
      String csv = const ListToCsvConverter().convert(rowsAsListOfValues);

      // 3. Simpan ke file temporer
      final directory =
          await getTemporaryDirectory(); // Gunakan direktori temporer
      final tempFilePath = "${directory.path}/temp_absensi_$date.csv";
      final tempFile = File(tempFilePath);
      await tempFile.writeAsString(csv);

      // Hentikan loading indicator di UI sebelum mulai download
      setState(() => _isLoading = false);

      // 4. "Unduh" file dari path temporer ke folder Downloads publik
      FileDownloader.downloadFile(
        url: tempFile.uri.toString(), // Gunakan URI dari file temporer
        name:
            "absensi_$date.csv", // Nama file yang akan muncul di folder Downloads
        onProgress: (fileName, progress) {
          // Anda bisa menampilkan progres di UI jika mau
        },
        onDownloadCompleted: (String path) {
          _showSnackbar('Laporan berhasil diunduh!', isError: false);
          OpenFile.open(path); // Buka file setelah selesai
        },
        onDownloadError: (String error) {
          throw 'Gagal mengunduh file: $error';
        },
      );
    } catch (e) {
      _showSnackbar(e.toString(), isError: true);
      // Pastikan loading indicator berhenti jika ada error
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

  void _downloadReportFromInternet(String url, String fileName) async {
    setState(() => _isLoading = true);
    _showSnackbar('Mengunduh laporan dari internet...', isError: false);
    try {
      await FileDownloader.downloadFile(
        url: url,
        name: fileName,
        onProgress: (fileName, progress) {
          // Bisa tambahkan indikator progres jika mau
        },
        onDownloadCompleted: (String path) {
          _showSnackbar('Laporan berhasil diunduh di: $path', isError: false);
          OpenFile.open(path); // Buka file setelah selesai
        },
        onDownloadError: (String error) {
          _showSnackbar('Gagal mengunduh file: $error', isError: true);
        },
      );
    } catch (e) {
      _showSnackbar(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
