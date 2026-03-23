import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/emby_provider.dart';
import '../utils/app_config.dart';

class MediaDetailScreen extends StatelessWidget {
  final dynamic item;
  const MediaDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final emby = context.read<EmbyProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final primaryImg = emby.getImageUrl(item['Id']);
    final backdropImg = emby.getBackdropUrl(item['Id']);
    
    final title = item['Name'] ?? '未知标题';
    final overview = item['Overview'] ?? '暂无剧情简介';
    final year = item['ProductionYear']?.toString() ?? '未知年份';
    final rating = item['CommunityRating']?.toString() ?? '暂无评分';
    
    String duration = '';
    if (item['RunTimeTicks'] != null) {
      int minutes = (item['RunTimeTicks'] / 10000000 / 60).round();
      duration = '$minutes 分钟';
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, blurRadius: 10)])),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    backdropImg.isNotEmpty ? backdropImg : primaryImg,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Image.network(primaryImg, fit: BoxFit.cover),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black87, Colors.transparent],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: const Color(0xFFFF5722), borderRadius: BorderRadius.circular(20)),
                        child: Text(year, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      if (duration.isNotEmpty) ...[
                        Icon(Icons.access_time, size: 18, color: isDark ? Colors.grey : Colors.grey.shade700),
                        const SizedBox(width: 4),
                        Text(duration, style: TextStyle(color: isDark ? Colors.grey : Colors.grey.shade700)),
                        const SizedBox(width: 16),
                      ],
                      Icon(Icons.star_rounded, size: 20, color: Colors.amber.shade400),
                      const SizedBox(width: 4),
                      Text(rating, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () {
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('内网串流播放器即将到来...')));
                      },
                      icon: const Icon(Icons.play_arrow_rounded, size: 28),
                      label: const Text('立即播放', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? Colors.white : Colors.black,
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text('剧情简介', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(
                    overview,
                    style: const TextStyle(fontSize: 15, height: 1.6),
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
