import re

with open('lib/screens/vm_view.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Make it show `serverProvider.rawVmResponse` !
new_vm_view = """import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/server_provider.dart';

class VmView extends StatelessWidget {
  const VmView({super.key});

  @override
  Widget build(BuildContext context) {
    final serverProvider = Provider.of<ServerProvider>(context);
    
    return Scaffold(
      appBar: AppBar(title: const Text('虚拟机控制台')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
             const Text('以下是抓取到的原生数据：', style: TextStyle(color: Colors.grey)),
             const SizedBox(height: 10),
             Text(serverProvider.rawVmResponse, style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
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
