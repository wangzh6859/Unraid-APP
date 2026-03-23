import re
with open('lib/api/unraid_web_client.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Instead of POSTing to update.htm, let's GET the actual /VMs page to see what's in it.
# Because the post to update.htm just gave us an action-response frame.
vms_fetch = """    try {
      final response = await _dio.get(
        '${AppConfig.baseDomain}/VMs',
        options: Options(headers: {'Cookie': _cookie}),
      );
      if (response.statusCode == 200) {
         return {'data': response.data.toString()};
      }
      return {'error': '无法获取虚拟机列表'};"""

code = re.sub(r"    try \{\n      final response = await _dio\.post\(\n        '\$\{AppConfig\.baseDomain\}/update\.htm',\n        data: \{'csrf_token': _csrfToken, 'api': 'vms'\},\n        options: Options\(\n          headers: \{'Cookie': _cookie\},\n          contentType: Headers\.formUrlEncodedContentType,\n        \),\n      \);\n      if \(response\.statusCode == 200\) \{\n         return \{'data': response\.data\.toString\(\)\};\n      \}\n      return \{'error': '无法获取虚拟机列表'\};", vms_fetch, code, flags=re.DOTALL)

with open('lib/api/unraid_web_client.dart', 'w', encoding='utf-8') as f:
    f.write(code)
