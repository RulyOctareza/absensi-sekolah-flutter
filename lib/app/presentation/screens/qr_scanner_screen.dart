import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:absensi_sekolah/app/data/services/firebase_service.dart';
import 'package:absensi_sekolah/app/data/services/attendance_service.dart';
import 'package:absensi_sekolah/app/data/services/notification_service.dart';

class QRScannerScreen extends StatefulWidget {
  final String attendanceType;
  const QRScannerScreen({super.key, required this.attendanceType});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  final List<Map<String, String>> scanResults = [];
  final FirebaseService _firebaseService = FirebaseService();
  final AttendanceService _attendanceService = AttendanceService();
  final NotificationService _notificationService = NotificationService();
  bool isProcessing = false;

  // Untuk mengatasi hot-reload, kita perlu pause dan resume kamera
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan QR ${widget.attendanceType}'),
        actions: [
          if (isProcessing)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.purple,
                ),
              ),
            )
          else
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Selesai',
                style: TextStyle(color: Colors.purple),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: Colors.deepPurple,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 300,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: ListView.builder(
              itemCount: scanResults.length,
              itemBuilder: (context, index) {
                final result = scanResults[index];
                final isSuccess = result['status'] == 'Berhasil';
                return ListTile(
                  leading: Icon(
                    isSuccess ? Icons.check_circle : Icons.error,
                    color: isSuccess ? Colors.green : Colors.red,
                  ),
                  title: Text(result['nama'] ?? result['id'] ?? '-'),
                  subtitle: Text(result['status'] ?? ''),
                  trailing: result['id'] != null ? Text(result['id']!) : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      if (isProcessing) return;
      final id = scanData.code;
      if (id != null && !scanResults.any((e) => e['id'] == id)) {
        setState(() {
          isProcessing = true;
        });
        String status = '';
        String? nama;
        try {
          final studentData = await _firebaseService.getStudentById(id);
          if (studentData == null) {
            status = 'Gagal: Siswa tidak ditemukan';
          } else {
            nama = studentData['nama_lengkap'] ?? id;
            await _attendanceService.submitAttendance(
              studentData: studentData,
              attendanceType: widget.attendanceType,
            );
            await _notificationService.sendWhatsappNotification(
              studentData: studentData,
              attendanceType: widget.attendanceType,
            );
            status = 'Berhasil';
          }
        } catch (e) {
          status = 'Gagal: ${e.toString()}';
        }
        setState(() {
          scanResults.add({'id': id, 'nama': nama ?? id, 'status': status});
          isProcessing = false;
        });
        await controller.pauseCamera();
        await Future.delayed(const Duration(seconds: 1));
        await controller.resumeCamera();
      }
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
