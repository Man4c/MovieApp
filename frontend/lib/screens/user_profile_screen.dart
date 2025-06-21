import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_video_app/providers/auth_provider.dart';
import 'package:flutter_video_app/providers/watch_history_provider.dart';
import 'package:flutter_video_app/providers/favorites_provider.dart';
import 'package:flutter_video_app/screens/admin_add_movie_screen.dart'; // Import AdminAddMovieScreen
import 'package:flutter_video_app/screens/admin_user_list_screen.dart'; // Import AdminUserListScreen
import 'package:flutter_video_app/screens/favorites_screen.dart';
import 'package:flutter_video_app/screens/subscription_screen.dart'; // Import SubscriptionScreen
import 'package:flutter_video_app/screens/watch_history_screen.dart';
import 'package:intl/intl.dart'; // For date formatting

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _usernameFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  late TextEditingController _newUsernameController;
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;

  bool _isLoadingUsername = false;
  bool _isLoadingPassword = false;

  @override
  void initState() {
    super.initState();
    _newUsernameController = TextEditingController();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();

    // Add this to refresh data when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        authProvider.refreshUserData();
      }
    });
  }

  @override
  void dispose() {
    _newUsernameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Consumer2<FavoritesProvider, WatchHistoryProvider>(
      builder: (context, favoritesProvider, watchHistoryProvider, child) {
        final favoritesCount = favoritesProvider.favorites.length;
        final watchHistoryCount = watchHistoryProvider.watchHistory.length;
        final recentHistory =
            watchHistoryProvider.watchHistory
                .take(5)
                .map((video) => WatchHistoryItem.fromVideo(video))
                .toList();

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
                    decoration: const BoxDecoration(
                      color: Color(0xFF23262A),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 40,
                              backgroundColor: Color(0xFFE53935),
                              child: Icon(
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
                                  Text(
                                    authProvider.user?.name ?? 'Guest User',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    authProvider.user?.email ?? 'No email',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (authProvider.isAuthenticated &&
                                authProvider.user?.googleId == null)
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.white70,
                                ),
                                onPressed: () {
                                  if (authProvider.user != null) {
                                    _newUsernameController.text =
                                        authProvider.user!.name;
                                  }
                                  _showUpdateUsernameDialog(
                                    context,
                                    authProvider,
                                  );
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Subscription Status Card
                        Builder(
                          builder: (context) {
                            final user = authProvider.user;
                            final subscription = user?.subscription;
                            final bool isActiveSubscriber =
                                authProvider.hasActiveSubscription;

                            // Format subscription details
                            String planName = _getPlanName(
                              subscription?.planId,
                            );
                            String statusText =
                                subscription?.status?.toUpperCase() ??
                                'NO SUBSCRIPTION';
                            String endDateText =
                                subscription?.currentPeriodEnd != null
                                    ? DateFormat(
                                      'dd MMM yyyy',
                                    ).format(subscription!.currentPeriodEnd!)
                                    : 'N/A';
                            String subscriptionIdText =
                                subscription?.subscriptionId ?? 'N/A';

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2C2F33),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            isActiveSubscriber
                                                ? Icons.stars
                                                : Icons.star_border,
                                            color:
                                                isActiveSubscriber
                                                    ? const Color(0xFFE53935)
                                                    : Colors.grey,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            isActiveSubscriber
                                                ? 'Active Subscription'
                                                : 'No Active Subscription',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.refresh,
                                          color: Colors.white70,
                                        ),
                                        onPressed:
                                            () =>
                                                authProvider.refreshUserData(),
                                      ),
                                    ],
                                  ),
                                  if (isActiveSubscriber) ...[
                                    const SizedBox(height: 16),
                                    _buildSubscriptionDetail(
                                      'Plan',
                                      planName,
                                      Icons.card_membership,
                                    ),
                                    const SizedBox(height: 8),
                                    _buildSubscriptionDetail(
                                      'Status',
                                      statusText,
                                      Icons.info_outline,
                                    ),
                                    const SizedBox(height: 8),
                                    _buildSubscriptionDetail(
                                      'Renewal',
                                      endDateText,
                                      Icons.event_repeat,
                                    ),
                                    const SizedBox(height: 8),
                                    _buildSubscriptionDetail(
                                      'ID',
                                      subscriptionIdText,
                                      Icons.confirmation_number_outlined,
                                    ),
                                  ] else
                                    Text(
                                      'Subscribe to unlock premium features and content',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFFE53935,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                      ),
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder:
                                                (_) =>
                                                    const SubscriptionScreen(),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        isActiveSubscriber
                                            ? 'Manage Subscription'
                                            : 'Subscribe Now',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
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
                          title: 'Pengaturan Akun',
                          subtitle: 'Ubah username & password',
                          onTap: () {
                            if (authProvider.isAuthenticated &&
                                authProvider.user?.googleId == null) {
                              _showChangePasswordDialog(context, authProvider);
                            } else if (authProvider.isAuthenticated &&
                                authProvider.user?.googleId != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Akun Google tidak dapat mengubah password disini.',
                                  ),
                                ),
                              );
                            }
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
                        _buildMenuItem(
                          // Refresh User Data Button
                          icon: Icons.refresh,
                          title: 'Refresh Account Data',
                          subtitle:
                              'Update your profile and subscription status',
                          onTap: () async {
                            try {
                              await authProvider.refreshUserData();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'User data refreshed successfully!',
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Failed to refresh user data: $e',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                        if (authProvider.user?.role == 'admin')
                          _buildMenuItem(
                            icon: Icons.manage_accounts,
                            title: 'User Management',
                            subtitle: 'View and manage all users',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const AdminUserListScreen(),
                                ),
                              );
                            },
                          ),
                        if (authProvider.user?.role == 'admin')
                          _buildMenuItem(
                            icon:
                                Icons
                                    .movie_creation_outlined, // Or Icons.add_to_photos, Icons.video_call
                            title: 'Add New Movie',
                            subtitle: 'Add a new movie to the catalog',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const AdminAddMovieScreen(),
                                ),
                              );
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
                  // Watch History Section with actual data
                  WatchHistorySection(
                    items: recentHistory,
                    onSeeAll: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WatchHistoryScreen(),
                        ),
                      );
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

  void _showUpdateUsernameDialog(
    BuildContext context,
    AuthProvider authProvider,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C2F33),
          title: const Text(
            'Ubah Username',
            style: TextStyle(color: Colors.white),
          ),
          content: Form(
            key: _usernameFormKey,
            child: TextFormField(
              controller: _newUsernameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Username Baru',
                labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.7)),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFE53935)),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Username tidak boleh kosong';
                }
                if (value.length < 3) {
                  return 'Username minimal 3 karakter';
                }
                if (value == authProvider.user?.name) {
                  return 'Username baru tidak boleh sama dengan yang sekarang';
                }
                return null;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Batal',
                style: TextStyle(color: Colors.white70),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
              ),
              child:
                  _isLoadingUsername
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Text('Simpan'),
              onPressed: () async {
                if (_usernameFormKey.currentState!.validate()) {
                  setState(() {
                    _isLoadingUsername = true;
                  });
                  try {
                    await authProvider.updateUsername(
                      _newUsernameController.text,
                    );
                    if (mounted) {
                      Navigator.of(dialogContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Username berhasil diperbarui!'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      Navigator.of(dialogContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Gagal memperbarui username: ${e.toString()}',
                          ),
                        ),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isLoadingUsername = false;
                      });
                    }
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showChangePasswordDialog(
    BuildContext context,
    AuthProvider authProvider,
  ) {
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C2F33),
          title: const Text(
            'Ubah Password',
            style: TextStyle(color: Colors.white),
          ),
          content: Form(
            key: _passwordFormKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    controller: _currentPasswordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Password Saat Ini',
                      labelStyle: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    validator:
                        (value) =>
                            value!.isEmpty
                                ? 'Password saat ini tidak boleh kosong'
                                : null,
                  ),
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Password Baru',
                      labelStyle: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password baru tidak boleh kosong';
                      }
                      if (value.length < 6) {
                        return 'Password minimal 6 karakter';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Konfirmasi Password Baru',
                      labelStyle: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Konfirmasi password tidak boleh kosong';
                      }
                      if (value != _newPasswordController.text) {
                        return 'Password tidak cocok';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Batal',
                style: TextStyle(color: Colors.white70),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
              ),
              child:
                  _isLoadingPassword
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Text('Simpan'),
              onPressed: () async {
                if (_passwordFormKey.currentState!.validate()) {
                  setState(() {
                    _isLoadingPassword = true;
                  });
                  try {
                    await authProvider.changePassword(
                      _currentPasswordController.text,
                      _newPasswordController.text,
                    );
                    if (mounted) {
                      Navigator.of(dialogContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Password berhasil diubah!'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      Navigator.of(dialogContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Gagal mengubah password: ${e.toString()}',
                          ),
                        ),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isLoadingPassword = false;
                      });
                    }
                  }
                }
              },
            ),
          ],
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

  // Helper function to get color based on subscription status
  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'canceled':
      case 'cancelled':
        return Colors.orange;
      case 'incomplete':
      case 'incomplete_expired':
        return Colors.red;
      case 'trialing':
        return Colors.blue;
      case 'past_due':
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }

  // Helper function to build subscription detail row
  Widget _buildSubscriptionDetail(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white.withOpacity(0.7)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _getPlanName(String? planId) {
    return {
          'price_1OXST2Htj6wIa7rMQDz2GAxc': 'Basic Plan (720p)',
          'price_1OXST2Htj6wIa7rMoYlgA7Bm': 'Premium Plan (1080p)',
          'price_1OXSUAHtj6wIa7rMPmeNgqkx': 'Pro Plan (4K + HDR)',
        }[planId ?? ''] ??
        'Unknown Plan';
  }

  Future<void> _refreshSubscriptionData(AuthProvider authProvider) async {
    try {
      await authProvider.refreshUserData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subscription data updated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to refresh data: $e')));
      }
    }
  }
}

class WatchHistoryItem {
  final String thumbnailUrl;
  final String episodeInfo;
  final String title;
  final String id; // Added for video identification

  WatchHistoryItem({
    required this.thumbnailUrl,
    required this.episodeInfo,
    required this.title,
    required this.id,
  });

  // Factory constructor to create from VideoModel
  factory WatchHistoryItem.fromVideo(dynamic video) {
    // It's highly recommended to replace 'dynamic' with a concrete VideoModel class
    // for type safety, as mentioned in the analysis.
    return WatchHistoryItem(
      id: video.tmdbId,
      thumbnailUrl: video.posterPath,
      episodeInfo: video.type.isNotEmpty ? video.type.first : 'Movie',
      title: video.title,
    );
  }
}

class WatchHistorySection extends StatelessWidget {
  final List<WatchHistoryItem> items;
  final VoidCallback onSeeAll;

  const WatchHistorySection({
    super.key,
    required this.items,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Riwayat Tontonan',
            style: TextStyle(
              color: Color(0xFFB0B0B0),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF23262A),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF0099E6),
                                      borderRadius: BorderRadius.only(
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
