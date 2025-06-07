import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_video_app/providers/watch_history_provider.dart';
import 'package:flutter_video_app/widgets/video_grid.dart';

class WatchHistoryScreen extends StatelessWidget {
  const WatchHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1D21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF23262A),
        elevation: 0,
        title: const Text(
          'Riwayat Tontonan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      backgroundColor: const Color(0xFF23262A),
                      title: const Text(
                        'Hapus Riwayat',
                        style: TextStyle(color: Colors.white),
                      ),
                      content: const Text(
                        'Apakah Anda yakin ingin menghapus semua riwayat tontonan?',
                        style: TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Batal',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            try {
                              Navigator.pop(context);
                              await Provider.of<WatchHistoryProvider>(
                                context,
                                listen: false,
                              ).clearWatchHistory();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Riwayat tontonan telah dihapus',
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: ${e.toString()}'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          child: const Text(
                            'Hapus',
                            style: TextStyle(color: Color(0xFFE53935)),
                          ),
                        ),
                      ],
                    ),
              );
            },
          ),
        ],
      ),
      body: Consumer<WatchHistoryProvider>(
        builder: (context, watchHistoryProvider, child) {
          if (watchHistoryProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFE53935)),
            );
          }

          final videos = watchHistoryProvider.watchHistory;

          if (videos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey[600]),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada riwayat tontonan',
                    style: TextStyle(fontSize: 18, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return VideoGrid(
            videos: videos,
            scrollController: ScrollController(),
          );
        },
      ),
    );
  }
}
