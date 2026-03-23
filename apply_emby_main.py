import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Register Provider
code = code.replace("import 'providers/server_provider.dart';", "import 'providers/server_provider.dart';\nimport 'providers/emby_provider.dart';")
code = code.replace("ChangeNotifierProvider(create: (_) => ServerProvider()),", "ChangeNotifierProvider(create: (_) => ServerProvider()),\n        ChangeNotifierProvider(create: (_) => EmbyProvider()),")

# Update MediaView
media_view = """class MediaView extends StatefulWidget {
  const MediaView({super.key});
  @override
  State<MediaView> createState() => _MediaViewState();
}

class _MediaViewState extends State<MediaView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmbyProvider>().fetchMedia();
    });
  }

  @override
  Widget build(BuildContext context) {
    final embyProvider = context.watch<EmbyProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            floating: true,
            title: const Text('影音中心', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => embyProvider.fetchMedia(),
              )
            ],
            backgroundColor: Colors.transparent,
          ),
          if (embyProvider.isLoading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (embyProvider.errorMsg.isNotEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 60, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(embyProvider.errorMsg, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            )
          else if (embyProvider.latestItems.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text('没有最近添加的内容，或者未配置Emby', style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.68,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = embyProvider.latestItems[index];
                    final imageUrl = embyProvider.getImageUrl(item['Id']);
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: isDark ? Colors.white10 : Colors.grey.shade100,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (imageUrl.isNotEmpty)
                            Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.movie_creation, size: 40, color: Colors.grey)),
                            )
                          else
                            const Center(child: Icon(Icons.movie_creation, size: 40, color: Colors.grey)),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearColorGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [Colors.black87, Colors.transparent],
                                ),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                item['Name'] ?? '未知内容',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: embyProvider.latestItems.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
"""

# Wait, LinearColorGradient doesn't exist, it's LinearGradient.
media_view = media_view.replace("LinearColorGradient", "LinearGradient")

code = re.sub(r"class MediaView extends StatelessWidget \{.*?\n\}\n", media_view, code, flags=re.DOTALL)


# Update Settings UI state variables to include Emby
settings_state = """class _SettingsViewState extends State<SettingsView> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _embyUrlController = TextEditingController();
  final TextEditingController _embyKeyController = TextEditingController();
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
      _embyUrlController.text = prefs.getString('emby_url') ?? 'https://emby.5nas.asia:16666';
      _embyKeyController.text = prefs.getString('emby_api_key') ?? '675fa80d238d42caaed2f667c6c28b50';
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('unraid_ip', _ipController.text);
    await prefs.setString('unraid_api_key', _keyController.text);
    await prefs.setString('emby_url', _embyUrlController.text);
    await prefs.setString('emby_api_key', _embyKeyController.text);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ 配置已保存！'), backgroundColor: Colors.green),
      );
      setState(() => _isSaving = false);
    }
  }"""

code = re.sub(r"class _SettingsViewState extends State<SettingsView> \{.*?Future<void> _saveSettings\(\) async \{.*?\n  \}", settings_state, code, flags=re.DOTALL)

# Inject the Emby settings group in UI
emby_group = """          const SizedBox(height: 24),
          _buildSettingsGroup(context, 'Emby 影音中心配置', [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Emby 服务端地址 (包含端口)', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(controller: _embyUrlController, decoration: InputDecoration(hintText: '例: https://emby.5nas.asia:8096', filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), prefixIcon: const Icon(Icons.movie))),
                  const SizedBox(height: 16),
                  const Text('Emby API 密钥', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(controller: _embyKeyController, obscureText: true, decoration: InputDecoration(hintText: '输入在 Emby 后台生成的 API Key', filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), prefixIcon: const Icon(Icons.vpn_key))),
                ],
              ),
            ),
          ]),"""

code = re.sub(r"const SizedBox\(height: 24\),\s*SizedBox\(\s*width: double\.infinity,\s*height: 48,\s*child: ElevatedButton\.icon\(", emby_group + "\n          const SizedBox(height: 24),\n          SizedBox(\n            width: double.infinity,\n            height: 48,\n            child: ElevatedButton.icon(", code)

# Update version to trigger action
code = code.replace("version: 1.1.5+6", "version: 1.1.6+7")

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

with open('pubspec.yaml', 'r', encoding='utf-8') as f:
    yaml = f.read()
yaml = yaml.replace("version: 1.1.5+6", "version: 1.1.6+7")
with open('pubspec.yaml', 'w', encoding='utf-8') as f:
    f.write(yaml)

