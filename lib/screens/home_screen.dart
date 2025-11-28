import 'package:flutter/material.dart';
import '../widgets/menu_item_widget.dart';
import '../models/menu_item.dart';
import 'menu_detail_screen.dart';
import 'anamnesa_ai_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Menu items berdasarkan gambar
  final List<MenuItem> menuItems = [
    MenuItem(
      title: 'Anamnesa AI',
      icon: Icons.psychology,
      color: Colors.purple,
      iconImage: 'logo_anamnesa_ai.png',
      badge: 'Baru',
    ),
    MenuItem(
      title: 'Info Program\nJKN',
      icon: Icons.info_outline,
      color: Colors.blue,
      iconImage: 'logo_info_program_jkn.png',
    ),
    MenuItem(
      title: 'TELEHEALTH',
      icon: Icons.video_call,
      color: Colors.purple,
      iconImage: 'logo_telehealth.png',
    ),
    MenuItem(
      title: 'Info Riwayat\nPelayanan',
      icon: Icons.medical_services,
      color: Colors.red,
      iconImage: 'logo_info_riwayat_pelayanan.png',
    ),
    MenuItem(
      title: 'Bugar',
      icon: Icons.fitness_center,
      color: Colors.blue,
      iconImage: 'logo_bugar.png',
    ),
    MenuItem(
      title: 'NEW Rehab\n(Cicilan)',
      icon: Icons.medical_information,
      color: Colors.blue,
      iconImage: 'logo_new_rehab.png',
    ),
    MenuItem(
      title: 'Penambahan\nPeserta',
      icon: Icons.person_add,
      color: Colors.teal,
      iconImage: 'logo_penambahan_peserta.png',
    ),
    MenuItem(
      title: 'Info Peserta',
      icon: Icons.badge,
      color: Colors.green,
      iconImage: 'logo_info_peserta.png',
    ),
    MenuItem(
      title: 'SOS',
      icon: Icons.emergency,
      color: Colors.red,
      iconImage: 'logo_sos.png',
    ),
    MenuItem(
      title: 'Info Lokasi\nFaskes',
      icon: Icons.location_on,
      color: Colors.blue,
      iconImage: 'logo_info_lokasi.png',
    ),
    MenuItem(
      title: 'Perubahan\nData Peserta',
      icon: Icons.edit_document,
      color: Colors.orange,
      iconImage: 'logo_perubahan_data_peserta.png',
    ),
    MenuItem(
      title: 'Menu Lainnya',
      icon: Icons.apps,
      color: Colors.grey,
      iconImage: 'logo_menu_lainnya.png',
    ),
  ];

  void _navigateToMenu(MenuItem menuItem) {
    // Jika menu Anamnesa AI, navigasi ke screen khusus
    if (menuItem.title == 'Anamnesa AI') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AnamnesaAIScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MenuDetailScreen(menuItem: menuItem),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),

      // Body Halaman
      body: _selectedIndex == 0 ? _buildHomeContent() : _buildOtherPages(),

      // 1. Tombol Tengah (Floating Action Button)
      floatingActionButton: Transform.translate(
        offset: const Offset(
          0,
          15,
        ), // <--- Mainkan angka ini. Semakin besar, semakin turun.
        child: SizedBox(
          width: 65,
          height: 65,
          child: FloatingActionButton(
            backgroundColor: const Color(0xFF0D47A1), // Warna Biru JKN
            elevation: 4, // Bayangan agar terlihat "mengambang"
            shape: const CircleBorder(), // Pastikan bulat sempurna
            onPressed: () {
              setState(() {
                _selectedIndex = 2; // Index 2 adalah "Kartu"
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(
                1.0,
              ), // Padding agar icon tidak terlalu besar
              child: Image.asset(
                'assets/icons/logo_kartu.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),

      // Posisi Tombol Tengah (Docked di tengah)
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // 2. Bottom Navigation Bar (Custom menggunakan BottomAppBar)
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(), // Membuat lekukan (opsional)
        notchMargin: 2.0, // Jarak antara tombol bulat dan bar
        color: Colors.white,
        elevation: 10,
        padding: EdgeInsets.zero, // Hilangkan padding bawaan
        child: SizedBox(
          height: 50, // Tinggi navbar
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // KIRI
              _buildNavItem(icon: Icons.home, label: 'Home', index: 0),
              _buildNavItem(icon: Icons.article, label: 'Berita', index: 1),

              // TENGAH (Space kosong untuk teks "Kartu")
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedIndex = 2),
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.end, // Teks di paling bawah
                    children: [
                      const SizedBox(
                        height: 12,
                      ), // Space kosong untuk lingkaran biru
                      Text(
                        'Kartu',
                        style: TextStyle(
                          fontSize: 12,
                          color: _selectedIndex == 2
                              ? const Color(0xFF0D47A1)
                              : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8), // Jarak dari bawah
                    ],
                  ),
                ),
              ),

              // KANAN
              _buildNavItem(icon: Icons.help_outline, label: 'FAQ', index: 3),
              _buildNavItem(icon: Icons.person, label: 'Profil', index: 4),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Widget untuk membuat Item Navigasi Biasa
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF0D47A1) : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? const Color(0xFF0D47A1) : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with gradient (lebih ringan dari image)
            Container(
              height: 100,
              width: double.infinity, // Pastikan lebar memenuhi layar
              decoration: const BoxDecoration(
                // Menggunakan gambar background
                image: DecorationImage(
                  image: AssetImage('assets/icons/header_jkn.png'),
                  fit: BoxFit.fill, // Agar gambar memenuhi area container
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- LOGO IMAGE ---
                      // Langsung Image.asset agar background transparan (tidak dibungkus kotak putih)
                      Image.asset(
                        'assets/icons/jkn_icon.png',
                        width: 100, // Sesuaikan ukuran logo (misal 80 - 120)
                        height: 70,
                        fit: BoxFit.contain, // Agar rasio logo tetap terjaga
                      ),

                      // --- PROFILE ICON ---
                      const CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, color: Color(0xFF0D47A1)),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: 4),
            // User Info Card
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- BAGIAN HEADER (NAMA & VERSI) DILUAR CARD ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Hi, Azel',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Anggota Keluarga Non Aktif',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        'V4.14.0',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20), // Jarak antara header dan card
                // --- BAGIAN CARD ANTREAN ONLINE ---
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      20,
                    ), // Radius lebih bulat sesuai gambar
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start, // Rata atas
                    children: [
                      // 1. Gambar Icon di Kiri
                      Container(
                        width: 100, // Sesuaikan ukuran gambar
                        height: 100,
                        margin: const EdgeInsets.only(right: 12),
                        child: Image.asset(
                          'assets/icons/logo_antrean_online.png',
                          fit: BoxFit.contain,
                        ),
                      ),

                      // 2. Konten Teks & Tombol di Kanan
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Antrean Online',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0D47A1), // Warna biru JKN
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Untuk kunjungan lebih efisien tanpa harus menunggu lama.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                              ),
                            ),

                            const SizedBox(height: 12),
                            const Divider(thickness: 1, height: 1),
                            const SizedBox(height: 12),

                            // Tombol Ambil Antrean
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(
                                    0xFF0D47A1,
                                  ), // AppTheme.primaryBlue
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Ambil Antrean',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Menu Grid
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  return MenuItemWidget(
                    menuItem: menuItems[index],
                    onTap: () => _navigateToMenu(menuItems[index]),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),
            Container(
              // Tinggi disesuaikan (ratio 950x400 pada lebar 320 kira-kira butuh tinggi 135-150an)
              height: 150,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // --- CARD 1 ---
                  Container(
                    width: 320, // Lebar fixed
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    // ClipRRect agar sudut gambar melengkung mengikuti container
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/icons/news1.png',
                        fit: BoxFit.cover, // Memaksa gambar memenuhi kotak
                      ),
                    ),
                  ),

                  // --- CARD 2 (Duplicate) ---
                  Container(
                    width: 320,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/icons/news1.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherPages() {
    String pageTitle = '';
    switch (_selectedIndex) {
      case 1:
        pageTitle = 'Berita';
        break;
      case 2:
        pageTitle = 'Kartu';
        break;
      case 3:
        pageTitle = 'FAQ';
        break;
      case 4:
        pageTitle = 'Profil';
        break;
    }

    return Center(
      child: Text(
        pageTitle,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }
}
