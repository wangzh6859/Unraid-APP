import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Row is const, not Column. 
# title: const Row( ... )
code = code.replace("title: const Row(", "title: Row(")

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

with open('lib/providers/server_provider.dart', 'r', encoding='utf-8') as f:
    prov_code = f.read()

# Let's just remove the $ from awk completely by writing it differently, or using raw string.
# Dart raw string: r"..."
prov_code = prov_code.replace("top -bn1 | grep 'Cpu(s)' | awk '{print $2 + $4}'", r"top -bn1 | grep 'Cpu(s)' | awk '{print $2 + $4}'")
prov_code = prov_code.replace("free | grep Mem | awk '{print $3/$2 * 100.0}'", r"free | grep Mem | awk '{print $3/$2 * 100.0}'")

with open('lib/providers/server_provider.dart', 'w', encoding='utf-8') as f:
    f.write(prov_code)
