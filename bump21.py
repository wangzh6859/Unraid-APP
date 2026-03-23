with open('pubspec.yaml', 'r', encoding='utf-8') as f:
    yaml = f.read()
yaml = yaml.replace("version: 2.4.3+21", "version: 2.4.4+22")
with open('pubspec.yaml', 'w', encoding='utf-8') as f:
    f.write(yaml)
