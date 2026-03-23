import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/server_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 全局主题状态管理器
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ServerProvider()),
      ],
      child: const UnraidApp(),
    ),
  );
}

class UnraidApp extends StatelessWidget {
  const UnraidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'Unraid 管家',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          theme: ThemeData(
            fontFamily: 'Roboto',
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFFF5722),
              brightness: Brightness.light,
              surface: const Color(0xFFF5F5F7),
            ),
            cardColor: Colors.white,
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            fontFamily: 'Roboto',
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFFF5722),
              brightness: Brightness.dark,
              surface: const Color(0xFF0F0F0F),
            ),
            cardColor: const Color(0xFF1A1A1A),
            useMaterial3: true,
          ),
          home: const MainNavigationPage(),
        );
      },
    );
  }
}

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardView(),
    const FileBrowserView(),
    const MediaClientView(), // 全新的 Emby 客户端视图
    const SettingsView(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
        indicatorColor: const Color(0xFFFF5722).withOpacity(0.2),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard, color: Color(0xFFFF5722)), label: '首页'),
          NavigationDestination(icon: Icon(Icons.folder_outlined), selectedIcon: Icon(Icons.folder, color: Color(0xFFFF5722)), label: '文件'),
          NavigationDestination(icon: Icon(Icons.play_circle_outline), selectedIcon: Icon(Icons.play_circle_fill, color: Color(0xFFFF5722)), label: '影音'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings, color: Color(0xFFFF5722)), label: '设置'),
        ],
      ),
    );
  }
}

// ---------------- 首页 (整合 Docker/VM 入口 & CPU 型号) ----------------

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final serverProvider = context.watch<ServerProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white70 : Colors.black87;

    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          title: const Row(
            children: [
              Icon(Icons.dns_rounded, color: Color(0xFFFF5722), size: 28),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('主服务器', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2, fontSize: 22)),
                  Text(serverProvider.cpuModel, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.normal)),
                ],
              ),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
          actions: [
            IconButton(
              icon: serverProvider.isLoading 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
                : const Icon(Icons.refresh),
              onPressed: () => serverProvider.refreshData(),
            ),
            Container(
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: serverProvider.isConnected ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  Icon(serverProvider.isConnected ? Icons.check_circle : Icons.error, color: serverProvider.isConnected ? Colors.greenAccent : Colors.redAccent, size: 16),
                  const SizedBox(width: 6),
                  Text(serverProvider.isConnected ? '已连接' : '未连接', style: TextStyle(color: serverProvider.isConnected ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (serverProvider.errorMsg.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text('API连接报错: ${serverProvider.errorMsg}', style: const TextStyle(color: Colors.red)),
                ),
              // 快捷入口 (Docker & VM)
              Row(
                children: [
                  Expanded(child: _buildShortcutCard(context, 'Docker 容器', '12 运行中', Icons.view_in_ar, Colors.purple, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const DockerView()));
                  })),
                  const SizedBox(width: 12),
                  Expanded(child: _buildShortcutCard(context, '虚拟机', '1 运行中', Icons.computer, Colors.teal, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const VmView()));
                  })),
                ],
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('核心计算负载', Icons.speed, textColor),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildSquareCard(context, 'CPU', serverProvider.cpuUsage, '45°C', Icons.memory, Colors.blue)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildSquareCard(context, 'GPU', serverProvider.gpuUsage, serverProvider.gpuTemp, Icons.developer_board, Colors.green)),
                ],
              ),
              const SizedBox(height: 12),
              _buildWideCard(context, '内存使用率', serverProvider.memUsage, '14.4 GB / 32 GB', Icons.memory_sharp, Colors.purple, progress: 0.45),
              const SizedBox(height: 24),
              
              _buildSectionTitle('阵列存储', Icons.storage_rounded, textColor),
              const SizedBox(height: 12),
              _buildWideCard(context, '总容量使用率', '68%', '可用 12 TB / 总共 64 TB', Icons.data_usage, Colors.orange, progress: 0.68),
              const SizedBox(height: 24),
              
              _buildSectionTitle('网络带宽', Icons.router_rounded, textColor),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildNetCard(context, '下载速率', '12.4', 'MB/s', Icons.download_rounded, Colors.cyan)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildNetCard(context, '上传速率', '3.2', 'MB/s', Icons.upload_rounded, Colors.indigo)),
                ],
              ),
              const SizedBox(height: 30),
            ]),
          ),
        ),
      ],
    );
  }
  Widget _buildShortcutCard(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
          boxShadow: isDark ? [] : [BoxShadow(color: color.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 16, color: isDark ? Colors.white38 : Colors.black38),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color.withOpacity(0.7)),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildSquareCard(BuildContext context, String title, String mainValue, String subValue, IconData icon, MaterialColor color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, size: 28, color: isDark ? color.shade200 : color.shade700),
              ),
              Icon(Icons.more_horiz, color: isDark ? Colors.white24 : Colors.black26, size: 20),
            ],
          ),
          const SizedBox(height: 20),
          Text(title, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(mainValue, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(subValue, style: TextStyle(color: isDark ? color.shade200 : color.shade700, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildNetCard(BuildContext context, String title, String value, String unit, IconData icon, MaterialColor color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 24, color: isDark ? color.shade200 : color.shade700),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(value, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 2),
                  Text(unit, style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 10)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWideCard(BuildContext context, String title, String mainValue, String subValue, IconData icon, MaterialColor color, {double? progress}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, size: 28, color: isDark ? color.shade200 : color.shade700),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 13)),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(mainValue, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 24, fontWeight: FontWeight.bold)),
                        Text(subValue, style: TextStyle(color: isDark ? Colors.white38 : Colors.black54, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: isDark ? Colors.white10 : Colors.black12,
                color: isDark ? color.shade300 : color.shade600,
                minHeight: 6,
              ),
            ),
          ]
        ],
      ),
    );
  }
}

// ---------------- 新版影音播放端 (Emby Client) ----------------
class MediaClientView extends StatelessWidget {
  const MediaClientView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.movie_filter, color: Color(0xFF52B54B)),
            SizedBox(width: 8),
            Text('家庭影院', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
          ],
        ),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(icon: const Icon(Icons.cast), onPressed: () {}),
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // 顶部焦点图 (大图推荐)
          Container(
            height: 220,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)]),
              image: const DecorationImage(
                image: NetworkImage('https://image.tmdb.org/t/p/w500/8b8R8l88ILliNa22vRoASihl5IQ.jpg'), // 占位图
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black45, BlendMode.darken),
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  bottom: 20,
                  left: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('沙丘2 (Dune: Part Two)', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text('科幻 / 动作 • 2024 • 4K HDR', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.play_arrow, color: Colors.black),
                        label: const Text('立即播放', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('继续观看', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          const SizedBox(height: 12),
          
          // 横向继续观看列表
          SizedBox(
            height: 160,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildContinueCard(context, '繁花', '第 14 集', 0.65, Colors.amber),
                _buildContinueCard(context, '奥本海默', '剩余 45 分钟', 0.82, Colors.orange),
                _buildContinueCard(context, '瑞克和莫蒂 S07', '第 5 集', 0.15, Colors.lightGreen),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('最新添加', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          const SizedBox(height: 12),
          
          // 瀑布流电影海报
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.65,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: 6,
              itemBuilder: (context, index) {
                final colors = [Colors.red, Colors.blue, Colors.green, Colors.purple, Colors.orange, Colors.teal];
                return Container(
                  decoration: BoxDecoration(
                    color: colors[index].withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(Icons.movie, color: colors[index], size: 40),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildContinueCard(BuildContext context, String title, String sub, double progress, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 220,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 90,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: const Center(child: Icon(Icons.play_circle_fill, color: Colors.white54, size: 40)),
          ),
          LinearProgressIndicator(value: progress, backgroundColor: Colors.transparent, color: const Color(0xFF52B54B)),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(sub, style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// ---------------- Docker 独立管理页 (从首页进入) ----------------
class DockerView extends StatelessWidget {
  const DockerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Docker 容器', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDockerItem(context, 'emby', 'emby/embyserver', '运行中', true, Icons.play_circle_fill, Colors.green),
          _buildDockerItem(context, 'Nextcloud', 'linuxserver/nextcloud', '运行中', true, Icons.cloud_circle, Colors.blue),
          _buildDockerItem(context, 'qBittorrent', 'linuxserver/qbittorrent', '运行中', true, Icons.downloading, Colors.blueAccent),
        ],
      ),
    );
  }

  Widget _buildDockerItem(BuildContext context, String name, String image, String status, bool isRunning, IconData appIcon, Color appColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(color: isRunning ? appColor.withOpacity(0.1) : (isDark ? Colors.white10 : Colors.black12), borderRadius: BorderRadius.circular(14)),
              child: Icon(appIcon, color: isRunning ? appColor : (isDark ? Colors.white38 : Colors.black38), size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
                  const SizedBox(height: 4),
                  Text(image, style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black54)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: isRunning ? Colors.green : Colors.red)),
                      const SizedBox(width: 6),
                      Text(status, style: TextStyle(fontSize: 12, color: isRunning ? Colors.green : Colors.red, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(isRunning ? Icons.stop_circle_outlined : Icons.play_circle_outline),
              color: isRunning ? Colors.red : Colors.green,
              onPressed: () {},
            )
          ],
        ),
      ),
    );
  }
}

// ---------------- VM 独立管理页 (从首页进入) ----------------
class VmView extends StatelessWidget {
  const VmView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: const Text('虚拟机', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.transparent),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(shape: BoxShape.circle, color: isDark ? Colors.white10 : Colors.black12),
              child: Icon(Icons.desktop_windows_outlined, size: 80, color: isDark ? Colors.white24 : Colors.black26),
            ),
            const SizedBox(height: 24),
            Text('暂无运行中的虚拟机', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ---------------- 其他页面 (不变) ----------------
class FileBrowserView extends StatelessWidget {
  const FileBrowserView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: const Text('文件', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.transparent),
      body: const Center(child: Text('文件浏览器内容')),
    );
  }
}


// ---------------- 设置页 ----------------
class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _sshHostController = TextEditingController();
  final TextEditingController _sshUserController = TextEditingController();
  final TextEditingController _sshPassController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ipController.text = prefs.getString('unraid_ip') ?? 'http://192.168.1.100:19009';
      _keyController.text = prefs.getString('unraid_api_key') ?? '';
      _sshHostController.text = prefs.getString('ssh_host') ?? '';
      _sshUserController.text = prefs.getString('ssh_user') ?? 'root';
      _sshPassController.text = prefs.getString('ssh_pass') ?? '';
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('unraid_ip', _ipController.text);
    await prefs.setString('unraid_api_key', _keyController.text);
    await prefs.setString('ssh_host', _sshHostController.text);
    await prefs.setString('ssh_user', _sshUserController.text);
    await prefs.setString('ssh_pass', _sshPassController.text);
    await prefs.setInt('ssh_port', 22);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ 服务器配置已保存！网络引擎将重新初始化。'), backgroundColor: Colors.green),
      );
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('设置', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingsGroup(context, '服务器连接配置 (Unraid API)', [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Unraid API 地址 (包含端口)', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _ipController,
                    decoration: InputDecoration(
                      hintText: '例如: http://192.168.1.100:19009',
                      filled: true,
                      fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.lan),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('API Key (密钥)', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _keyController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: '输入您的 Unraid API Key',
                      filled: true,
                      fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.key),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveSettings,
                      icon: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
                      label: const Text('保存并测试连接', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5722),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ]),
          
          _buildSettingsGroup(context, 'SSH 连接配置 (用于读取GPU状态)', [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SSH 主机 IP', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(controller: _sshHostController, decoration: InputDecoration(hintText: '例: 192.168.1.100', filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
                  const SizedBox(height: 16),
                  const Text('SSH 用户名', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(controller: _sshUserController, decoration: InputDecoration(hintText: '默认: root', filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
                  const SizedBox(height: 16),
                  const Text('SSH 密码', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(controller: _sshPassController, obscureText: true, decoration: InputDecoration(hintText: '输入您的 root 密码', filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 24),
          
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveSettings,
                      icon: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
                      label: const Text('保存所有配置并测试连接', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5722),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),

          const SizedBox(height: 24),
          _buildSettingsGroup(context, '外观与通用', [
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: const Text('主题设置'),
              trailing: DropdownButton<ThemeMode>(
                value: themeNotifier.value,
                underline: const SizedBox(),
                dropdownColor: Theme.of(context).cardColor,
                items: const [
                  DropdownMenuItem(value: ThemeMode.system, child: Text('跟随系统')),
                  DropdownMenuItem(value: ThemeMode.light, child: Text('浅色模式')),
                  DropdownMenuItem(value: ThemeMode.dark, child: Text('深色模式')),
                ],
                onChanged: (mode) {
                  if (mode != null) {
                    themeNotifier.value = mode;
                  }
                },
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(BuildContext context, String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 12),
          child: Text(title, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: Theme.of(context).brightness == Brightness.light ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)] : [],
          ),
          child: Column(children: items),
        ),
      ],
    );
}
}
