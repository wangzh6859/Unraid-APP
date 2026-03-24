import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/server_provider.dart';

class VmView extends StatelessWidget {
  const VmView({super.key});

  @override
  Widget build(BuildContext context) {
    final serverProvider = Provider.of<ServerProvider>(context);
    
    return Scaffold(
      appBar: AppBar(title: const Text('【全向雷达 V2.1.4】')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
             Text(
               '连接状态: ${serverProvider.errorMsg.isEmpty ? 'OK' : serverProvider.errorMsg}',
               style: TextStyle(color: serverProvider.errorMsg.isEmpty ? Colors.green : Colors.red),
             ),
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
