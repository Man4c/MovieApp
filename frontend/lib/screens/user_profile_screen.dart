import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_video_app/providers/watch_history_provider.dart';
import 'package:flutter_video_app/providers/favorites_provider.dart';
import 'package:flutter_video_app/screens/favorites_screen.dart';
import 'package:flutter_video_app/screens/watch_history_screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isSubscribed = true;
  final DateTime _subscriptionEndDate = DateTime.now().add(
    const Duration(days: 30),
  );

  @override
  Widget build(BuildContext context) {
    return Consumer2<FavoritesProvider, WatchHistoryProvider>(
      builder: (context, favoritesProvider, watchHistoryProvider, _) {
        final favoritesCount = favoritesProvider.favorites.length;
        final watchHistoryCount = watchHistoryProvider.watchHistory.length;

        return Scaffold(
          backgroundColor: const Color(0xFF1A1D21),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF23262A),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: const Color(0xFFE53935),
                              child: const Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'John Doe',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'john.doe@email.com',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.white70,
                              ),
                              onPressed: () {
                                // TODO: Navigate to edit profile
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Subscription Status Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C2F33),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      _isSubscribed
                                          ? const Color(
                                            0xFFE53935,
                                          ).withOpacity(0.1)
                                          : Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _isSubscribed
                                      ? Icons.star
                                      : Icons.star_border,
                                  color:
                                      _isSubscribed
                                          ? const Color(0xFFE53935)
                                          : Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isSubscribed
                                          ? 'Paket Premium Aktif'
                                          : 'Belum Berlangganan',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (_isSubscribed) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Berakhir pada ${_subscriptionEndDate.day}/${_subscriptionEndDate.month}/${_subscriptionEndDate.year}',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  // TODO: Navigate to subscription management
                                },
                                child: Text(
                                  _isSubscribed ? 'Kelola' : 'Berlangganan',
                                  style: const TextStyle(
                                    color: Color(0xFFE53935),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Menu Items
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        _buildMenuItem(
                          icon: Icons.favorite,
                          title: 'Favorit',
                          subtitle: '$favoritesCount item tersimpan',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const FavoritesScreen(),
                              ),
                            );
                          },
                        ),
                        _buildMenuItem(
                          icon: Icons.history,
                          title: 'Riwayat Nonton',
                          subtitle: '$watchHistoryCount item terakhir',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const WatchHistoryScreen(),
                              ),
                            );
                          },
                        ),
                        _buildMenuItem(
                          icon: Icons.settings,
                          title: 'Pengaturan',
                          subtitle: 'Notifikasi, privasi, dan lainnya',
                          onTap: () {
                            // TODO: Navigate to settings
                          },
                        ),
                        _buildMenuItem(
                          icon: Icons.help_outline,
                          title: 'Bantuan',
                          subtitle: 'FAQ dan dukungan',
                          onTap: () {
                            // TODO: Navigate to help
                          },
                        ),
                        const SizedBox(height: 24),
                        // Logout Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF23262A),
                              foregroundColor: const Color(0xFFE53935),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              // TODO: Show logout confirmation dialog
                            },
                            child: const Text(
                              'Keluar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  WatchHistorySection(
                    items: [
                      WatchHistoryItem(
                        thumbnailUrl:
                            'https://image.tmdb.org/t/p/w500/yourimage1.jpg',
                        episodeInfo: 'E1',
                        title: 'Tarot',
                      ),
                      WatchHistoryItem(
                        thumbnailUrl:
                            'https://image.tmdb.org/t/p/w500/yourimage2.jpg',
                        episodeInfo: 'SMusim 5:E8',
                        title: 'Demon Slayer: Kimetsu...',
                      ),
                      // dst.
                    ],
                    onSeeAll: () {
                      // Navigasi ke halaman riwayat lengkap
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF23262A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: const Color(0xFFE53935), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}

class WatchHistoryItem {
  final String thumbnailUrl;
  final String episodeInfo;
  final String title;

  WatchHistoryItem({
    required this.thumbnailUrl,
    required this.episodeInfo,
    required this.title,
  });
}

class WatchHistorySection extends StatelessWidget {
  final List<WatchHistoryItem> items;
  final VoidCallback onSeeAll;

  const WatchHistorySection({
    Key? key,
    required this.items,
    required this.onSeeAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Judul bagian
          const Text(
            'Riwayat Tontonan',
            style: TextStyle(
              color: Color(0xFFB0B0B0),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          // Kartu utama
          Container(
            decoration: BoxDecoration(
              color: Color(0xFF23262A),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header kartu
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.white),
                      const SizedBox(width: 8),
                      const Text(
                        'Riwayat Tontonan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          Icons.chevron_right,
                          color: Colors.white,
                        ),
                        onPressed: onSeeAll,
                      ),
                    ],
                  ),
                ),
                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'Belum ada riwayat tontonan',
                        style: TextStyle(color: Colors.grey[400], fontSize: 16),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 140,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    item.thumbnailUrl,
                                    width: 120,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  left: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0099E6),
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(8),
                                        bottomLeft: Radius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      item.episodeInfo,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: 120,
                              child: Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
