import re
with open('lib/api/unraid_web_client.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Change it to GET /webGui/scripts/vmmanager, but also if it fails, return the error code!
vms_fetch = """    try {
      final response = await _dio.post(
        '${AppConfig.baseDomain}/update.htm',
        data: {'csrf_token': _csrfToken, 'api': 'domain', 'action': 'get_content'},
        options: Options(
          headers: {'Cookie': _cookie},
          contentType: Headers.formUrlEncodedContentType,
        ),
      );
      if (response.statusCode == 200) {
         return {'data': response.data.toString()};
      }
      return {'error': '无法获取虚拟机列表: HTTP ${response.statusCode} - ${response.statusMessage}'};"""

code = re.sub(r"    try \{\n      final response = await _dio\.post\(\n        '\$\{AppConfig\.baseDomain\}/webGui/scripts/vmmanager',\n        options: Options\(headers: \{'Cookie': _cookie\}\),\n      \);\n      if \(response\.statusCode == 200\) \{\n         return \{'data': response\.data\.toString\(\)\};\n      \}\n      return \{'error': '无法获取虚拟机列表'\};", vms_fetch, code, flags=re.DOTALL)

with open('lib/api/unraid_web_client.dart', 'w', encoding='utf-8') as f:
    f.write(code)
