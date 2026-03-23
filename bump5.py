with open('pubspec.yaml', 'r', encoding='utf-8') as f:
    yaml = f.read()
yaml = yaml.replace("version: 2.0.4+5", "version: 2.1.0+6")
with open('pubspec.yaml', 'w', encoding='utf-8') as f:
    f.write(yaml)
