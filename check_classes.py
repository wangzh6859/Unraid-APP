import re
with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

classes = re.findall(r"class (\w+)", code)
print("Current classes:", list(set(classes)))
