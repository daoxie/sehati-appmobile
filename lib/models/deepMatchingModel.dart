/// Daftar pilihan agama
enum Agama { islam, kristen, katolik, hindu, buddha, konghucu, lainnya }

/// Helper class untuk Agama
class AgamaHelper {
  static const List<String> daftarAgama = [
    'Islam',
    'Kristen',
    'Katolik',
    'Hindu',
    'Buddha',
    'Konghucu',
    'Lainnya',
  ];

  /// Konversi enum ke string untuk Firebase
  static String toDisplayString(Agama agama) {
    switch (agama) {
      case Agama.islam:
        return 'Islam';
      case Agama.kristen:
        return 'Kristen';
      case Agama.katolik:
        return 'Katolik';
      case Agama.hindu:
        return 'Hindu';
      case Agama.buddha:
        return 'Buddha';
      case Agama.konghucu:
        return 'Konghucu';
      case Agama.lainnya:
        return 'Lainnya';
    }
  }

  /// Konversi string ke enum
  static Agama? fromString(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'Islam':
        return Agama.islam;
      case 'Kristen':
        return Agama.kristen;
      case 'Katolik':
        return Agama.katolik;
      case 'Hindu':
        return Agama.hindu;
      case 'Buddha':
        return Agama.buddha;
      case 'Konghucu':
        return Agama.konghucu;
      case 'Lainnya':
        return Agama.lainnya;
      default:
        return null;
    }
  }
}

/// Daftar pilihan hobi populer
class HobiHelper {
  static const List<String> daftarHobi = [
    'Membaca',
    'Menulis',
    'Olahraga',
    'Musik',
    'Gaming',
    'Traveling',
    'Fotografi',
    'Memasak',
    'Menonton Film',
    'Berkebun',
    'Melukis',
    'Menari',
    'Berenang',
    'Hiking',
    'Yoga',
    'Meditasi',
    'Belanja',
    'Kuliner',
    'Otomotif',
    'Coding',
  ];

  /// Mendapatkan icon untuk hobi tertentu
  static String getIcon(String hobi) {
    switch (hobi) {
      case 'Membaca':
        return '📚';
      case 'Menulis':
        return '✍️';
      case 'Olahraga':
        return '⚽';
      case 'Musik':
        return '🎵';
      case 'Gaming':
        return '🎮';
      case 'Traveling':
        return '✈️';
      case 'Fotografi':
        return '📷';
      case 'Memasak':
        return '🍳';
      case 'Menonton Film':
        return '🎬';
      case 'Berkebun':
        return '🌱';
      case 'Melukis':
        return '🎨';
      case 'Menari':
        return '💃';
      case 'Berenang':
        return '🏊';
      case 'Hiking':
        return '🥾';
      case 'Yoga':
        return '🧘';
      case 'Meditasi':
        return '🙏';
      case 'Belanja':
        return '🛍️';
      case 'Kuliner':
        return '🍔';
      case 'Otomotif':
        return '🚗';
      case 'Coding':
        return '💻';
      default:
        return '🎯';
    }
  }
}

/// Model untuk filter deep matching
class DeepMatchingFilter {
  final String? filterAgama;
  final List<String> filterHobi;
  final int? minUmur;
  final int? maxUmur;

  const DeepMatchingFilter({
    this.filterAgama,
    this.filterHobi = const [],
    this.minUmur,
    this.maxUmur,
  });

  /// Cek apakah filter kosong (tidak ada filter yang aktif)
  bool get isEmpty =>
      filterAgama == null &&
      filterHobi.isEmpty &&
      minUmur == null &&
      maxUmur == null;

  /// Cek apakah ada filter yang aktif
  bool get isNotEmpty => !isEmpty;

  /// Membuat salinan dengan perubahan
  DeepMatchingFilter copyWith({
    String? filterAgama,
    List<String>? filterHobi,
    int? minUmur,
    int? maxUmur,
    bool clearAgama = false,
    bool clearMinUmur = false,
    bool clearMaxUmur = false,
  }) {
    return DeepMatchingFilter(
      filterAgama: clearAgama ? null : (filterAgama ?? this.filterAgama),
      filterHobi: filterHobi ?? this.filterHobi,
      minUmur: clearMinUmur ? null : (minUmur ?? this.minUmur),
      maxUmur: clearMaxUmur ? null : (maxUmur ?? this.maxUmur),
    );
  }

  /// Menghitung umur dari tanggal lahir
  static int? hitungUmur(String? dobString) {
    if (dobString == null || dobString.isEmpty) return null;

    try {
      // Format: "dd MMMM yyyy" (contoh: "15 Januari 1995")
      final parts = dobString.split(' ');
      if (parts.length != 3) return null;

      final day = int.parse(parts[0]);
      final year = int.parse(parts[2]);

      // Mapping bulan Indonesia
      const bulanMap = {
        'Januari': 1,
        'Februari': 2,
        'Maret': 3,
        'April': 4,
        'Mei': 5,
        'Juni': 6,
        'Juli': 7,
        'Agustus': 8,
        'September': 9,
        'Oktober': 10,
        'November': 11,
        'Desember': 12,
      };

      final month = bulanMap[parts[1]];
      if (month == null) return null;

      final birthDate = DateTime(year, month, day);
      final now = DateTime.now();
      int umur = now.year - birthDate.year;

      // Kurangi 1 jika belum ulang tahun di tahun ini
      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        umur--;
      }

      return umur;
    } catch (e) {
      return null;
    }
  }
}
