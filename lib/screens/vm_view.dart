import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../providers/server_provider.dart';

class VmView extends StatelessWidget {
  const VmView({super.key});

  Widget _miniInfo(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color.withOpacity(0.9)),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: color.withOpacity(0.95))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final serverProvider = Provider.of<ServerProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget buildBody() {
      if (serverProvider.isLoading && serverProvider.vms.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      // If parsed VM list is available, show list.
      if (serverProvider.vms.isNotEmpty) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: serverProvider.vms.length,
          itemBuilder: (context, index) {
            final vm = serverProvider.vms[index];
            final name = (vm['name'] ?? '未知虚拟机').toString();
            final status = (vm['status'] ?? 'unknown').toString();
            final running = (vm['running'] == true);
            final cpu = (vm['cpu'] ?? '').toString();
            final mem = (vm['mem'] ?? '').toString();
            final ip = (vm['ip'] ?? '').toString();
            final autostart = vm['autostart'];

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: running ? Colors.green.withOpacity(0.3) : Colors.grey.withOpacity(0.2)),
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
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: running ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    running ? Icons.play_circle_fill : Icons.stop_circle_outlined,
                    color: running ? Colors.green : Colors.grey,
                  ),
                ),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) async {
                    final uuid = (vm['uuid'] ?? '').toString();
                    if (uuid.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('缺少 uuid，无法控制')));
                      return;
                    }

                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('正在执行: $value ...')));
                    final ok = await serverProvider.controlVm(uuid, value);
                    if (ok) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('操作已发送')));
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('操作失败，请看调试信息')));
                      }
                    }
                  },
                  itemBuilder: (_) => <PopupMenuEntry<String>>[
                    if (!running) const PopupMenuItem(value: 'start', child: Text('启动')),
                    if (running) const PopupMenuItem(value: 'stop', child: Text('关机(优雅)')),
                    if (running) const PopupMenuItem(value: 'restart', child: Text('重启')),
                    if (running) const PopupMenuItem(value: 'force-stop', child: Text('强制停止')),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, size: 14, color: (running ? Colors.green : Colors.grey).withOpacity(0.9)),
                          const SizedBox(width: 6),
                          Text(running ? '运行中' : '已停止'),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              status,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        children: [
                          if (cpu.isNotEmpty) _miniInfo(Icons.memory, cpu, Colors.blue),
                          if (mem.isNotEmpty) _miniInfo(Icons.storage, mem, Colors.orange),
                          if (ip.isNotEmpty) _miniInfo(Icons.lan, ip, Colors.teal),
                          if (autostart != null)
                            _miniInfo(Icons.power_settings_new, autostart == true ? '自启:开' : '自启:关', autostart == true ? Colors.green : Colors.grey),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }

      // Fallback: show raw debug text for troubleshooting.
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: SelectableText(
          serverProvider.rawVmResponse.isEmpty ? '等待数据返回中...' : serverProvider.rawVmResponse,
          style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
        ),
      );
    }

    final total = serverProvider.vms.length;
    final runningCount = serverProvider.vms.where((e) => e['running'] == true).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(total > 0 ? '虚拟机（$runningCount/$total 运行中）' : '虚拟机'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => serverProvider.fetchStats(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Icon(
                  serverProvider.errorMsg.isEmpty ? Icons.check_circle : Icons.error,
                  size: 16,
                  color: serverProvider.errorMsg.isEmpty ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    serverProvider.errorMsg.isEmpty ? '连接状态：OK' : '连接状态：${serverProvider.errorMsg}',
                    style: TextStyle(color: serverProvider.errorMsg.isEmpty ? Colors.green : Colors.red, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: serverProvider.rawVmHtmlPreview.isEmpty
                      ? null
                      : () async {
                          await Clipboard.setData(ClipboardData(text: serverProvider.rawVmHtmlPreview));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('已复制 /VMs 源码预览（前 8KB）')),
                            );
                          }
                        },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('复制/VMs源码', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: buildBody()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => serverProvider.fetchStats(),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
