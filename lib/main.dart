import 'package:flutter/material.dart';

// 全局主题状态管理器
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

void main() {
  runApp(const UnraidApp());
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
          // 浅色主题
          theme: ThemeData(
            fontFamily: 'Roboto',
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFFF5722),
              brightness: Brightness.light,
              surface: const Color(0xFFF5F5F7), // 浅色背景
            ),
            cardColor: Colors.white,
            useMaterial3: true,
          ),
          // 深色主题
          darkTheme: ThemeData(
            fontFamily: 'Roboto',
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFFF5722),
              brightness: Brightness.dark,
              surface: const Color(0xFF0F0F0F), // 极夜黑背景
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
    const DockerView(),
    const VmView(),
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
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard, color: Color(0xFFFF5722)), label: '概览'),
          NavigationDestination(icon: Icon(Icons.folder_outlined), selectedIcon: Icon(Icons.folder, color: Color(0xFFFF5722)), label: '文件'),
          NavigationDestination(icon: Icon(Icons.view_in_ar_outlined), selectedIcon: Icon(Icons.view_in_ar, color: Color(0xFFFF5722)), label: '容器'),
          NavigationDestination(icon: Icon(Icons.computer_outlined), selectedIcon: Icon(Icons.computer, color: Color(0xFFFF5722)), label: '虚拟机'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings, color: Color(0xFFFF5722)), label: '设置'),
        ],
      ),
    );
  }
}

// ---------------- 概览页 ----------------
class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white70 : Colors.black87;

    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          title: const Row(
            children: [
              Icon(Icons.dns_rounded, color: Color(0xFFFF5722), size: 28),
              SizedBox(width: 12),
              Text('主服务器', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2)),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
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
                  Text('运行中', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildSectionTitle('系统负载', Icons.speed, textColor),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildSquareCard(context, 'CPU', '12%', '45°C', Icons.memory, Colors.blue)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildSquareCard(context, '内存', '45%', '14.4 GB', Icons.developer_board, Colors.purple)),
                ],
              ),
              const SizedBox(height: 24),
              
              _buildSectionTitle('阵列存储', Icons.storage_rounded, textColor),
              const SizedBox(height: 12),
              _buildWideCard(context, '总容量使用率', '68%', '可用 12 TB / 总共 64 TB', Icons.data_usage, Colors.orange, progress: 0.68),
              const SizedBox(height: 24),
              
              _buildSectionTitle('网络带宽', Icons.router_rounded, textColor),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildNetCard(context, '下载速率', '12.4', 'MB/s', Icons.download_rounded, Colors.green)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildNetCard(context, '上传速率', '3.2', 'MB/s', Icons.upload_rounded, Colors.cyan)),
                ],
              ),
              const SizedBox(height: 30),
            ]),
          ),
        ),
      ],
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

// ---------------- 文件浏览页 ----------------
class FileBrowserView extends StatelessWidget {
  const FileBrowserView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('文件浏览', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Icon(Icons.home_rounded, size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text('mnt', style: TextStyle(fontWeight: FontWeight.bold)),
                const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                const Text('user', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildFileItem(context, 'appdata', '文件夹 • 昨天 14:30', true),
          _buildFileItem(context, 'domains', '文件夹 • 3月12日', true),
          _buildFileItem(context, 'isos', '文件夹 • 1月5日', true),
          _buildFileItem(context, 'Media', '文件夹 • 昨天 09:15', true),
          _buildFileItem(context, 'docker.img', '20.0 GB • 磁盘映像', false, icon: Icons.disc_full, color: Colors.orange),
          _buildFileItem(context, 'syslog.txt', '125 KB • 文本文件', false, icon: Icons.description, color: Colors.blue),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // 模拟上传点击
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('触发上传文件...')));
        },
        icon: const Icon(Icons.upload_file),
        label: const Text('上传'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildFileItem(BuildContext context, String name, String subtitle, bool isFolder, {IconData? icon, Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(
          isFolder ? Icons.folder_rounded : (icon ?? Icons.insert_drive_file),
          size: 36,
          color: isFolder ? Colors.amber : (color ?? Colors.grey),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54)),
        trailing: PopupMenuButton(
          icon: Icon(Icons.more_vert, color: isDark ? Colors.white54 : Colors.black54),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'download', child: Row(children: [Icon(Icons.download, size: 18), SizedBox(width: 8), Text('下载')])),
            const PopupMenuItem(value: 'rename', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('重命名')])),
            const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 18), SizedBox(width: 8), Text('删除', style: TextStyle(color: Colors.red))])),
          ],
        ),
      ),
    );
  }
}

// ---------------- Docker页 ----------------
class DockerView extends StatelessWidget {
  const DockerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Docker 容器', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDockerItem(context, 'Plex Media Server', 'linuxserver/plex', '运行中', true, Icons.play_circle_fill, Colors.amber),
          _buildDockerItem(context, 'Nextcloud', 'linuxserver/nextcloud', '运行中', true, Icons.cloud_circle, Colors.blue),
          _buildDockerItem(context, 'qBittorrent', 'linuxserver/qbittorrent', '运行中', true, Icons.downloading, Colors.blueAccent),
          _buildDockerItem(context, 'HomeAssistant', 'homeassistant/home-assistant', '已停止', false, Icons.home_rounded, Colors.grey),
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
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isRunning ? appColor.withOpacity(0.1) : (isDark ? Colors.white10 : Colors.black12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(appIcon, color: isRunning ? appColor : (isDark ? Colors.white38 : Colors.black38), size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
                  const SizedBox(height: 4),
                  Text(image, style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black54), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isRunning ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(status, style: TextStyle(fontSize: 12, color: isRunning ? Colors.green : Colors.red, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: Icon(isRunning ? Icons.stop_circle_outlined : Icons.play_circle_outline),
                  color: isRunning ? Colors.red : Colors.green,
                  iconSize: 28,
                  onPressed: () {},
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// ---------------- 虚拟机页 ----------------
class VmView extends StatelessWidget {
  const VmView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: const Text('虚拟机', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)), backgroundColor: Colors.transparent),
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

// ---------------- 设置页 ----------------
class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

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
            _buildSettingsItem(context, '语言', '简体中文', Icons.language_outlined),
          ]),
          const SizedBox(height: 24),
          _buildSettingsGroup(context, '服务器', [
            _buildSettingsItem(context, '连接地址', '192.168.1.100', Icons.lan_outlined),
            _buildSettingsItem(context, 'API 密钥', '已配置', Icons.key_outlined),
          ]),
          const SizedBox(height: 24),
          _buildSettingsGroup(context, '关于', [
            _buildSettingsItem(context, '检查更新', '版本 1.1.0', Icons.update),
            _buildSettingsItem(context, '开源主页', 'GitHub', Icons.code),
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

  Widget _buildSettingsItem(BuildContext context, String title, String trailing, IconData icon) {
    return ListTile(
      leading: Icon(icon, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(trailing, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white38 : Colors.black38, fontSize: 14)),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, size: 20),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}
