import re

with open('lib/api/unraid_web_client.dart', 'r', encoding='utf-8') as f:
    code = f.read()

code = code.replace("import 'package:html/parser.dart' show parse;", "")

with open('lib/api/unraid_web_client.dart', 'w', encoding='utf-8') as f:
    f.write(code)

with open('pubspec.yaml', 'r', encoding='utf-8') as f:
    yaml = f.read()

yaml = re.sub(r"\s+html:\s+\^0\.15\.4", "", yaml)

with open('pubspec.yaml', 'w', encoding='utf-8') as f:
    f.write(yaml)
