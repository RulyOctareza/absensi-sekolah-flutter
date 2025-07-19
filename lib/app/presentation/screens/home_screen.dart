import 'package:absensi_sekolah/app/presentation/screens/qr_scanner_screen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Absensi Guru'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text('Scan QR Siswa'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            textStyle: const TextStyle(fontSize: 18),
          ),
          onPressed: () async {
            final result = await Navigator.push<String?>(
              context,
              MaterialPageRoute(builder: (context) => const QRScannerScreen()),
            );

            if (result != null) {
              // Tampilkan hasil scan di snackbar
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Hasil Scan: $result')));
              }
            }
          },
        ),
      ),
    );
  }
}
