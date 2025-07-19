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
}
