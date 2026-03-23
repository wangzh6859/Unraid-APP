with open('pubspec.yaml', 'r', encoding='utf-8') as f:
    yaml = f.read()
yaml = yaml.replace("version: 2.3.2+16", "version: 2.3.3+17")
with open('pubspec.yaml', 'w', encoding='utf-8') as f:
    f.write(yaml)
