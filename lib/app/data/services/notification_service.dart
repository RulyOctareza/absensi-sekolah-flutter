import 'dart:convert';
import 'package:absensi_sekolah/app/utils/constants.dart';
import 'package:dio/dio.dart';

class NotificationService {
  final Dio _dio = Dio();

  Future<void> sendWhatsappNotification({
    required Map<String, dynamic> studentData,
    required String attendanceType,
  }) async {
    try {
      // Ambil nomor whatsapp dari data siswa
      final String? waNumber = studentData['Nomor_Whatsapp']?.toString();

      if (waNumber == null || waNumber.isEmpty) {
        print(
          'Nomor WhatsApp tidak ditemukan untuk siswa ini, notifikasi dilewati.',
        );
        return;
      }

      final now = DateTime.now();
      final time =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

      await _dio.post(
        n8nWebHookUrl,
        data: json.encode({
          'nama_siswa': studentData['nama_lengkap'],
          'nomor_whatsapp': waNumber.startsWith('0')
              ? '62${waNumber.substring(1)}'
              : waNumber,
          'tipe_absen': attendanceType,
          'waktu': time,
        }),
      );
      print('Permintaan notifikasi ke n8n berhasil dikirim.');
    } catch (e) {
      // Kita hanya print error, tidak melemparnya ke UI agar tidak mengganggu
      // user jika notifikasi gagal terkirim.
      print('Gagal mengirim notifikasi ke n8n: $e');
    }
  }
}
