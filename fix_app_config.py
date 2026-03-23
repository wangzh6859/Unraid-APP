import re

with open('lib/utils/app_config.dart', 'r', encoding='utf-8') as f:
    code = f.read()

if "static String portainerUser = '';" not in code:
    new_vars = """
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
"""
    code = code.replace("static String portainerToken = '';", new_vars + "\n  static String portainerToken = '';")

    # load them in load()
    code = code.replace("portainerToken = prefs.getString('portainerToken') ?? '';", "portainerToken = prefs.getString('portainerToken') ?? '';\n    portainerUser = prefs.getString('portainerUser') ?? '';\n    portainerPass = prefs.getString('portainerPass') ?? '';")

with open('lib/utils/app_config.dart', 'w', encoding='utf-8') as f:
    f.write(code)

