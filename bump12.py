with open('pubspec.yaml', 'r', encoding='utf-8') as f:
    yaml = f.read()
yaml = yaml.replace("version: 2.2.3+12", "version: 2.2.4+13")
with open('pubspec.yaml', 'w', encoding='utf-8') as f:
    f.write(yaml)
