with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# The injection in the previous step messed up the code slicing.
# I duplicated the SliverAppBar content by mistake.
# Let's restore the DashboardView completely to ensure it's correct.

dashboard_clean = """
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
                  Text('Intel Core i5-13500 · 14 Cores', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.normal)),
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
                  Expanded(child: _buildSquareCard(context, 'GPU', '8%', 'NVDEC 待机', Icons.developer_board, Colors.green)),
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
"""

import re
pattern = r"class DashboardView extends StatelessWidget \{.*?(?=  Widget _buildShortcutCard)"
code = re.sub(pattern, dashboard_clean, code, flags=re.DOTALL)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)
