with open('pubspec.yaml', 'r', encoding='utf-8') as f:
    yaml = f.read()
yaml = yaml.replace("version: 2.6.0+30", "version: 2.6.1+31")
with open('pubspec.yaml', 'w', encoding='utf-8') as f:
    f.write(yaml)
