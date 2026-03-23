import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static String baseDomain = '';
  static String username = '';
  static String password = '';
  static String embyToken = '';
  static String embyUserId = '';

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    baseDomain = prefs.getString('base_domain') ?? '';
    username = prefs.getString('username') ?? '';
    password = prefs.getString('password') ?? '';
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
    await prefs.remove('emby_token');
    await prefs.remove('emby_user_id');
    
    baseDomain = url;
    username = user;
    password = pass;
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
    if (baseDomain.isEmpty) return '';
    try {
      final uri = Uri.parse(baseDomain);
      return '${uri.scheme}://emby.${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
    } catch (_) {
      return '';
    }
  }
}
