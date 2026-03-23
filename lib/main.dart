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
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Unraid Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCard('Server Status', 'Started - Tower', Icons.dns, Colors.green),
          const SizedBox(height: 16),
          _buildCard('CPU & RAM', 'CPU: 12% / 65°C  |  RAM: 45%', Icons.memory, Colors.blue),
          const SizedBox(height: 16),
          _buildCard('Array Storage', '32TB / 64TB Used', Icons.storage, Colors.orange),
          const SizedBox(height: 16),
          _buildCard('Docker Containers', '12 Running, 3 Stopped', Icons.view_in_ar, Colors.purple),
          const SizedBox(height: 16),
          _buildCard('Virtual Machines', '1 Running (Windows 11)', Icons.computer, Colors.teal),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.deepOrange,
        child: const Icon(Icons.settings, color: Colors.white),
      ),
    );
  }

  Widget _buildCard(String title, String subtitle, IconData icon, Color iconColor) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: const Color(0xFF1E1E1E),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 32, color: iconColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Text(subtitle, style: const TextStyle(fontSize: 15, color: Colors.white70)),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white54),
      ),
    );
  }
}
