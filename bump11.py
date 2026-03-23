with open('pubspec.yaml', 'r', encoding='utf-8') as f:
    yaml = f.read()
yaml = yaml.replace("version: 2.2.2+11", "version: 2.2.3+12")
with open('pubspec.yaml', 'w', encoding='utf-8') as f:
    f.write(yaml)
