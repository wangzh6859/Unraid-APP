with open('pubspec.yaml', 'r', encoding='utf-8') as f:
    yaml = f.read()
yaml = yaml.replace("version: 2.6.1+31", "version: 2.6.2+32")
with open('pubspec.yaml', 'w', encoding='utf-8') as f:
    f.write(yaml)
