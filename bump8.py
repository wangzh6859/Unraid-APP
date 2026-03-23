with open('pubspec.yaml', 'r', encoding='utf-8') as f:
    yaml = f.read()
yaml = yaml.replace("version: 2.1.2+8", "version: 2.2.0+9")
with open('pubspec.yaml', 'w', encoding='utf-8') as f:
    f.write(yaml)
