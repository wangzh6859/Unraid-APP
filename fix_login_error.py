import re
with open('lib/api/unraid_web_client.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Using raw string for replacement string to avoid backslash hell
login_err_handling = r"""      if (dashResp.statusCode == 200) {
        final html = dashResp.data.toString();
        final RegExp regex = RegExp(r'var\s+csrf_token\s*=\s*"([^"]+)"');
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

code = re.sub(r"if \(dashResp\.statusCode == 200\) \{.*?return false;\n      \}", login_err_handling, code, flags=re.DOTALL)

with open('lib/api/unraid_web_client.dart', 'w', encoding='utf-8') as f:
    f.write(code)

with open('lib/providers/server_provider.dart', 'r', encoding='utf-8') as f:
    pcode = f.read()

pcode = pcode.replace("errorMsg = dashResult['error'];", "errorMsg = dashResult['error'];\n      rawVmResponse = errorMsg;")

with open('lib/providers/server_provider.dart', 'w', encoding='utf-8') as f:
    f.write(pcode)

