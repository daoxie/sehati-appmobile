import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/models/chatModels.dart';
import '/models/locationModel.dart';

/// Controller untuk mencari pasangan berdasarkan lokasi
/// Kode ini dibuat sederhana agar mudah dipahami
class LocationController with ChangeNotifier {
  // Variabel untuk Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Variabel untuk menyimpan user yang login
  User? _currentUser;
  
  // List untuk menyimpan pengguna yang ditemukan berdasarkan lokasi
  List<ChatUser> _nearbyUsers = [];
  
  // Variabel untuk loading
  bool _isLoading = false;
  
  // Variabel untuk pesan error
  String? _errorMessage;
  
  // Lokasi yang dipilih untuk filter
  String? _selectedProvinsi;
  String? _selectedKota;
  
  // Radius untuk pencarian lokasi terdekat (dalam km)
  double _searchRadius = 10.0; // Default 10 km
  
  // Getter agar bisa diakses dari luar
  List<ChatUser> get nearbyUsers => _nearbyUsers;
  bool get isLoading => _isLoading;
  double get searchRadius => _searchRadius;
  String? get errorMessage => _errorMessage;
  String? get selectedProvinsi => _selectedProvinsi;
  String? get selectedKota => _selectedKota;
  
  // Constructor - jalan saat controller dibuat
  LocationController() {
    _currentUser = _auth.currentUser;
    
    // Dengarkan perubahan login/logout
    _auth.authStateChanges().listen((User? user) {
      _currentUser = user;
      if (user == null) {
        // Kalau user logout, kosongkan data
        _nearbyUsers = [];
        _selectedProvinsi = null;
        _selectedKota = null;
        notifyListeners();
      }
    });
  }
  
  /// Fungsi untuk set provinsi yang dipilih
  void setProvinsi(String? provinsi) {
    _selectedProvinsi = provinsi;
    _selectedKota = null; // Reset kota kalau provinsi berubah
    _nearbyUsers = []; // Kosongkan hasil pencarian
    notifyListeners();
  }
  
  /// Fungsi untuk set kota yang dipilih
  void setKota(String? kota) {
    _selectedKota = kota;
    notifyListeners();
  }
  
  /// Fungsi untuk set radius pencarian (dalam km)
  void setSearchRadius(double radius) {
    _searchRadius = radius;
    notifyListeners();
  }
  
  /// Fungsi utama untuk mencari pengguna berdasarkan lokasi
  Future<void> searchByLocation() async {
    // Cek apakah user sudah login
    if (_currentUser == null) {
      _errorMessage = 'Anda harus login terlebih dahulu';
      notifyListeners();
      return;
    }
    
    // Cek apakah provinsi sudah dipilih
    if (_selectedProvinsi == null || _selectedProvinsi!.isEmpty) {
      _errorMessage = 'Silakan pilih provinsi terlebih dahulu';
      notifyListeners();
      return;
    }
    
    // Mulai loading
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      // Ambil semua user dari Firebase
      QuerySnapshot usersSnapshot = await _firestore.collection('users').get();
      
      // List sementara untuk menyimpan hasil
      List<ChatUser> hasilPencarian = [];
      
      // Looping setiap user yang ada di database
      for (var doc in usersSnapshot.docs) {
        // Ambil data user
        final data = doc.data() as Map<String, dynamic>?;
        
        // Kalau data kosong, skip
        if (data == null) continue;
        
        // Ubah data jadi ChatUser
        ChatUser user = ChatUser.fromMap(data, documentId: doc.id);
        
        // Skip kalau ini adalah user sendiri
        if (user.uid == _currentUser!.uid) continue;
        
        // Cek apakah user punya data lokasi
        if (data['location'] == null) continue;
        
        // Ambil data lokasi user
        Map<String, dynamic> locationData = data['location'] as Map<String, dynamic>;
        String userProvinsi = locationData['provinsi'] ?? '';
        String userKota = locationData['kota'] ?? '';
        
        // Cek apakah provinsi sama
        bool provinsiSama = userProvinsi == _selectedProvinsi;
        
        // Kalau provinsi tidak sama, skip
        if (!provinsiSama) continue;
        
        // Kalau kota sudah dipilih, cek apakah kota sama
        if (_selectedKota != null && _selectedKota!.isNotEmpty) {
          bool kotaSama = userKota == _selectedKota;
          if (!kotaSama) continue;
        }
        
        // Kalau sampai sini, berarti user cocok dengan filter
        hasilPencarian.add(user);
      }
      
      // Simpan hasil pencarian
      _nearbyUsers = hasilPencarian;
      
      // Kalau tidak ada hasil
      if (_nearbyUsers.isEmpty) {
        if (_selectedKota != null && _selectedKota!.isNotEmpty) {
          _errorMessage = 'Tidak ada pengguna ditemukan di $_selectedKota, $_selectedProvinsi';
        } else {
          _errorMessage = 'Tidak ada pengguna ditemukan di $_selectedProvinsi';
        }
      }
      
    } catch (e) {
      // Kalau ada error, tampilkan pesan
      _errorMessage = 'Terjadi kesalahan: $e';
      print('Error saat mencari user berdasarkan lokasi: $e');
    } finally {
      // Selesai loading
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Fungsi untuk reset filter dan hasil pencarian
  void resetFilter() {
    _selectedProvinsi = null;
    _selectedKota = null;
    _nearbyUsers = [];
    _errorMessage = null;
    notifyListeners();
  }
  
  /// Fungsi untuk clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  /// Fungsi untuk mendapatkan lokasi user yang sedang login
  Future<UserLocation?> getCurrentUserLocation() async {
    if (_currentUser == null) return null;
    
    try {
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .get();
      
      if (!userDoc.exists) return null;
      
      final data = userDoc.data() as Map<String, dynamic>?;
      if (data == null || data['location'] == null) return null;
      
      return UserLocation.fromMap(data['location'] as Map<String, dynamic>);
      
    } catch (e) {
      print('Error mendapatkan lokasi user: $e');
      return null;
    }
  }
  
  /// Fungsi untuk update lokasi user yang sedang login
  Future<void> updateCurrentUserLocation(UserLocation location) async {
    if (_currentUser == null) {
      _errorMessage = 'Anda harus login terlebih dahulu';
      notifyListeners();
      return;
    }
    
    try {
      await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .update({
            'location': location.toMap(),
          });
      
      print('Lokasi berhasil diupdate');
      
    } catch (e) {
      _errorMessage = 'Gagal mengupdate lokasi: $e';
      print('Error update lokasi: $e');
      notifyListeners();
    }
  }
  
  /// Fungsi untuk mencari pengguna terdekat berdasarkan GPS
  /// User harus sudah mengatur lokasi GPS mereka
  Future<void> searchNearbyUsers() async {
    // Cek apakah user sudah login
    if (_currentUser == null) {
      _errorMessage = 'Anda harus login terlebih dahulu';
      notifyListeners();
      return;
    }
    
    // Mulai loading
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      // Ambil lokasi user yang sedang login
      UserLocation? myLocation = await getCurrentUserLocation();
      
      // Cek apakah user punya GPS coordinates
      if (myLocation == null || !myLocation.hasValidCoordinates) {
        _errorMessage = 'Anda harus mengatur lokasi GPS terlebih dahulu.\nBuka Profile → Atur Lokasi';
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      // Ambil semua user dari Firebase
      QuerySnapshot usersSnapshot = await _firestore.collection('users').get();
      
      // List untuk menyimpan user dengan jarak
      List<Map<String, dynamic>> usersWithDistance = [];
      
      // Looping setiap user
      for (var doc in usersSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;
        
        // Ubah data jadi ChatUser
        ChatUser user = ChatUser.fromMap(data, documentId: doc.id);
        
        // Skip kalau ini adalah user sendiri
        if (user.uid == _currentUser!.uid) continue;
        
        // Cek apakah user punya data lokasi
        if (data['location'] == null) continue;
        
        // Ambil lokasi user
        UserLocation userLocation = UserLocation.fromMap(
          data['location'] as Map<String, dynamic>,
        );
        
        // Cek apakah user punya GPS coordinates
        if (!userLocation.hasValidCoordinates) continue;
        
        // Hitung jarak antara saya dengan user ini
        double? distance = myLocation.distanceTo(userLocation);
        
        // Kalau jarak null atau lebih dari radius, skip
        if (distance == null || distance > _searchRadius) continue;
        
        // Simpan user dengan jaraknya
        usersWithDistance.add({
          'user': user,
          'distance': distance,
        });
      }
      
      // Sort berdasarkan jarak (yang terdekat di atas)
      usersWithDistance.sort((a, b) {
        double distA = a['distance'] as double;
        double distB = b['distance'] as double;
        return distA.compareTo(distB);
      });
      
      // Ambil hanya ChatUser saja (tanpa jarak)
      _nearbyUsers = usersWithDistance
          .map((item) => item['user'] as ChatUser)
          .toList();
      
      // Kalau tidak ada hasil
      if (_nearbyUsers.isEmpty) {
        _errorMessage = 'Tidak ada pengguna ditemukan dalam radius $_searchRadius km dari lokasi Anda';
      }
      
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      print('Error saat mencari user terdekat: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Fungsi untuk mendapatkan jarak user dengan user lain
  Future<double?> getDistanceToUser(String userId) async {
    if (_currentUser == null) return null;
    
    try {
      // Ambil lokasi saya
      UserLocation? myLocation = await getCurrentUserLocation();
      if (myLocation == null || !myLocation.hasValidCoordinates) return null;
      
      // Ambil lokasi user lain
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      
      if (!userDoc.exists) return null;
      
      final data = userDoc.data() as Map<String, dynamic>?;
      if (data == null || data['location'] == null) return null;
      
      UserLocation userLocation = UserLocation.fromMap(
        data['location'] as Map<String, dynamic>,
      );
      
      if (!userLocation.hasValidCoordinates) return null;
      
      // Hitung jarak
      return myLocation.distanceTo(userLocation);
      
    } catch (e) {
      print('Error menghitung jarak: $e');
      return null;
    }
  }
}
