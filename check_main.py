with open('lib/main.dart', 'r') as f:
    code = f.read()

import re
m1 = re.search(r'final List<Widget> _pages = \[.*?\];', code, re.DOTALL)
if m1:
    print("Pages block:\n", m1.group(0))

m2 = re.search(r'items: const \[.*?\]', code, re.DOTALL)
if m2:
    print("Nav items block:\n", m2.group(0))
