import 'package:flutter/material.dart';

void main() {
  runApp(const UnraidApp());
}

class UnraidApp extends StatelessWidget {
  const UnraidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Unraid Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange, 
          brightness: Brightness.dark,
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
      backgroundColor: Colors.black,
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: const Color(0xFF121212),
        indicatorColor: Colors.deepOrange.withOpacity(0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: Colors.deepOrange),
            label: '状态',
          ),
          NavigationDestination(
            icon: Icon(Icons.view_in_ar_outlined),
            selectedIcon: Icon(Icons.view_in_ar, color: Colors.deepOrange),
            label: 'Docker',
          ),
          NavigationDestination(
            icon: Icon(Icons.computer_outlined),
            selectedIcon: Icon(Icons.computer, color: Colors.deepOrange),
            label: '虚拟机',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings, color: Colors.deepOrange),
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
          title: const Text('Unraid Tower', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          actions: [
            IconButton(
              icon: const Icon(Icons.power_settings_new, color: Colors.redAccent),
              onPressed: () {},
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildMetricCard('CPU 负载', '12%', '温度: 45°C', Icons.memory, Colors.blue),
              const SizedBox(height: 16),
              _buildMetricCard('内存使用', '45%', '16GB / 32GB', Icons.developer_board, Colors.purple),
              const SizedBox(height: 16),
              _buildMetricCard('阵列容量', '68%', '12TB 可用 / 64TB 总量', Icons.storage, Colors.orange),
              const SizedBox(height: 16),
              _buildMetricCard('网络速率', '↓ 12MB/s', '↑ 3.4MB/s', Icons.network_check, Colors.green),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String mainValue, String subValue, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 36, color: color),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 4),
                Text(mainValue, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subValue, style: const TextStyle(color: Colors.white54, fontSize: 13)),
              ],
            ),
          ),
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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Docker 容器', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDockerItem('Plex', 'Running', true),
          _buildDockerItem('Nextcloud', 'Running', true),
          _buildDockerItem('qbittorrent', 'Running', true),
          _buildDockerItem('HomeAssistant', 'Stopped', false),
        ],
      ),
    );
  }

  Widget _buildDockerItem(String name, String status, bool isRunning) {
    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isRunning ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
          child: Icon(Icons.view_in_ar, color: isRunning ? Colors.green : Colors.red),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        subtitle: Text(status, style: TextStyle(color: isRunning ? Colors.greenAccent : Colors.redAccent)),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert, color: Colors.white54),
          itemBuilder: (context) => [
            PopupMenuItem(child: Text(isRunning ? '停止' : '启动')),
            const PopupMenuItem(child: Text('重启')),
            const PopupMenuItem(child: Text('查看日志')),
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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('虚拟机', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.computer, size: 80, color: Colors.white24),
            const SizedBox(height: 16),
            const Text('暂无运行中的虚拟机', style: TextStyle(color: Colors.white54, fontSize: 16)),
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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('设置', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        children: [
          const ListTile(
            title: Text('服务器连接'),
            subtitle: Text('192.168.1.100'),
            leading: Icon(Icons.link),
          ),
          const Divider(color: Colors.white10),
          const ListTile(
            title: Text('API 密钥'),
            subtitle: Text('已配置'),
            leading: Icon(Icons.vpn_key),
          ),
        ],
      ),
    );
  }
}
