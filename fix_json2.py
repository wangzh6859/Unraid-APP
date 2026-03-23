with open('lib/api/unraid_client.dart', 'r', encoding='utf-8') as f:
    code = f.read()

code = code.replace("          import 'dart:convert';\n", "")

with open('lib/api/unraid_client.dart', 'w', encoding='utf-8') as f:
    f.write(code)
