import 'package:flutter/material.dart';

void main() {
  runApp(const UnraidApp());
}

class UnraidApp extends StatelessWidget {
  const UnraidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Unraid 管家',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto', // Default but we can tweak if needed
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF5722), // 飞牛风格的深橘红色
          brightness: Brightness.dark,
          background: const Color(0xFF0F0F0F),
          surface: const Color(0xFF1A1A1A),
        ),
        useMaterial3: true,
      ),
      home: const MainNavigationPage(),
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
    const DockerView(),
    const VmView(),
    const SettingsView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: const Color(0xFF141414),
        indicatorColor: const Color(0xFFFF5722).withOpacity(0.2),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: Color(0xFFFF5722)),
            label: '概览',
          ),
          NavigationDestination(
            icon: Icon(Icons.view_in_ar_outlined),
            selectedIcon: Icon(Icons.view_in_ar, color: Color(0xFFFF5722)),
            label: '容器',
          ),
          NavigationDestination(
            icon: Icon(Icons.computer_outlined),
            selectedIcon: Icon(Icons.computer, color: Color(0xFFFF5722)),
            label: '虚拟机',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings, color: Color(0xFFFF5722)),
            label: '设置',
          ),
        ],
      ),
    );
  }
}

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          title: Row(
            children: [
              const Icon(Icons.dns_rounded, color: Color(0xFFFF5722), size: 28),
              const SizedBox(width: 12),
              const Text('主服务器', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2)),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.background,
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
                  SizedBox(width: 6),
                  Text('运行中', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildSectionTitle('系统负载', Icons.speed),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildSquareCard('CPU', '12%', '45°C', Icons.memory, Colors.blueAccent)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildSquareCard('内存', '45%', '14.4 GB', Icons.developer_board, Colors.purpleAccent)),
                ],
              ),
              const SizedBox(height: 24),
              
              _buildSectionTitle('阵列存储', Icons.storage_rounded),
              const SizedBox(height: 12),
              _buildWideCard('总容量使用率', '68%', '可用 12 TB / 总共 64 TB', Icons.data_usage, Colors.orangeAccent, progress: 0.68),
              const SizedBox(height: 24),
              
              _buildSectionTitle('网络带宽', Icons.router_rounded),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildNetCard('下载速率', '12.4', 'MB/s', Icons.download_rounded, Colors.greenAccent)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildNetCard('上传速率', '3.2', 'MB/s', Icons.upload_rounded, Colors.cyanAccent)),
                ],
              ),
              const SizedBox(height: 30),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.white54),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildSquareCard(String title, String mainValue, String subValue, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
        ],
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
                child: Icon(icon, size: 28, color: color),
              ),
              Icon(Icons.more_horiz, color: Colors.white24, size: 20),
            ],
          ),
          const SizedBox(height: 20),
          Text(title, style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(mainValue, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(subValue, style: TextStyle(color: color.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildNetCard(String title, String value, String unit, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 2),
                  Text(unit, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWideCard(String title, String mainValue, String subValue, IconData icon, Color color, {double? progress}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(mainValue, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        Text(subValue, style: const TextStyle(color: Colors.white38, fontSize: 12)),
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
                backgroundColor: Colors.white10,
                color: color,
                minHeight: 6,
              ),
            ),
          ]
        ],
      ),
    );
  }
}

class DockerView extends StatelessWidget {
  const DockerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Docker 容器', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDockerItem('Plex Media Server', 'linuxserver/plex', '运行中', true, Icons.play_circle_fill, Colors.amber),
          _buildDockerItem('Nextcloud', 'linuxserver/nextcloud', '运行中', true, Icons.cloud_circle, Colors.blue),
          _buildDockerItem('qBittorrent', 'linuxserver/qbittorrent', '运行中', true, Icons.downloading, Colors.blueAccent),
          _buildDockerItem('HomeAssistant', 'homeassistant/home-assistant', '已停止', false, Icons.home_rounded, Colors.white54),
        ],
      ),
    );
  }

  Widget _buildDockerItem(String name, String image, String status, bool isRunning, IconData appIcon, Color appColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // App Icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isRunning ? appColor.withOpacity(0.1) : Colors.white10,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(appIcon, color: isRunning ? appColor : Colors.white38, size: 28),
            ),
            const SizedBox(width: 16),
            
            // Text Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isRunning ? Colors.white : Colors.white60)),
                  const SizedBox(height: 4),
                  Text(image, style: const TextStyle(fontSize: 11, color: Colors.white38), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isRunning ? Colors.greenAccent : Colors.redAccent,
                          boxShadow: isRunning ? [BoxShadow(color: Colors.greenAccent.withOpacity(0.5), blurRadius: 4)] : [],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(status, style: TextStyle(fontSize: 12, color: isRunning ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            
            // Actions
            Column(
              children: [
                IconButton(
                  icon: Icon(isRunning ? Icons.stop_circle_outlined : Icons.play_circle_outline),
                  color: isRunning ? Colors.redAccent : Colors.greenAccent,
                  iconSize: 28,
                  onPressed: () {},
                ),
                const Text('日志', style: TextStyle(fontSize: 10, color: Colors.white38)),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class VmView extends StatelessWidget {
  const VmView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('虚拟机管理', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.03),
              ),
              child: Icon(Icons.desktop_windows_outlined, size: 80, color: Colors.white24),
            ),
            const SizedBox(height: 24),
            const Text('暂无运行中的虚拟机', style: TextStyle(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {}, 
              icon: const Icon(Icons.add), 
              label: const Text('新建虚拟机'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFF5722),
                side: const BorderSide(color: Color(0xFFFF5722)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('应用设置', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingsGroup('服务器', [
            _buildSettingsItem('连接地址', '192.168.1.100', Icons.lan_outlined),
            _buildSettingsItem('API 密钥', '已配置', Icons.key_outlined),
            _buildSettingsItem('切换服务器', '本地塔式服务器', Icons.swap_horiz_rounded),
          ]),
          const SizedBox(height: 24),
          _buildSettingsGroup('外观与通用', [
            _buildSettingsItem('主题颜色', '飞牛深橘', Icons.color_lens_outlined),
            _buildSettingsItem('语言', '简体中文', Icons.language_outlined),
            _buildSettingsItem('震动反馈', '已开启', Icons.vibration),
          ]),
          const SizedBox(height: 24),
          _buildSettingsGroup('关于', [
            _buildSettingsItem('检查更新', '版本 1.0.0 Alpha', Icons.update),
            _buildSettingsItem('GitHub 仓库', 'wangzh6859/Unraid-APP', Icons.code),
          ]),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 12),
          child: Text(title, style: const TextStyle(color: Color(0xFFFF5722), fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(String title, String trailing, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70, size: 22),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(trailing, style: const TextStyle(color: Colors.white38, fontSize: 14)),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}
