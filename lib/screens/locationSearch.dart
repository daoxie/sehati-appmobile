import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/controllers/locationController.dart';
import '/models/chatModels.dart';
import '/models/locationModel.dart';

/// Screen untuk mencari pasangan berdasarkan lokasi
class LocationSearchScreen extends StatefulWidget {
  const LocationSearchScreen({super.key});

  @override
  State<LocationSearchScreen> createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends State<LocationSearchScreen> {
  // Mode pencarian: 0 = Berdasarkan Area, 1 = Terdekat (GPS)
  int _searchMode = 0;

  @override
  void initState() {
    super.initState();
    // Load lokasi user saat pertama kali masuk
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentUserLocation();
    });
  }

  // Fungsi untuk load lokasi user yang sedang login
  Future<void> _loadCurrentUserLocation() async {
    final controller = Provider.of<LocationController>(context, listen: false);
    final currentLocation = await controller.getCurrentUserLocation();

    if (currentLocation != null) {
      // Set provinsi dan kota saat ini
      controller.setProvinsi(currentLocation.provinsi);
      controller.setKota(currentLocation.kota);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9), // Hijau muda
      appBar: AppBar(
        title: const Text(
          'Cari Pengguna',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2E7D32), // Hijau gelap
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<LocationController>(
        builder: (context, controller, child) {
          return Column(
            children: [
              // Mode selector
              _buildModeSelector(),

              // Bagian filter lokasi (kondisional berdasarkan mode)
              if (_searchMode == 0)
                _buildFilterSection(controller)
              else
                _buildGPSSection(controller),

              // Tombol cari
              _buildSearchButton(controller),

              // Hasil pencarian
              Expanded(child: _buildSearchResults(controller)),
            ],
          );
        },
      ),
    );
  }

  /// Widget untuk memilih mode pencarian
  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF388E3C), // Hijau
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _searchMode = 0;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _searchMode == 0
                    ? const Color(0xFF4CAF50) // Hijau aktif
                    : const Color(0xFF81C784), // Hijau non-aktif
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.map, size: 20),
              label: const Text('Area'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _searchMode = 1;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _searchMode == 1
                    ? const Color(0xFF4CAF50) // Hijau aktif
                    : const Color(0xFF81C784), // Hijau non-aktif
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.near_me, size: 20),
              label: const Text('Terdekat'),
            ),
          ),
        ],
      ),
    );
  }

  /// Widget untuk GPS mode section
  Widget _buildGPSSection(LocationController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF388E3C), // Hijau
        border: Border(bottom: BorderSide(color: Color(0xFF2E7D32), width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Jarak Pencarian',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.location_searching,
                color: Color(0xFFFFFFFF),
              ), // Putih
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${controller.searchRadius.toInt()} km',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Radius dari lokasi Anda',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: controller.searchRadius,
            min: 1,
            max: 100,
            divisions: 99,
            activeColor: const Color(0xFF4CAF50), // Hijau
            inactiveColor: const Color(0xFF81C784), // Hijau muda
            label: '${controller.searchRadius.toInt()} km',
            onChanged: (value) {
              controller.setSearchRadius(value);
            },
          ),
        ],
      ),
    );
  }

  /// Widget untuk bagian filter lokasi
  Widget _buildFilterSection(LocationController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF388E3C), // Hijau
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dropdown untuk pilih provinsi
          const Text(
            'Pilih Provinsi',
            style: TextStyle(color: Colors.black87, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9), // Hijau sangat muda
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF4CAF50)), // Hijau
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: controller.selectedProvinsi,
                hint: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Pilih Provinsi',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
                icon: const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(Icons.arrow_drop_down, color: Colors.black54),
                ),
                dropdownColor: const Color(0xFF388E3C), // Hijau
                items: LocationData.provinsiList.map((String provinsi) {
                  return DropdownMenuItem<String>(
                    value: provinsi,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        provinsi,
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  controller.setProvinsi(newValue);
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Dropdown untuk pilih kota (hanya muncul kalau provinsi sudah dipilih)
          if (controller.selectedProvinsi != null) ...[
            const Text(
              'Pilih Kota (Opsional)',
              style: TextStyle(color: Colors.black87, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9), // Hijau sangat muda
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF4CAF50)), // Hijau
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  isExpanded: true,
                  value: controller.selectedKota,
                  hint: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Semua Kota',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                  icon: const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Icon(Icons.arrow_drop_down, color: Colors.black54),
                  ),
                  dropdownColor: const Color(0xFF388E3C), // Hijau
                  items: [
                    // Item untuk "Semua Kota"
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'Semua Kota',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                    ),
                    // Item untuk kota-kota yang tersedia
                    ...LocationData.getKotaByProvinsi(
                      controller.selectedProvinsi!,
                    ).map((String kota) {
                      return DropdownMenuItem<String?>(
                        value: kota,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            kota,
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                      );
                    }),
                  ],
                  onChanged: (String? newValue) {
                    controller.setKota(newValue);
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Widget untuk tombol cari
  Widget _buildSearchButton(LocationController controller) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Tombol cari
          Expanded(
            child: ElevatedButton(
              onPressed: controller.isLoading
                  ? null
                  : () {
                      // Panggil fungsi berdasarkan mode
                      if (_searchMode == 0) {
                        controller.searchByLocation();
                      } else {
                        controller.searchNearbyUsers();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50), // Hijau
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: controller.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchMode == 0 ? Icons.search : Icons.near_me,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _searchMode == 0 ? 'Cari Pengguna' : 'Cari Terdekat',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(width: 12),

          // Tombol reset
          ElevatedButton(
            onPressed: controller.isLoading
                ? null
                : () {
                    controller.resetFilter();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF81C784), // Hijau muda
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
    );
  }

  /// Widget untuk menampilkan hasil pencarian
  Widget _buildSearchResults(LocationController controller) {
    // Kalau sedang loading
    if (controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)), // Hijau
        ),
      );
    }

    // Kalau ada error
    if (controller.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off, size: 80, color: Colors.black26),
              const SizedBox(height: 16),
              Text(
                controller.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    // Kalau belum ada hasil pencarian
    if (controller.nearbyUsers.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on, size: 80, color: Colors.black26),
              SizedBox(height: 16),
              Text(
                'Pilih lokasi dan tekan tombol "Cari Pengguna"\nuntuk menemukan pasangan di sekitar Anda',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    // Tampilkan hasil pencarian
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: controller.nearbyUsers.length,
      itemBuilder: (context, index) {
        final user = controller.nearbyUsers[index];
        return _buildUserCard(user);
      },
    );
  }

  /// Widget untuk menampilkan card user
  Widget _buildUserCard(ChatUser user) {
    return Card(
      color: const Color(0xFF388E3C), // Hijau
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Foto profil
            CircleAvatar(
              radius: 30,
              backgroundColor: const Color(0xFF4CAF50), // Hijau
              backgroundImage:
                  user.imageUrl != null && user.imageUrl!.isNotEmpty
                  ? NetworkImage(user.imageUrl!)
                  : null,
              child: user.imageUrl == null || user.imageUrl!.isEmpty
                  ? Text(
                      user.username.isNotEmpty
                          ? user.username[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),

            const SizedBox(width: 16),

            // Info user
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Color(0xFF2E7D32), // Hijau gelap
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          user.bio ?? 'Tidak ada bio',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Tombol lihat profil
            IconButton(
              onPressed: () {
                _showUserProfile(user);
              },
              icon: const Icon(
                Icons.arrow_forward_ios,
                color: Color(0xFF2E7D32), // Hijau gelap
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Fungsi untuk menampilkan profil user (sementara pakai dialog)
  void _showUserProfile(ChatUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF388E3C), // Hijau
        title: Text(user.username, style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user.imageUrl != null && user.imageUrl!.isNotEmpty)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    user.imageUrl!,
                    height: 200,
                    width: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            if (user.gender != null)
              Text(
                'Gender: ${user.gender}',
                style: const TextStyle(color: Colors.white70),
              ),
            const SizedBox(height: 8),
            Text(
              'Bio: ${user.bio ?? "Tidak ada bio"}',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Tutup',
              style: TextStyle(color: Color(0xFFFFFFFF)), // Putih
            ),
          ),
        ],
      ),
    );
  }
}
