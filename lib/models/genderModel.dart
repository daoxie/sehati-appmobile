/// Enum untuk jenis kelamin dalam sistem matching
enum Gender { lakiLaki, perempuan, semua }

/// Model untuk preferensi filter gender
class GenderFilter {
  final Gender selectedGender;

  const GenderFilter({this.selectedGender = Gender.semua});

  /// Konversi nilai Gender ke string untuk Firebase
  static String? toFirebaseString(Gender gender) {
    switch (gender) {
      case Gender.lakiLaki:
        return 'Laki-laki';
      case Gender.perempuan:
        return 'Perempuan';
      case Gender.semua:
        return null; // null berarti tidak ada filter
    }
  }

  /// Konversi string dari Firebase ke enum Gender
  static Gender fromFirebaseString(String? value) {
    switch (value) {
      case 'Laki-laki':
        return Gender.lakiLaki;
      case 'Perempuan':
        return Gender.perempuan;
      default:
        return Gender.semua;
    }
  }

  /// Mendapatkan nama tampilan untuk UI
  static String getDisplayName(Gender gender) {
    switch (gender) {
      case Gender.lakiLaki:
        return 'Laki-laki';
      case Gender.perempuan:
        return 'Perempuan';
      case Gender.semua:
        return 'Semua';
    }
  }

  /// Mendapatkan icon untuk UI
  static String getIcon(Gender gender) {
    switch (gender) {
      case Gender.lakiLaki:
        return '♂';
      case Gender.perempuan:
        return '♀';
      case Gender.semua:
        return '⚥';
    }
  }

  /// Daftar semua opsi gender untuk filter
  static List<Gender> get allOptions => Gender.values;
}
