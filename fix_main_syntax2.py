import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Fix the missing escape slashes for $ in Dart. Dart interpolates $ in strings.
# The awk scripts used $2, $4, $3, $2 which dart tries to interpret as variables.
code = code.replace("awk '{print $2 + $4}'", "awk '{print \\$2 + \\$4}'")
code = code.replace("awk '{print $3/$2 * 100.0}'", "awk '{print \\$3/\\$2 * 100.0}'")

# There is also a syntax error in main.dart:
# 768:19: Error: Expected an identifier, but got ')'.
# Expected ']' before this.
# Let's fix line 768.

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

