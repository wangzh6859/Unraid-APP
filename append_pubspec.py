with open('pubspec.yaml', 'r', encoding='utf-8') as f:
    yaml = f.read()

yaml = yaml.replace("version: 2.0.1+2", "version: 2.0.2+3")

if "flutter_launcher_icons:" not in yaml:
    yaml += """
flutter_launcher_icons:
  android: "ic_launcher"
  ios: true
  image_path: "assets/icon.png"
  min_sdk_android: 21 # android min sdk min:16, default 21
"""

with open('pubspec.yaml', 'w', encoding='utf-8') as f:
    f.write(yaml)
