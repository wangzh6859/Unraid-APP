with open('pubspec.yaml', 'r', encoding='utf-8') as f:
    yaml = f.read()
yaml = yaml.replace("version: 2.5.4+27", "version: 2.5.5+28")
with open('pubspec.yaml', 'w', encoding='utf-8') as f:
    f.write(yaml)
