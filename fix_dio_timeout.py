import re
with open('lib/api/unraid_web_client.dart', 'r', encoding='utf-8') as f:
    code = f.read()

timeout_code = """
  UnraidWebClient() {
    _dio.options.validateStatus = (status) => true;
    _dio.options.followRedirects = false; // Important for login capture
    _dio.options.connectTimeout = const Duration(seconds: 5);
    _dio.options.receiveTimeout = const Duration(seconds: 5);
  }
"""

code = re.sub(r"UnraidWebClient\(\) \{.*?\n  \}", timeout_code, code, flags=re.DOTALL)

with open('lib/api/unraid_web_client.dart', 'w', encoding='utf-8') as f:
    f.write(code)
