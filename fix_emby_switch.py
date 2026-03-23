import re

# Update AppConfig to decouple Emby auth from global auth. Global is just the default.
with open('lib/utils/app_config.dart', 'r', encoding='utf-8') as f:
    config_code = f.read()

new_config = """import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static String baseDomain = '';
  static String username = '';
  static String password = '';
  
  static String embyCustomUrl = '';
  static String embyCustomUser = '';
  static String embyCustomPass = '';
  
  static String embyToken = '';
  static String embyUserId = '';

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    baseDomain = prefs.getString('base_domain') ?? '';
    username = prefs.getString('username') ?? '';
    password = prefs.getString('password') ?? '';
    
    embyCustomUrl = prefs.getString('emby_custom_url') ?? '';
    embyCustomUser = prefs.getString('emby_custom_user') ?? '';
    embyCustomPass = prefs.getString('emby_custom_pass') ?? '';
    
    embyToken = prefs.getString('emby_token') ?? '';
    embyUserId = prefs.getString('emby_user_id') ?? '';
  }

  static Future<void> save(String domain, String user, String pass) async {
    final prefs = await SharedPreferences.getInstance();
    String url = domain.trim();
    if (url.isNotEmpty && !url.startsWith('http')) {
      url = 'https://' + url;
    }
    
    await prefs.setString('base_domain', url);
    await prefs.setString('username', user);
    await prefs.setString('password', pass);
    
    baseDomain = url;
    username = user;
    password = pass;
  }
  
  static Future<void> saveEmbyAccount(String url, String user, String pass) async {
    final prefs = await SharedPreferences.getInstance();
    String cUrl = url.trim();
    if (cUrl.isNotEmpty && !cUrl.startsWith('http')) {
      cUrl = 'https://' + cUrl;
    }
    
    await prefs.setString('emby_custom_url', cUrl);
    await prefs.setString('emby_custom_user', user);
    await prefs.setString('emby_custom_pass', pass);
    await prefs.remove('emby_token'); // reset token on account change
    await prefs.remove('emby_user_id');
    
    embyCustomUrl = cUrl;
    embyCustomUser = user;
    embyCustomPass = pass;
    embyToken = '';
    embyUserId = '';
  }

  static Future<void> saveEmbyAuth(String token, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('emby_token', token);
    await prefs.setString('emby_user_id', userId);
    embyToken = token;
    embyUserId = userId;
  }

  static String get glancesUrl {
    if (baseDomain.isEmpty) return '';
    try {
      final uri = Uri.parse(baseDomain);
      return '${uri.scheme}://glances.${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
    } catch (_) {
      return '';
    }
  }

  static String get embyUrl {
    if (embyCustomUrl.isNotEmpty) return embyCustomUrl;
    if (baseDomain.isEmpty) return '';
    try {
      final uri = Uri.parse(baseDomain);
      return '${uri.scheme}://emby.${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
    } catch (_) {
      return '';
    }
  }
  
  static String get activeEmbyUser {
    return embyCustomUser.isNotEmpty ? embyCustomUser : username;
  }
  
  static String get activeEmbyPass {
    return embyCustomPass.isNotEmpty ? embyCustomPass : password;
  }
}"""
with open('lib/utils/app_config.dart', 'w', encoding='utf-8') as f:
    f.write(new_config)


# Update EmbyClient to use activeEmbyUser
with open('lib/api/emby_client.dart', 'r', encoding='utf-8') as f:
    emby_code = f.read()
emby_code = emby_code.replace("AppConfig.username", "AppConfig.activeEmbyUser")
emby_code = emby_code.replace("AppConfig.password", "AppConfig.activeEmbyPass")
with open('lib/api/emby_client.dart', 'w', encoding='utf-8') as f:
    f.write(emby_code)

# Add an Emby Account Dialog in MediaView (in main.dart)
with open('lib/main.dart', 'r', encoding='utf-8') as f:
    main_code = f.read()

# In _MediaViewState build, add an action button to switch account.
emby_dialog = """
  void _showEmbyAccountDialog() {
    final urlCtrl = TextEditingController(text: AppConfig.embyUrl);
    final userCtrl = TextEditingController(text: AppConfig.activeEmbyUser);
    final passCtrl = TextEditingController(text: AppConfig.activeEmbyPass);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Emby 账号配置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'Emby 地址 (含端口)')),
            const SizedBox(height: 8),
            TextField(controller: userCtrl, decoration: const InputDecoration(labelText: '用户名')),
            const SizedBox(height: 8),
            TextField(controller: passCtrl, obscureText: true, decoration: const InputDecoration(labelText: '密码')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () async {
              await AppConfig.saveEmbyAccount(urlCtrl.text, userCtrl.text, passCtrl.text);
              Navigator.pop(ctx);
              context.read<EmbyProvider>().fetchMedia();
            },
            child: const Text('保存并重连'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
"""
main_code = main_code.replace("  @override\n  Widget build(BuildContext context) {", emby_dialog)

# Add the account button to the SliverAppBar actions
app_bar_pattern = r"actions: \[\n              IconButton\(\n                icon: const Icon\(Icons.refresh\),\n                onPressed: \(\) => embyProvider.fetchMedia\(\),\n              \)\n            \],"
new_app_bar = """actions: [
              IconButton(icon: const Icon(Icons.manage_accounts), onPressed: _showEmbyAccountDialog),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => embyProvider.fetchMedia(),
              )
            ],"""
main_code = re.sub(app_bar_pattern, new_app_bar, main_code)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(main_code)

