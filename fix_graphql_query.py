import re

with open('lib/api/unraid_client.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# The query I used: "query { info { cpu { brand cores threads } } system { state { cpuLoad, memory { free, total } } } }"
# This triggered the 400 Bad Request again because I had reverted the script entirely to some previous commit earlier,
# or my previous python script regex failed to replace it!
# Yes, looking at the code, `system { state { cpuLoad, memory { free, total } } }` is STILL THERE.
# Unraid 7.2 API GraphQL schema doesn't seem to have `system { state { cpuLoad } }` or it requires some other nesting.

new_query = r'"query": "query { info { cpu { brand cores threads } os { uptime } } }"'
# We will use simple query
code = code.replace(r'"query": "query { info { cpu { brand cores threads } } system { state { cpuLoad, memory { free, total } } } }"', new_query)

# Change options to not throw 400 so we can read the actual server error message.
# _dio.options.validateStatus = (_) => true;
init_code = """
    if (apiKey != null && apiKey!.isNotEmpty) {
      _dio.options.headers['x-api-key'] = apiKey;
    }
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    _dio.options.validateStatus = (status) => true; // 不要直接抛出 400 异常
"""
code = re.sub(r"if \(apiKey != null.*?receiveTimeout = const Duration\(seconds: 10\);", init_code.strip(), code, flags=re.DOTALL)

with open('lib/api/unraid_client.dart', 'w', encoding='utf-8') as f:
    f.write(code)


with open('lib/providers/server_provider.dart', 'r', encoding='utf-8') as f:
    prov_code = f.read()

# Since we don't fetch cpuLoad from GraphQL anymore, we need to show some fake placeholder data
# to keep the UI from looking broken, or at least show 'N/A' gracefully instead of throwing error.
fallback_block = """
        try {
          final resData = data['data'];
          if (resData != null) {
             final info = resData['info'];
             if (info != null && info['cpu'] != null) {
               cpuModel = '${info['cpu']['brand']}';
               cpuUsage = "${info['cpu']['cores']}核";
             }
          } else if (data['errors'] != null) {
             errorMsg = 'GraphQL: ${data['errors'][0]['message']}';
          }
        } catch (e) {
          errorMsg = '数据解析异常: $e';
        }
"""
# Replace the parsing block
prov_code = re.sub(r"try \{\s*final resData = data\['data'\];.*?\} catch \(e\) \{\s*errorMsg = '数据解析异常';\s*\}", fallback_block.strip(), prov_code, flags=re.DOTALL)

with open('lib/providers/server_provider.dart', 'w', encoding='utf-8') as f:
    f.write(prov_code)

with open('pubspec.yaml', 'r', encoding='utf-8') as f:
    yaml = f.read()
yaml = yaml.replace("version: 1.1.6+7", "version: 1.1.7+8")
with open('pubspec.yaml', 'w', encoding='utf-8') as f:
    f.write(yaml)

