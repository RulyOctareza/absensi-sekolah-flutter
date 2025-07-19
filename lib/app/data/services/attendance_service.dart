import 'dart:convert';
import 'package:absensi_sekolah/app/utils/constants.dart';
import 'package:http/http.dart' as http;

class AttendanceService {
  Future<void> submitAttendance({
    required Map<String, dynamic> studentData,
    required String attendanceType, // "masuk" atau "pulang"
  }) async {
    try {
      final url = Uri.parse(webAppUrl);
      final body = json.encode({
        'id_siswa': studentData['id_siswa'],
        'nama_siswa': studentData['nama_lengkap'],
        'kelas': studentData['kelas'].toString(),
        'tipe_absen': attendanceType,
      });

      final response = await http.post(url, body: body);

      if (response.statusCode != 200) {
        throw 'Gagal terhubung ke server. Status: ${response.statusCode}';
      }

      final responseBody = json.decode(response.body);
      if (responseBody['status'] != 'success') {
        throw responseBody['message'] ?? 'Terjadi error yang tidak diketahui.';
      }
    } catch (e) {
      // Lemparkan kembali error agar bisa ditangkap oleh UI
      throw 'Error saat mengirim absensi: $e';
    }
  }
}
