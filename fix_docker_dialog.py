import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

dialog_code = """
  void _showPortainerConfigDialog() {
    final userCtrl = TextEditingController(text: AppConfig.portainerUser);
    final passCtrl = TextEditingController(text: AppConfig.portainerPass);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Portainer 账号配置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: userCtrl, decoration: const InputDecoration(labelText: 'Portainer 用户名 (如 admin)')),
            const SizedBox(height: 8),
            TextField(controller: passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Portainer 密码')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () async {
              await AppConfig.savePortainerAccount(userCtrl.text, passCtrl.text);
              Navigator.pop(ctx);
              context.read<ServerProvider>().fetchStats();
            },
            child: const Text('保存并连接'),
          ),
        ],
      ),
    );
  }
"""

if "_showPortainerConfigDialog" not in code:
    code = code.replace("class _DockerViewState extends State<DockerView> {", "class _DockerViewState extends State<DockerView> {" + dialog_code)

# Add button to AppBar to trigger this
old_appbar = """      appBar: AppBar(
        title: const Text('Docker 控制台', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_tree),"""

new_appbar = """      appBar: AppBar(
        title: const Text('Docker 控制台', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.manage_accounts),
            tooltip: '配置 Portainer 账号',
            onPressed: _showPortainerConfigDialog,
          ),
          IconButton(
            icon: const Icon(Icons.account_tree),"""
            
code = code.replace(old_appbar, new_appbar)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

