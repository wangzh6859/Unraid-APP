import 'package:shared_preferences/shared_preferences.dart';

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

  static String get portainerUrl {
    if (baseDomain.isEmpty) return '';
    try {
      Uri uri = Uri.parse(baseDomain);
      return '${uri.scheme}://pce.${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
    } catch (e) {
      return '';
    }
  }
  
  
  static String portainerUser = '';
  static String portainerPass = '';
  
  static String get activePortainerUser => portainerUser.isNotEmpty ? portainerUser : username;
  static String get activePortainerPass => portainerPass.isNotEmpty ? portainerPass : password;
  
  static Future<void> savePortainerAccount(String user, String pass) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('portainerUser', user);
    await prefs.setString('portainerPass', pass);
    portainerUser = user;
    portainerPass = pass;
    // clear token to force re-login
    await savePortainerToken('');
  }

  static String portainerToken = '';
  
  static Future<void> savePortainerToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('portainerToken', token);
    portainerToken = token;
  }
  
}