import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '/controllers/locationController.dart';
import '/models/locationModel.dart';

/// Screen untuk mengatur lokasi user
class SetLocationScreen extends StatefulWidget {
  const SetLocationScreen({super.key});

  @override
  State<SetLocationScreen> createState() => _SetLocationScreenState();
}

class _SetLocationScreenState extends State<SetLocationScreen> {
  // Variabel untuk menyimpan pilihan lokasi
  String? _selectedProvinsi;
  String? _selectedKota;
  String? _selectedKecamatan;

  // Variabel untuk GPS coordinates
  double? _latitude;
  double? _longitude;
  bool _isGettingLocation = false;

  // Controller untuk kecamatan (opsional)
  final TextEditingController _kecamatanController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load lokasi user saat pertama kali masuk
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentLocation();
    });
  }

  @override
  void dispose() {
    _kecamatanController.dispose();
    super.dispose();
  }

  // Fungsi untuk load lokasi user yang sedang login
  Future<void> _loadCurrentLocation() async {
    final controller = Provider.of<LocationController>(context, listen: false);
    final currentLocation = await controller.getCurrentUserLocation();

    if (currentLocation != null) {
      setState(() {
        _selectedProvinsi = currentLocation.provinsi;
        _selectedKota = currentLocation.kota;
        _selectedKecamatan = currentLocation.kecamatan;
        _latitude = currentLocation.latitude;
        _longitude = currentLocation.longitude;
        if (currentLocation.kecamatan != null) {
          _kecamatanController.text = currentLocation.kecamatan!;
        }
      });
    }
  }

  // Fungsi untuk mendapatkan GPS dari perangkat
  Future<void> _getCurrentGPS() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      // Cek apakah GPS service aktif
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'GPS tidak aktif. Mohon aktifkan GPS di perangkat Anda',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() {
          _isGettingLocation = false;
        });
        return;
      }

      // Cek permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Izin akses lokasi ditolak'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() {
            _isGettingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Izin akses lokasi ditolak permanen. Ubah di pengaturan aplikasi',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
        setState(() {
          _isGettingLocation = false;
        });
        return;
      }

      // Dapatkan posisi GPS
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _isGettingLocation = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Koordinat GPS berhasil didapatkan!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isGettingLocation = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mendapatkan GPS: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Fungsi untuk save lokasi
  Future<void> _saveLocation() async {
    // Validasi: provinsi harus dipilih
    if (_selectedProvinsi == null || _selectedProvinsi!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih provinsi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validasi: kota harus dipilih
    if (_selectedKota == null || _selectedKota!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih kota'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Buat objek lokasi dengan GPS coordinates
    final location = UserLocation(
      provinsi: _selectedProvinsi!,
      kota: _selectedKota!,
      kecamatan: _kecamatanController.text.trim().isNotEmpty
          ? _kecamatanController.text.trim()
          : null,
      latitude: _latitude,
      longitude: _longitude,
    );

    // Simpan ke Firebase
    final controller = Provider.of<LocationController>(context, listen: false);
    await controller.updateCurrentUserLocation(location);

    // Cek apakah ada error
    if (controller.errorMessage != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(controller.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Berhasil
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lokasi berhasil disimpan!'),
            backgroundColor: Colors.green,
          ),
        );
        // Kembali ke halaman sebelumnya
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text('Atur Lokasi', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF16213E),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF0F3460)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFFE94560)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Atur lokasi Anda agar pengguna lain dapat menemukan Anda',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Dropdown provinsi
            const Text(
              'Provinsi *',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF0F3460)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedProvinsi,
                  hint: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Pilih Provinsi',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                  icon: const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Icon(Icons.arrow_drop_down, color: Colors.white70),
                  ),
                  dropdownColor: const Color(0xFF16213E),
                  items: LocationData.provinsiList.map((String provinsi) {
                    return DropdownMenuItem<String>(
                      value: provinsi,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          provinsi,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedProvinsi = newValue;
                      _selectedKota = null; // Reset kota kalau provinsi berubah
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Dropdown kota
            const Text(
              'Kota/Kabupaten *',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF0F3460)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedKota,
                  hint: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      _selectedProvinsi == null
                          ? 'Pilih provinsi terlebih dahulu'
                          : 'Pilih Kota/Kabupaten',
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ),
                  icon: const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Icon(Icons.arrow_drop_down, color: Colors.white70),
                  ),
                  dropdownColor: const Color(0xFF16213E),
                  items: _selectedProvinsi == null
                      ? []
                      : LocationData.getKotaByProvinsi(_selectedProvinsi!).map((
                          String kota,
                        ) {
                          return DropdownMenuItem<String>(
                            value: kota,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                kota,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          );
                        }).toList(),
                  onChanged: _selectedProvinsi == null
                      ? null
                      : (String? newValue) {
                          setState(() {
                            _selectedKota = newValue;
                          });
                        },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Input kecamatan (opsional)
            const Text(
              'Kecamatan (Opsional)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _kecamatanController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Masukkan kecamatan (opsional)',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF16213E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF0F3460)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF0F3460)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE94560)),
                ),
                prefixIcon: const Icon(
                  Icons.location_city,
                  color: Colors.white70,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Divider
            const Divider(color: Color(0xFF0F3460)),

            const SizedBox(height: 16),

            // GPS Section
            const Text(
              'Koordinat GPS (Untuk Pencarian Terdekat)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Info GPS
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF0F3460)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.gps_fixed,
                        color: Color(0xFFE94560),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _latitude != null && _longitude != null
                              ? 'Koordinat tersimpan: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}'
                              : 'Belum ada koordinat GPS',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isGettingLocation ? null : _getCurrentGPS,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F3460),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: _isGettingLocation
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.my_location),
                      label: Text(
                        _isGettingLocation
                            ? 'Mendapatkan GPS...'
                            : 'Ambil Koordinat GPS Saya',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '💡 GPS diperlukan agar Anda bisa muncul di pencarian "Pengguna Terdekat"',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Tombol simpan
            ElevatedButton(
              onPressed: _saveLocation,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE94560),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Simpan Lokasi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
