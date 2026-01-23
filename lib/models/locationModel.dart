import 'dart:math';

/// Model untuk data lokasi pengguna dengan GPS coordinates
class UserLocation {
  final String provinsi;
  final String kota;
  final String? kecamatan; // opsional
  final double? latitude;  // GPS coordinate
  final double? longitude; // GPS coordinate

  UserLocation({
    required this.provinsi,
    required this.kota,
    this.kecamatan,
    this.latitude,
    this.longitude,
  });

  /// Membuat objek UserLocation dari Map (dari Firebase)
  factory UserLocation.fromMap(Map<String, dynamic> map) {
    return UserLocation(
      provinsi: map['provinsi'] ?? '',
      kota: map['kota'] ?? '',
      kecamatan: map['kecamatan'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
    );
  }

  /// Mengubah objek UserLocation ke Map (untuk Firebase)
  Map<String, dynamic> toMap() {
    return {
      'provinsi': provinsi,
      'kota': kota,
      'kecamatan': kecamatan,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  /// Mendapatkan lokasi lengkap dalam bentuk string
  String get fullLocation {
    if (kecamatan != null && kecamatan!.isNotEmpty) {
      return '$kecamatan, $kota, $provinsi';
    }
    return '$kota, $provinsi';
  }

  /// Cek apakah lokasi sama (provinsi dan kota)
  bool isSameLocation(UserLocation other) {
    return provinsi == other.provinsi && kota == other.kota;
  }
  
  /// Cek apakah memiliki koordinat GPS yang valid
  bool get hasValidCoordinates {
    return latitude != null && longitude != null;
  }
  
  /// Menghitung jarak antara lokasi ini dengan lokasi lain (dalam kilometer)
  /// Menggunakan formula Haversine
  double? distanceTo(UserLocation other) {
    // Kalau salah satu tidak punya koordinat, return null
    if (!hasValidCoordinates || !other.hasValidCoordinates) {
      return null;
    }
    
    // Radius bumi dalam kilometer
    const double earthRadiusKm = 6371.0;
    
    // Konversi derajat ke radian
    double lat1Rad = _degreesToRadians(latitude!);
    double lat2Rad = _degreesToRadians(other.latitude!);
    double deltaLatRad = _degreesToRadians(other.latitude! - latitude!);
    double deltaLonRad = _degreesToRadians(other.longitude! - longitude!);
    
    // Formula Haversine
    double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLonRad / 2) * sin(deltaLonRad / 2);
    
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    // Jarak dalam kilometer
    double distance = earthRadiusKm * c;
    
    return distance;
  }
  
  /// Helper: Konversi derajat ke radian
  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

}

/// Daftar provinsi di Indonesia (contoh, bisa diperluas)
class LocationData {
  static final List<String> provinsiList = [
    'Aceh',
    'Sumatera Utara',
    'Sumatera Barat',
    'Riau',
    'Kepulauan Riau',
    'Jambi',
    'Sumatera Selatan',
    'Bangka Belitung',
    'Bengkulu',
    'Lampung',
    'DKI Jakarta',
    'Jawa Barat',
    'Banten',
    'Jawa Tengah',
    'DI Yogyakarta',
    'Jawa Timur',
    'Bali',
    'Nusa Tenggara Barat',
    'Nusa Tenggara Timur',
    'Kalimantan Barat',
    'Kalimantan Tengah',
    'Kalimantan Selatan',
    'Kalimantan Timur',
    'Kalimantan Utara',
    'Sulawesi Utara',
    'Gorontalo',
    'Sulawesi Tengah',
    'Sulawesi Barat',
    'Sulawesi Selatan',
    'Sulawesi Tenggara',
    'Maluku',
    'Maluku Utara',
    'Papua',
    'Papua Barat',
    'Papua Selatan',
    'Papua Tengah',
    'Papua Pegunungan',
  ];

  /// Daftar kota berdasarkan provinsi (contoh untuk beberapa provinsi)
  /// Dalam aplikasi nyata, ini bisa diambil dari API atau database
  static final Map<String, List<String>> kotaByProvinsi = {
    'DKI Jakarta': [
      'Jakarta Pusat',
      'Jakarta Utara',
      'Jakarta Barat',
      'Jakarta Selatan',
      'Jakarta Timur',
      'Kepulauan Seribu',
    ],
    'Jawa Barat': [
      'Bandung',
      'Bekasi',
      'Bogor',
      'Cirebon',
      'Depok',
      'Sukabumi',
      'Tasikmalaya',
      'Cimahi',
      'Banjar',
    ],
    'Jawa Tengah': [
      'Semarang',
      'Surakarta',
      'Salatiga',
      'Pekalongan',
      'Tegal',
      'Magelang',
    ],
    'Jawa Timur': [
      'Surabaya',
      'Malang',
      'Kediri',
      'Blitar',
      'Mojokerto',
      'Madiun',
      'Pasuruan',
      'Probolinggo',
      'Batu',
    ],
    'DI Yogyakarta': [
      'Yogyakarta',
      'Bantul',
      'Sleman',
      'Kulon Progo',
      'Gunung Kidul',
    ],
    'Bali': [
      'Denpasar',
      'Badung',
      'Gianyar',
      'Tabanan',
      'Buleleng',
      'Karangasem',
      'Klungkung',
      'Jembrana',
    ],
    // Tambahkan provinsi lain sesuai kebutuhan
  };

  /// Mendapatkan daftar kota berdasarkan provinsi
  static List<String> getKotaByProvinsi(String provinsi) {
    return kotaByProvinsi[provinsi] ?? [];
  }
}
