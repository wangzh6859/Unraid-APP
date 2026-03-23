import re
with open('lib/api/unraid_web_client.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Let's hit /webGui/scripts/vmmanager with a POST to see what it spits out
vms_fetch = """    try {
      final response = await _dio.post(
        '${AppConfig.baseDomain}/webGui/scripts/vmmanager',
        options: Options(headers: {'Cookie': _cookie}),
      );
      if (response.statusCode == 200) {
         return {'data': response.data.toString()};
      }
      return {'error': '无法获取虚拟机列表'};"""

code = re.sub(r"    try \{\n      final response = await _dio\.get\(\n        '\$\{AppConfig\.baseDomain\}/VMs',\n        options: Options\(headers: \{'Cookie': _cookie\}\),\n      \);\n      if \(response\.statusCode == 200\) \{\n         return \{'data': response\.data\.toString\(\)\};\n      \}\n      return \{'error': '无法获取虚拟机列表'\};", vms_fetch, code, flags=re.DOTALL)

with open('lib/api/unraid_web_client.dart', 'w', encoding='utf-8') as f:
    f.write(code)
