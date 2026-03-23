import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Update DashboardView to show real GPU
code = code.replace("Expanded(child: _buildSquareCard(context, 'GPU', '8%', 'NVDEC 待机', Icons.developer_board, Colors.green)),",
                    "Expanded(child: _buildSquareCard(context, 'GPU', serverProvider.gpuUsage, serverProvider.gpuTemp, Icons.developer_board, Colors.green)),")

# Add SSH fields to Settings
new_settings_state = """
class _SettingsViewState extends State<SettingsView> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _sshHostController = TextEditingController();
  final TextEditingController _sshUserController = TextEditingController();
  final TextEditingController _sshPassController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ipController.text = prefs.getString('unraid_ip') ?? 'http://192.168.1.100:19009';
      _keyController.text = prefs.getString('unraid_api_key') ?? '';
      _sshHostController.text = prefs.getString('ssh_host') ?? '';
      _sshUserController.text = prefs.getString('ssh_user') ?? 'root';
      _sshPassController.text = prefs.getString('ssh_pass') ?? '';
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('unraid_ip', _ipController.text);
    await prefs.setString('unraid_api_key', _keyController.text);
    await prefs.setString('ssh_host', _sshHostController.text);
    await prefs.setString('ssh_user', _sshUserController.text);
    await prefs.setString('ssh_pass', _sshPassController.text);
    await prefs.setInt('ssh_port', 22);
"""
code = re.sub(r"class _SettingsViewState extends State<SettingsView> \{.*?await prefs.setString\('unraid_api_key', _keyController\.text\);", new_settings_state.strip(), code, flags=re.DOTALL)

# Inject SSH UI blocks into the build method of Settings
ssh_ui = """
          _buildSettingsGroup(context, 'SSH 连接配置 (用于读取GPU状态)', [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SSH 主机 IP', style: TextStyle(fontWeight: FontWeight.w600)),
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
          const SizedBox(height: 24),
"""
code = code.replace("const SizedBox(height: 24),\n          _buildSettingsGroup(context, '外观与通用', [", ssh_ui + "          _buildSettingsGroup(context, '外观与通用', [")

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)
