import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Make sure we import provider and our custom provider
if "import 'package:provider/provider.dart';" not in code:
    code = code.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:provider/provider.dart';\nimport 'providers/server_provider.dart';")

# Change void main() to inject ChangeNotifierProvider
main_pattern = r"void main\(\) \{\s*runApp\(const UnraidApp\(\)\);\s*\}"
new_main = """void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ServerProvider()),
      ],
      child: const UnraidApp(),
    ),
  );
}"""
code = re.sub(main_pattern, new_main, code)

# Update DashboardView to consume the provider data
dashboard_pattern = r"class DashboardView extends StatelessWidget \{.*?\}"
# Find the end of DashboardView
start_idx = code.find("class DashboardView extends StatelessWidget {")
if start_idx != -1:
    # Find matching brace. This is complex in regex, let's just do text replacement for the build method
    
    build_start = code.find("Widget build(BuildContext context) {", start_idx)
    code = code[:build_start] + """Widget build(BuildContext context) {
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
""" + code[code.find("Row(", build_start):]

    # Now replace the hardcoded CPU/Mem with provider variables
    code = code.replace("_buildSquareCard(context, 'CPU', '12%', '45°C'", "_buildSquareCard(context, 'CPU', serverProvider.cpuUsage, '45°C'")
    code = code.replace("_buildWideCard(context, '内存使用率', '45%', '14.4 GB / 32 GB', Icons.memory_sharp, Colors.purple, progress: 0.45)", 
                        "_buildWideCard(context, '内存使用率', serverProvider.memUsage, '14.4 GB / 32 GB', Icons.memory_sharp, Colors.purple, progress: 0.45)")

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)
