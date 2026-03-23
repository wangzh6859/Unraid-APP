import re

with open('lib/api/unraid_client.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Fix the bug where Dio tries to append /api/system directly without a slash if the base url doesn't have it,
# or user accidentally pasted without http, or pasted with API at the end.
# We will do some clean up on the baseUrl inside the init() method.

new_init = """
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    String? rawUrl = prefs.getString('unraid_ip');
    apiKey = prefs.getString('unraid_api_key');
    
    if (rawUrl != null && rawUrl.isNotEmpty) {
      // 容错处理: 如果用户输入了结尾多余的字符清理掉，确保是合法的 baseUrl
      rawUrl = rawUrl.trim();
      if (!rawUrl.startsWith('http')) {
        rawUrl = 'http://' + rawUrl;
      }
      if (rawUrl.endsWith('/')) {
        rawUrl = rawUrl.substring(0, rawUrl.length - 1);
      }
      baseUrl = rawUrl;
      _dio.options.baseUrl = baseUrl!;
    }
    
    if (apiKey != null && apiKey!.isNotEmpty) {
      _dio.options.headers['x-api-key'] = apiKey;
    }
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
  }
"""

code = re.sub(r"Future<void> init\(\) async \{.*?(?=\n  // 获取 CPU)", new_init, code, flags=re.DOTALL)

with open('lib/api/unraid_client.dart', 'w', encoding='utf-8') as f:
    f.write(code)
