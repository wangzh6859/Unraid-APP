with open('pubspec.yaml', 'r', encoding='utf-8') as f:
    yaml = f.read()
yaml = yaml.replace("version: 1.1.7+8", "version: 2.0.0+1")
with open('pubspec.yaml', 'w', encoding='utf-8') as f:
    f.write(yaml)
