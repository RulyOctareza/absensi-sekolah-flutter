import 'dart:convert';

import 'package:absensi_sekolah/app/utils/constants.dart';
import 'package:dio/dio.dart'; // Impor paket dio

class AttendanceService {
  final Dio _dio = Dio(); // Buat instance dari Dio

  Future<void> submitAttendance({
    required Map<String, dynamic> studentData,
    required String attendanceType, // "masuk" atau "pulang"
  }) async {
    try {
      // Dio secara otomatis akan mengikuti redirect
      final response = await _dio.post(
        webAppUrl,
        data: json.encode({
          // kirim data dalam format string JSON
          'id_siswa': studentData['id_siswa'],
          'nama_siswa': studentData['nama_lengkap'],
          'kelas': studentData['kelas'].toString(),
          'tipe_absen': attendanceType,
        }),
        options: Options(
          headers: {'Content-Type': 'application/json'},
          followRedirects: true,
          // Anggap 302 sebagai status valid (berhasil), bukan error
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      // Anggap 302 sebagai sukses jika memang server selalu redirect setelah record
      if (response.statusCode == 302) {
        // Optional: log atau handle khusus jika perlu
        return;
      }

      final responseBody = response.data;
      if (responseBody is Map && responseBody['status'] != 'success') {
        throw responseBody['message'] ?? 'Terjadi error yang tidak diketahui.';
      }
    } on DioException catch (e) {
      // Menangkap error spesifik dari Dio untuk logging yang lebih baik
      print('Dio error: ${e.message}');
      throw 'Gagal terhubung ke server. Periksa koneksi internet Anda.';
    } catch (e) {
      // Menangkap error lainnya
      throw 'Error saat mengirim absensi: $e';
    }
  }
}
