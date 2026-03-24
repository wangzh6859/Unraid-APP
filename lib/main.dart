import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'providers/server_provider.dart';
import 'providers/emby_provider.dart';

import 'utils/app_config.dart';
import 'screens/login_screen.dart';
import 'screens/vm_view.dart';
import 'screens/media_detail_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';

// 全局主题状态管理器
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ServerProvider()),
        ChangeNotifierProvider(create: (_) => EmbyProvider()),
      ],
      child: const UnraidApp(),
    ),
  );
}

class UnraidApp extends StatefulWidget {
  const UnraidApp({super.key});
  @override
  State<UnraidApp> createState() => _UnraidAppState();
}

class _UnraidAppState extends State<UnraidApp> {
  bool _isReady = false;
  bool _hasLogin = false;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    await AppConfig.load();
    setState(() {
      _hasLogin = AppConfig.baseDomain.isNotEmpty && AppConfig.username.isNotEmpty;
      _isReady = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) {
        return MaterialApp(
          title: 'Unraid Dashboard',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: ThemeData(
            brightness: Brightness.light,
            colorSchemeSeed: const Color(0xFFFF5722),
            scaffoldBackgroundColor: const Color(0xFFF2F2F6),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorSchemeSeed: const Color(0xFFFF5722),
            scaffoldBackgroundColor: const Color(0xFF111112),
            cardColor: const Color(0xFF1C1C1E),
            useMaterial3: true,
          ),
          home: !_isReady 
              ? const Scaffold(body: Center(child: CircularProgressIndicator())) 
              : (_hasLogin ? const MainNavigationPage() : const LoginScreen()),
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
    const VmView(),
    const MediaClientView(), // 全新的 Emby 客户端视图
    const SettingsView(),
  ];


/*
  void _showEmbyAccountDialog() {
    final urlCtrl = TextEditingController(text: AppConfig.embyUrl);
    final userCtrl = TextEditingController(text: AppConfig.activeEmbyUser);
    final passCtrl = TextEditingController(text: AppConfig.activeEmbyPass);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Emby 账号配置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'Emby 地址 (含端口)')),
            const SizedBox(height: 8),
            TextField(controller: userCtrl, decoration: const InputDecoration(labelText: '用户名')),
            const SizedBox(height: 8),
            TextField(controller: passCtrl, obscureText: true, decoration: const InputDecoration(labelText: '密码')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () async {
            },
            child: const Text('保存并重连'),
          ),
        ],
      ),
    );
  }
*/

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
          NavigationDestination(icon: Icon(Icons.computer_outlined), selectedIcon: Icon(Icons.computer, color: Color(0xFFFF5722)), label: '虚拟机'),
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


/*
  void _showEmbyAccountDialog() {
    final urlCtrl = TextEditingController(text: AppConfig.embyUrl);
    final userCtrl = TextEditingController(text: AppConfig.activeEmbyUser);
    final passCtrl = TextEditingController(text: AppConfig.activeEmbyPass);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Emby 账号配置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'Emby 地址 (含端口)')),
            const SizedBox(height: 8),
            TextField(controller: userCtrl, decoration: const InputDecoration(labelText: '用户名')),
            const SizedBox(height: 8),
            TextField(controller: passCtrl, obscureText: true, decoration: const InputDecoration(labelText: '密码')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () async {
            },
            child: const Text('保存并重连'),
          ),
        ],
      ),
    );
  }
*/

  @override
  Widget build(BuildContext context) {

    final serverProvider = context.watch<ServerProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white70 : Colors.black87;

    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          title: Row(
            children: [
              const Icon(Icons.dns_rounded, color: Color(0xFFFF5722), size: 28),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('主服务器', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2, fontSize: 22)),
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
              onPressed: () => serverProvider.fetchStats(),
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
                  Expanded(child: _buildSquareCard(context, 'CPU', '${serverProvider.cpuUsage}%', '45°C', Icons.memory, Colors.blue)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildSquareCard(context, 'GPU', serverProvider.gpuUsage, serverProvider.gpuTemp, Icons.developer_board, Colors.green)),
                ],
              ),
              const SizedBox(height: 12),
              _buildWideCard(context, '内存使用率', '${serverProvider.memUsage}%', '14.4 GB / 32 GB', Icons.memory_sharp, Colors.purple, progress: double.tryParse(serverProvider.memUsage.replaceAll('%', '')) != null ? (double.parse(serverProvider.memUsage.replaceAll('%', '')) / 100.0) : 0.0),
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
class MediaClientView extends StatefulWidget {
  const MediaClientView({super.key});
  @override
  State<MediaClientView> createState() => _MediaClientViewState();
}

class _MediaClientViewState extends State<MediaClientView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmbyProvider>().fetchMedia();
    });
  }

  void _showEmbyAccountDialog() {
    final urlCtrl = TextEditingController(text: AppConfig.embyUrl);
    final userCtrl = TextEditingController(text: AppConfig.activeEmbyUser);
    final passCtrl = TextEditingController(text: AppConfig.activeEmbyPass);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Emby 账号配置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'Emby 地址 (含端口)')),
            const SizedBox(height: 8),
            TextField(controller: userCtrl, decoration: const InputDecoration(labelText: '用户名')),
            const SizedBox(height: 8),
            TextField(controller: passCtrl, obscureText: true, decoration: const InputDecoration(labelText: '密码')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () async {
              await AppConfig.saveEmbyAccount(urlCtrl.text, userCtrl.text, passCtrl.text);
              Navigator.pop(ctx);
              context.read<EmbyProvider>().fetchMedia();
            },
            child: const Text('保存并重连'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final embyProvider = context.watch<EmbyProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            floating: true,
            title: const Text('影音中心', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
            actions: [
              IconButton(icon: const Icon(Icons.manage_accounts), onPressed: _showEmbyAccountDialog),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => embyProvider.fetchMedia(),
              )
            ],
            backgroundColor: Colors.transparent,
          ),
          
          // Categories Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: embyProvider.categories.map((cat) {
                    final isSelected = embyProvider.currentCategory == cat['value'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ChoiceChip(
                        label: Text(cat['name']!, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            embyProvider.fetchMedia(category: cat['value']);
                          }
                        },
                        selectedColor: const Color(0xFFFF5722),
                        labelStyle: TextStyle(color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          if (embyProvider.isLoading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (embyProvider.errorMsg.isNotEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 60, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(embyProvider.errorMsg, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            )
          else if (embyProvider.latestItems.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text('该分类下没有内容，或未配置Emby', style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.68,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = embyProvider.latestItems[index];
                    final imageUrl = embyProvider.getImageUrl(item['Id']);
                    return GestureDetector(
                      onTap: () {
                         Navigator.push(context, MaterialPageRoute(builder: (_) => MediaDetailScreen(item: item)));
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: isDark ? Colors.white10 : Colors.grey.shade100,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (imageUrl.isNotEmpty)
                              Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Center(child: Icon(Icons.movie_creation, size: 40, color: Colors.grey)),
                              )
                            else
                              Center(child: Icon(Icons.movie_creation, size: 40, color: Colors.grey)),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [Colors.black87, Colors.transparent],
                                  ),
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  item['Name'] ?? '未知内容',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: embyProvider.latestItems.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}


class FileBrowserView extends StatelessWidget {
  const FileBrowserView({super.key});

/*
  void _showEmbyAccountDialog() {
    final urlCtrl = TextEditingController(text: AppConfig.embyUrl);
    final userCtrl = TextEditingController(text: AppConfig.activeEmbyUser);
    final passCtrl = TextEditingController(text: AppConfig.activeEmbyPass);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Emby 账号配置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'Emby 地址 (含端口)')),
            const SizedBox(height: 8),
            TextField(controller: userCtrl, decoration: const InputDecoration(labelText: '用户名')),
            const SizedBox(height: 8),
            TextField(controller: passCtrl, obscureText: true, decoration: const InputDecoration(labelText: '密码')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () async {
            },
            child: const Text('保存并重连'),
          ),
        ],
      ),
    );
  }
*/

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: const Text('文件', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.transparent),
      body: Center(child: Text('文件浏览器内容')),
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
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await AppConfig.load();
    setState(() {
      _ipController.text = AppConfig.baseDomain;
      _userController.text = AppConfig.username;
      _passController.text = AppConfig.password;
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    await AppConfig.save(_ipController.text, _userController.text, _passController.text);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ 配置已保存！子系统将自动派生新地址。'), backgroundColor: Colors.green),
      );
      setState(() => _isSaving = false);
    }
  }


/*
  void _showEmbyAccountDialog() {
    final urlCtrl = TextEditingController(text: AppConfig.embyUrl);
    final userCtrl = TextEditingController(text: AppConfig.activeEmbyUser);
    final passCtrl = TextEditingController(text: AppConfig.activeEmbyPass);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Emby 账号配置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'Emby 地址 (含端口)')),
            const SizedBox(height: 8),
            TextField(controller: userCtrl, decoration: const InputDecoration(labelText: '用户名')),
            const SizedBox(height: 8),
            TextField(controller: passCtrl, obscureText: true, decoration: const InputDecoration(labelText: '密码')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () async {
            },
            child: const Text('保存并重连'),
          ),
        ],
      ),
    );
  }
*/

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
          _buildSettingsGroup(context, '统一服务器认证 (全局)', [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('主服务器地址', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _ipController,
                    decoration: InputDecoration(
                      hintText: '例: https://5nas.asia:16666',
                      filled: true,
                      fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.dns),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('全局用户名', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _userController,
                    decoration: InputDecoration(
                      hintText: '用于 Glances 与 Emby',
                      filled: true,
                      fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('全局密码', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: '输入您的密码',
                      filled: true,
                      fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.key),
                    ),
                  ),
                ],
              ),
            ),
          ]),
          
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveSettings,
              icon: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
              label: const Text('保存并重载配置', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('退出登录', style: TextStyle(color: Colors.redAccent)),
              onTap: () async {
                 await AppConfig.save('', '', '');
                 Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
              },
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

// Restored Missing Views
class DockerView extends StatefulWidget {
  const DockerView({super.key});

  @override
  State<DockerView> createState() => _DockerViewState();
}

IconData _getDockerIcon(String? name) {
    if (name == null) return Icons.view_in_ar_rounded;
    name = name.toLowerCase();
    if (name.contains('nginx') || name.contains('proxy') || name.contains('swag')) return Icons.public;
    if (name.contains('sql') || name.contains('db') || name.contains('redis') || name.contains('mongo') || name.contains('mariadb')) return Icons.storage;
    if (name.contains('emby') || name.contains('jellyfin') || name.contains('plex')) return Icons.movie_creation;
    if (name.contains('qbittorrent') || name.contains('transmission') || name.contains('aria2') || name.contains('download')) return Icons.cloud_download;
    if (name.contains('alist') || name.contains('nextcloud') || name.contains('cloud')) return Icons.cloud;
    if (name.contains('homeassistant') || name.contains('ha')) return Icons.home;
    if (name.contains('openclaw') || name.contains('bot') || name.contains('ai')) return Icons.smart_toy;
    if (name.contains('portainer')) return Icons.dashboard;
    return Icons.dns;
  }

class _DockerViewState extends State<DockerView> {
  void _showPortainerConfigDialog() {
    final userCtrl = TextEditingController(text: AppConfig.portainerUser);
    final passCtrl = TextEditingController(text: AppConfig.portainerPass);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Portainer 账号配置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: userCtrl, decoration: const InputDecoration(labelText: 'Portainer 用户名 (如 admin)')),
            const SizedBox(height: 8),
            TextField(controller: passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Portainer 密码')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () async {
              await AppConfig.savePortainerAccount(userCtrl.text, passCtrl.text);
              Navigator.pop(ctx);
              context.read<ServerProvider>().fetchStats();
            },
            child: const Text('保存并连接'),
          ),
        ],
      ),
    );
  }

  String _sortMode = 'name'; // default sort by name
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServerProvider>().fetchStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final server = context.watch<ServerProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget _buildBody() {
      if (server.isLoading && server.dockerContainers.isEmpty) {
        return Center(child: CircularProgressIndicator());
      }
      if (server.errorMsg.isNotEmpty && server.dockerContainers.isEmpty) {
        return Center(child: Text(server.errorMsg, style: const TextStyle(color: Colors.red)));
      }
      if (server.dockerContainers.isEmpty) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: SelectableText(
            '监控模块返回信息：\n\n${server.rawDockerResponse}',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        );
      }
      
      List<dynamic> displayList = List.from(server.dockerContainers);
      
      displayList.sort((a, b) {
        if (_sortMode == 'name') {
           String getName(dynamic c) {
             if (c['Names'] != null && c['Names'] is List && c['Names'].isNotEmpty) {
               return c['Names'][0].toString().replaceAll('/', '');
             }
             if (c['name'] != null) return c['name'].toString();
             if (c['Names'] != null) return c['Names'].toString();
             return '';
           }
           return getName(a).toLowerCase().compareTo(getName(b).toLowerCase());
        } else if (_sortMode == 'cpu') {
           double cpuA = a['cpu']?.containsKey('total') == true ? (a['cpu']['total'] as num).toDouble() : 0.0;
           double cpuB = b['cpu']?.containsKey('total') == true ? (b['cpu']['total'] as num).toDouble() : 0.0;
           return cpuB.compareTo(cpuA); // descending
        } else if (_sortMode == 'mem') {
           double memA = a['memory']?.containsKey('usage') == true ? (a['memory']['usage'] as num).toDouble() : 0.0;
           double memB = b['memory']?.containsKey('usage') == true ? (b['memory']['usage'] as num).toDouble() : 0.0;
           return memB.compareTo(memA); // descending
        } else {
           // Default status sorting: Running first
           String statusA = a['status']?.toString().toLowerCase() ?? a['Status']?.toString().toLowerCase() ?? '';
           String statusB = b['status']?.toString().toLowerCase() ?? b['Status']?.toString().toLowerCase() ?? '';
           bool aUp = statusA.contains('running') || statusA.contains('healthy') || statusA.contains('up');
           bool bUp = statusB.contains('running') || statusB.contains('healthy') || statusB.contains('up');
           if (aUp && !bUp) return -1;
           if (bUp && !aUp) return 1;
           return 0;
        }
      });

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: displayList.length,
        itemBuilder: (context, index) {
          final container = displayList[index];
          
          // Handle both Glances and Portainer formats
          String name = '未知容器';
          if (container['Names'] != null && container['Names'] is List && container['Names'].isNotEmpty) {
             name = container['Names'][0].toString().replaceAll('/', ''); // Portainer format
          } else if (container['name'] != null) {
             name = container['name']; // Glances format
          } else if (container['Names'] is String) {
             name = container['Names'];
          }
          
          final String containerId = (container['Id'] ?? container['id'] ?? container['ID'] ?? '').toString();
          final status = container['State'] ?? container['Status'] ?? container['status'] ?? container['state'] ?? 'unknown';
          // Portainer list doesn't return live CPU/Mem, so we display Image name or State if cpu/mem is missing
          final hasCpu = container['cpu'] != null;
          final cpu = container['cpu']?.containsKey('total') == true ? container['cpu']['total'] : 0.0;

          // Native+Portainer merged stats
          final cpuPercent = (container['cpuPercent'] is num) ? (container['cpuPercent'] as num).toDouble() : null;
          final memUsageBytes = (container['memUsageBytes'] is num) ? (container['memUsageBytes'] as num).toDouble() : null;

          final mem = container['memory']?.containsKey('usage') == true 
              ? (container['memory']['usage'] / 1024 / 1024).toStringAsFixed(1) 
              : (memUsageBytes != null ? (memUsageBytes / 1024 / 1024).toStringAsFixed(1) : '0.0');

          final displayCpu = cpuPercent ?? ((cpu is num) ? (cpu as num).toDouble() : 0.0);
          
          final image = container['Image'] ?? container['image'] ?? '';
          
          final statusStr = status.toString().toLowerCase();
          final bool isRunning = (container['running'] == true) || statusStr.contains('running') || statusStr.contains('healthy') || statusStr.contains('up') || statusStr.contains('运行');

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade900 : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isRunning ? Colors.green.withOpacity(0.3) : Colors.grey.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: SizedBox(
                width: 48,
                height: 48,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: isRunning ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Builder(
                        builder: (_) {
                          try {
                            final iconPath = (container is Map ? (container['iconPath'] ?? '') : '').toString();
                            if (iconPath.isNotEmpty && AppConfig.baseDomain.isNotEmpty) {
                              final url = '${AppConfig.baseDomain}$iconPath';
                              return ClipOval(
                                child: Image.network(
                                  url,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    isRunning ? Icons.view_in_ar_rounded : Icons.stop_circle_outlined,
                                    color: isRunning ? Colors.green : Colors.grey,
                                  ),
                                ),
                              );
                            }
                          } catch (_) {}

                          return Icon(
                            isRunning ? Icons.view_in_ar_rounded : Icons.stop_circle_outlined,
                            color: isRunning ? Colors.green : Colors.grey,
                          );
                        },
                      ),
                    ),
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: isRunning ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              title: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.memory, size: 14, color: Colors.blue.shade400),
                    const SizedBox(width: 4),
                    Text('${displayCpu.toStringAsFixed(1)}%'),
                    const SizedBox(width: 16),
                    Icon(Icons.storage, size: 14, color: Colors.orange.shade400),
                    const SizedBox(width: 4),
                    Text('${mem} MB'),
                  ],
                ),
              ),
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) async {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('正在发送 $value 指令...')));
                  final success = await server.controlDocker(container, value);
                  if (success) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('指令执行成功')));
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('指令执行失败（已尝试 Native/Portainer）')));
                    }
                  }
                },
                itemBuilder: (context) => <PopupMenuEntry<String>>[
                  if (!isRunning) const PopupMenuItem<String>(value: 'start', child: Text('启动 (Start)')),
                  if (isRunning) const PopupMenuItem<String>(value: 'stop', child: Text('停止 (Stop)')),
                  if (isRunning) const PopupMenuItem<String>(value: 'restart', child: Text('重启 (Restart)')),
                ],
              ),
            ),
          );
        },
      );
    }

    final total = server.dockerContainers.length;
    final runningCount = server.dockerContainers.where((c) {
      try {
        if (c is Map && c['running'] == true) return true;
        final s = (c['State'] ?? c['Status'] ?? c['status'] ?? '').toString().toLowerCase();
        return s.contains('up') || s.contains('running') || s.contains('healthy');
      } catch (_) {
        return false;
      }
    }).length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Docker 控制台（$runningCount/$total 运行中）', style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.manage_accounts),
            tooltip: '配置 Portainer 账号',
            onPressed: _showPortainerConfigDialog,
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: '复制 Native Docker 源码预览（前 8KB）',
            onPressed: server.rawDockerHtmlPreview.isEmpty
                ? null
                : () async {
                    await Clipboard.setData(ClipboardData(text: server.rawDockerHtmlPreview));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制 Docker 源码预览')));
                    }
                  },
          ),

          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: '排序方式',
            onSelected: (value) {
              setState(() {
                _sortMode = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'status', child: Text('按运行状态')),
              const PopupMenuItem(value: 'name', child: Text('按名称字母')),
              const PopupMenuItem(value: 'cpu', child: Text('按 CPU 占用')),
              const PopupMenuItem(value: 'mem', child: Text('按 内存占用')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => server.fetchStats(),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }
}


