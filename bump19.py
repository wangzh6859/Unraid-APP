with open('pubspec.yaml', 'r', encoding='utf-8') as f:
    yaml = f.read()
yaml = yaml.replace("version: 2.4.1+19", "version: 2.4.2+20")
with open('pubspec.yaml', 'w', encoding='utf-8') as f:
    f.write(yaml)
