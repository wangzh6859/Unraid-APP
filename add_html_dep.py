import re
with open('pubspec.yaml', 'r') as f:
  yaml = f.read()

if "html:" not in yaml:
  yaml = yaml.replace("dio: ^5.4.3+1", "dio: ^5.4.3+1\n  html: ^0.15.4")

with open('pubspec.yaml', 'w') as f:
  f.write(yaml)
