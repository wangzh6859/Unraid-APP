import re
with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

m = re.search(r'v\d+\.\d+\.\d+', code)
if m:
    print("Found version string in UI:", m.group(0))
    code = re.sub(r'v\d+\.\d+\.\d+', 'v2.0.5', code)
    with open('lib/main.dart', 'w', encoding='utf-8') as f:
        f.write(code)
