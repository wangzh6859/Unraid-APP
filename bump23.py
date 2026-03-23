with open('pubspec.yaml', 'r', encoding='utf-8') as f:
    yaml = f.read()
yaml = yaml.replace("version: 2.5.0+23", "version: 2.5.1+24")
with open('pubspec.yaml', 'w', encoding='utf-8') as f:
    f.write(yaml)
