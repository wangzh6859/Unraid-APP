import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# I can see from grep output that I accidentally left the old save button inside the Unraid API group!
# Lines 767-781 are the old save button: `SizedBox(width: double.infinity, height: 48, child: ElevatedButton...`
# And then another one at 810.

# Let's clean up the whole build method of SettingsView to be completely flawless
clean_build = """
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('设置', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingsGroup(context, '服务器连接配置 (Unraid API)', [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Unraid API 地址 (包含端口)', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _ipController,
                    decoration: InputDecoration(
                      hintText: '例如: http://192.168.1.100:19009',
                      filled: true,
                      fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.lan),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('API Key (密钥)', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _keyController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: '输入您的 Unraid API Key',
                      filled: true,
                      fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.key),
                    ),
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 24),
          _buildSettingsGroup(context, 'SSH 连接配置 (用于读取真实负载和GPU状态)', [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SSH 主机 IP (通常同上)', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(controller: _sshHostController, decoration: InputDecoration(hintText: '例: 192.168.1.100', filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
                  const SizedBox(height: 16),
                  const Text('SSH 用户名', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(controller: _sshUserController, decoration: InputDecoration(hintText: '默认: root', filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
                  const SizedBox(height: 16),
                  const Text('SSH 密码', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(controller: _sshPassController, obscureText: true, decoration: InputDecoration(hintText: '输入您的 root 密码', filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveSettings,
              icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
              label: const Text('保存所有配置并测试连接', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5722),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildSettingsGroup(context, '外观与通用', [
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: const Text('主题设置'),
              trailing: DropdownButton<ThemeMode>(
                value: themeNotifier.value,
                underline: const SizedBox(),
                dropdownColor: Theme.of(context).cardColor,
                items: const [
                  DropdownMenuItem(value: ThemeMode.system, child: Text('跟随系统')),
                  DropdownMenuItem(value: ThemeMode.light, child: Text('浅色模式')),
                  DropdownMenuItem(value: ThemeMode.dark, child: Text('深色模式')),
                ],
                onChanged: (mode) {
                  if (mode != null) {
                    themeNotifier.value = mode;
                  }
                },
              ),
            ),
          ]),
        ],
      ),
    );
  }
"""

pattern = r"  @override\n  Widget build\(BuildContext context\) \{.*?_buildSettingsGroup\(context, '外观与通用', \["

code = re.sub(pattern, clean_build.strip()[:-54], code, flags=re.DOTALL) # slicing off the end to match replacement

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

