import re
with open('pubspec.yaml', 'r', encoding='utf-8') as f:
    yaml = f.read()
yaml = re.sub(r"version: .*", "version: 2.0.9+39", yaml)
with open('pubspec.yaml', 'w', encoding='utf-8') as f:
    f.write(yaml)

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()
code = re.sub(r"v\d+\.\d+\.\d+", "v2.0.9", code)
with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)
