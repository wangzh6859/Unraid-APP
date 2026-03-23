import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# 6.1 Add new imports
imports = """
import 'utils/app_config.dart';
import 'screens/login_screen.dart';
"""
code = code.replace("import 'providers/emby_provider.dart';", "import 'providers/emby_provider.dart';\n" + imports)

# 6.2 Convert UnraidApp to StatefulWidget to handle Login splash logic
app_stateless = r"class UnraidApp extends StatelessWidget \{.*?\n\}"
app_stateful = """class UnraidApp extends StatefulWidget {
  const UnraidApp({super.key});
  @override
  State<UnraidApp> createState() => _UnraidAppState();
}

class _UnraidAppState extends State<UnraidApp> {
  bool _isReady = false;
  bool _hasLogin = false;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    await AppConfig.load();
    setState(() {
      _hasLogin = AppConfig.baseDomain.isNotEmpty && AppConfig.username.isNotEmpty;
      _isReady = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) {
        return MaterialApp(
          title: 'Unraid Dashboard',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: ThemeData(
            brightness: Brightness.light,
            colorSchemeSeed: const Color(0xFFFF5722),
            scaffoldBackgroundColor: const Color(0xFFF2F2F6),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorSchemeSeed: const Color(0xFFFF5722),
            scaffoldBackgroundColor: const Color(0xFF111112),
            cardColor: const Color(0xFF1C1C1E),
            useMaterial3: true,
          ),
          home: !_isReady 
              ? const Scaffold(body: Center(child: CircularProgressIndicator())) 
              : (_hasLogin ? const MainScreen() : const LoginScreen()),
        );
      },
    );
  }
}"""
code = re.sub(app_stateless, app_stateful, code, flags=re.DOTALL)

# 6.3 Update SettingsView UI completely to only show Server Address, Username, Password
settings_state_pattern = r"class _SettingsViewState extends State<SettingsView> \{.*?Widget _buildSettingsGroup\(BuildContext context, String title, List<Widget> items\) \{"
settings_stateful = """class _SettingsViewState extends State<SettingsView> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await AppConfig.load();
    setState(() {
      _ipController.text = AppConfig.baseDomain;
      _userController.text = AppConfig.username;
      _passController.text = AppConfig.password;
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    await AppConfig.save(_ipController.text, _userController.text, _passController.text);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ 配置已保存！子系统将自动派生新地址。'), backgroundColor: Colors.green),
      );
      setState(() => _isSaving = false);
    }
  }

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
          _buildSettingsGroup(context, '统一服务器认证 (全局)', [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('主服务器地址', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _ipController,
                    decoration: InputDecoration(
                      hintText: '例: https://5nas.asia:16666',
                      filled: true,
                      fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.dns),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('全局用户名', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _userController,
                    decoration: InputDecoration(
                      hintText: '用于 Glances 与 Emby',
                      filled: true,
                      fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('全局密码', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: '输入您的密码',
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
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveSettings,
              icon: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
              label: const Text('保存并重载配置', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5722),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          const SizedBox(height: 24),
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
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('退出登录', style: TextStyle(color: Colors.redAccent)),
              onTap: () async {
                 await AppConfig.save('', '', '');
                 Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
              },
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(BuildContext context, String title, List<Widget> items) {"""
code = re.sub(settings_state_pattern, settings_stateful, code, flags=re.DOTALL)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)
