with open('pubspec.yaml', 'r', encoding='utf-8') as f:
    yaml = f.read()
yaml = yaml.replace("version: 2.5.2+25", "version: 2.5.3+26")
with open('pubspec.yaml', 'w', encoding='utf-8') as f:
    f.write(yaml)
