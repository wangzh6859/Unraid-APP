import re
with open('pubspec.yaml', 'r', encoding='utf-8') as f:
    yaml = f.read()
yaml = re.sub(r"version: .*", "version: 2.1.4+44", yaml)
with open('pubspec.yaml', 'w', encoding='utf-8') as f:
    f.write(yaml)

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()
code = re.sub(r"v\d+\.\d+\.\d+", "v2.1.4", code)
with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

with open('lib/screens/vm_view.dart', 'r', encoding='utf-8') as f:
    vcode = f.read()
vcode = re.sub(r"【全向雷达 V.*?】", "【全向雷达 V2.1.4】", vcode)
with open('lib/screens/vm_view.dart', 'w', encoding='utf-8') as f:
    f.write(vcode)
