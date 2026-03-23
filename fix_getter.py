with open('lib/api/unraid_web_client.dart', 'r', encoding='utf-8') as f:
    code = f.read()

code = code.replace("String _csrfToken = '';", "String _csrfToken = '';\n  String getCsrfToken() => _csrfToken;")

with open('lib/api/unraid_web_client.dart', 'w', encoding='utf-8') as f:
    f.write(code)
