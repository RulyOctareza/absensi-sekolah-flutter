import 'dart:convert';
import 'dart:developer';
import 'package:absensi_sekolah/app/utils/constants.dart';
import 'package:dio/dio.dart';

class AttendanceService {
  final Dio _dio = Dio();

  Future<void> submitAttendance({
    required Map<String, dynamic> studentData,
    required String attendanceType, // "masuk" atau "pulang"
  }) async {
    try {
      log(
        '[AttendanceService] Mulai submitAttendance dengan data: studentData=$studentData, attendanceType=$attendanceType',
      );
      final data = {
        'id_siswa': studentData['id_siswa'],
        'nama_siswa': studentData['nama_lengkap'],
        'kelas': studentData['kelas'].toString(),
        'tipe_absen': attendanceType,
      };
      log(
        '[AttendanceService] POST ke $webAppUrl dengan body: ${json.encode(data)}',
      );
      final response = await _dio.post(
        webAppUrl,
        data: json.encode(data),
        options: Options(
          headers: {'Content-Type': 'application/json'},
          followRedirects: true,
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      log(
        '[AttendanceService] Response status: \'${response.statusCode}\', body: \'${response.data}\'',
      );

      
      final responseBody = response.data is String
          ? json.decode(response.data)
          : response.data;
      log('[AttendanceService] Response decode: $responseBody');
      if (responseBody['status'] != 'success') {
        throw responseBody['message'] ?? 'Terjadi error yang tidak diketahui.';
      }
    } on DioException catch (e) {
      log('[AttendanceService] Dio error: \'${e.message}\'');
      throw 'Gagal terhubung ke server. Periksa koneksi internet Anda.';
    } catch (e) {
      log('[AttendanceService] ERROR: $e');
      throw 'Error saat mengirim absensi: $e';
    }
  }
}
