with open('pubspec.yaml', 'r', encoding='utf-8') as f:
    yaml = f.read()
yaml = yaml.replace("version: 2.7.0+33", "version: 2.7.1+34")
with open('pubspec.yaml', 'w', encoding='utf-8') as f:
    f.write(yaml)
