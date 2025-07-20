import 'dart:developer';
import 'package:firebase_database/firebase_database.dart';

class FirebaseService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  Future<Map<String, dynamic>?> getStudentById(String studentId) async {
    log('[FirebaseService] Mencari siswa dengan ID: $studentId');
    for (int i = 1; i <= 6; i++) {
      log('[FirebaseService] Cek di Kelas_$i');
      final studentSnapshot = await _dbRef
          .child('Kelas_$i')
          .orderByChild('id_siswa')
          .equalTo(studentId)
          .get();

      log(
        '[FirebaseService] Snapshot exists: \'${studentSnapshot.exists}\', value: \'${studentSnapshot.value}\'',
      );
      if (studentSnapshot.exists && studentSnapshot.value != null) {
        final data = studentSnapshot.value;
        log('[FirebaseService] Data hasil query: $data');
        if (data is Map) {
          final first = data.values.first;
          log('[FirebaseService] Data Map pertama: $first');
          if (first != null) {
            return Map<String, dynamic>.from(first as Map);
          }
        } else if (data is List) {
          // Jika hasil query berupa List, ambil Map pertama
          log('[FirebaseService] Data berupa List, ambil elemen pertama');
          if (data.isNotEmpty && data.first != null) {
            return Map<String, dynamic>.from(data.first as Map);
          }
        }
      }
    }
    log(
      '[FirebaseService] Siswa dengan ID $studentId tidak ditemukan di semua kelas.',
    );
    return null;
  }

  Future<Map<String, dynamic>?> getTeacherData(String email) async {
    final teacherSnapshot = await _dbRef
        .child('Guru')
        .orderByChild('email')
        .equalTo(email)
        .get();

    if (teacherSnapshot.exists && teacherSnapshot.value != null) {
      final data = teacherSnapshot.value;
      if (data is Map) {
        // Data dari query ini datang sebagai Map, bukan List, karena key-nya unik (-Mxxxx)
        final teacherDataMap = Map<String, dynamic>.from(data);
        // Ambil data dari value pertama di dalam Map tersebut
        final teacherData = Map<String, dynamic>.from(
          teacherDataMap.values.first,
        );
        return teacherData;
      } else if (data is List) {
        // Jika data berupa List, cari elemen pertama yang tidak null
        final first = data.firstWhere((e) => e != null, orElse: () => null);
        if (first != null) {
          return Map<String, dynamic>.from(first as Map);
        }
      }
    }
    return null;
  }

  Future<List<Map<String, dynamic>>?> getDailyAttendance(String date) async {
    // Nama sheet di GSheets adalah 'yyyy-MM-dd', tapi path di Firebase adalah 'yyyy_MM_dd'
    final datePath = date.replaceAll('-', '_');
    final attendanceSnapshot = await _dbRef
        .child('Log_Absensi_Harian/$datePath')
        .get();

    if (attendanceSnapshot.exists && attendanceSnapshot.value != null) {
      final List<Map<String, dynamic>> attendanceList = [];
      // Data datang sebagai List<dynamic>, kita perlu konversi
      final rawList = attendanceSnapshot.value as List<dynamic>;
      for (var item in rawList) {
        if (item != null) {
          attendanceList.add(Map<String, dynamic>.from(item as Map));
        }
      }
      return attendanceList;
    }
    return null;
  }
}
