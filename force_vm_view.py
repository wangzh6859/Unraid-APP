new_vm_view = """import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/server_provider.dart';

class VmView extends StatelessWidget {
  const VmView({super.key});

  @override
  Widget build(BuildContext context) {
    final serverProvider = Provider.of<ServerProvider>(context);
    
    return Scaffold(
      appBar: AppBar(title: const Text('【原生地牢 V2.0.8】')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
             Text('Token状态: ${serverProvider.errorMsg}', style: const TextStyle(color: Colors.red)),
             const SizedBox(height: 10),
             Text(serverProvider.rawVmResponse.isEmpty ? "等待数据返回中..." : serverProvider.rawVmResponse, 
               style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
          ],
        )
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          serverProvider.fetchStats();
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
"""

with open('lib/screens/vm_view.dart', 'w', encoding='utf-8') as f:
    f.write(new_vm_view)
