with open('pubspec.yaml', 'r', encoding='utf-8') as f:
    yaml = f.read()
yaml = yaml.replace("version: 2.6.2+32", "version: 2.7.0+33")
with open('pubspec.yaml', 'w', encoding='utf-8') as f:
    f.write(yaml)
