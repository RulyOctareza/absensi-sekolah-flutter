
import 'package:firebase_database/firebase_database.dart';

class FirebaseService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  Future<Map<String, dynamic>?> getStudentById(String studentId) async {
    for (int i = 1; i <= 6; i++) {
      final studentSnapshot = await _dbRef
          .child('Kelas_$i')
          .orderByChild('id_siswa')
          .equalTo(studentId)
          .get();

      if (studentSnapshot.exists) {
        // Data ditemukan, ambil data anak pertama (seharusnya hanya ada satu)
        final studentData = Map<String, dynamic>.from(
          (studentSnapshot.value as Map).values.first,
        );
        return studentData;
      }
    }
    // Jika loop selesai dan tidak ada data yang ditemukan
    return null;
  }
}
