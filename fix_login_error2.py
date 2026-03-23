import re
with open('lib/api/unraid_web_client.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Don't use regex for replace string if it has backslashes
old_block = """      if (dashResp.statusCode == 200) {
        final html = dashResp.data.toString();
        final RegExp regex = RegExp(r'var\s+csrf_token\s*=\s*"([^"]+)"');
        final match = regex.firstMatch(html);
        if (match != null && match.groupCount >= 1) {
          _csrfToken = match.group(1)!;
          return true;
        }
      }
      return false;"""

new_block = """      if (dashResp.statusCode == 200) {
        final html = dashResp.data.toString();
        final RegExp regex = RegExp(r'var\\s+csrf_token\\s*=\\s*"([^"]+)"');
        final match = regex.firstMatch(html);
        if (match != null && match.groupCount >= 1) {
          _csrfToken = match.group(1)!;
          return true;
        } else {
           throw Exception("未能在 Dashboard 找到 csrf_token");
        }
      } else {
         throw Exception("Dashboard 响应码: ${dashResp.statusCode}");
      }"""

code = code.replace(old_block, new_block)

with open('lib/api/unraid_web_client.dart', 'w', encoding='utf-8') as f:
    f.write(code)

