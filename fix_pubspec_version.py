import re
with open('pubspec.yaml', 'r', encoding='utf-8') as f:
    yaml = f.read()

yaml = re.sub(r"version: .*", "version: 2.0.5+35", yaml)

with open('pubspec.yaml', 'w', encoding='utf-8') as f:
    f.write(yaml)
