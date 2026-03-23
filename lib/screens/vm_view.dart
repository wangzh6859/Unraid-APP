import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/server_provider.dart';

class VmView extends StatefulWidget {
  const VmView({super.key});

  @override
  State<VmView> createState() => _VmViewState();
}

class _VmViewState extends State<VmView> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ServerProvider>(
      builder: (context, server, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('虚拟机', style: TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => server.fetchStats(),
              ),
            ],
          ),
          body: server.vms.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.computer, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('正在初始化原生引擎或未发现虚拟机', style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 8),
                        Text(
                          server.rawVmResponse,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: server.vms.length,
                  itemBuilder: (context, index) {
                     return Card(
                       child: ListTile(
                         title: Text('虚拟机 $index'),
                       )
                     );
                  }
              ),
        );
      },
    );
  }
}
