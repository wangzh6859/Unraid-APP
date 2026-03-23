with open('pubspec.yaml', 'r', encoding='utf-8') as f:
    yaml = f.read()
yaml = yaml.replace("version: 2.3.0+14", "version: 2.3.1+15")
with open('pubspec.yaml', 'w', encoding='utf-8') as f:
    f.write(yaml)
