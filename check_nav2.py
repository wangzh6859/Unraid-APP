import re
with open('lib/main.dart', 'r') as f:
    code = f.read()

m = re.search(r'NavigationBar\(.*?\)', code, re.DOTALL)
if m:
    print(m.group(0))
