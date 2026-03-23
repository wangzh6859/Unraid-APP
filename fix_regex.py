import re

with open('lib/api/unraid_web_client.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Error: Unexpected token ']'. in RegExp
# Original: final RegExp regex = RegExp(r'var\s+csrf_token\s*=\s*["\']([^"\']+)["\']');
# The issue in Dart is escaping inside r'' strings, or just simple syntax error from my generation.
# Actually Dart raw strings r'...' don't need backslashes for quotes usually, but `\'` might cause an issue if the string uses single quotes.
# Let's change the regex to a simpler one.

old_regex = r"final RegExp regex = RegExp(r'var\s+csrf_token\s*=\s*[\"\'\']([^\"\'\']+)[\"\'\']');"
# wait, the original was: final RegExp regex = RegExp(r'var\s+csrf_token\s*=\s*["\']([^"\']+)["\']');
# Let's use string concatenation or double quotes for the raw string:
new_regex = """final RegExp regex = RegExp(r'var\\s+csrf_token\\s*=\\s*["\']([^"\']+)["\']');"""

# Let's just use a very safe string without tricky escapes
safe_regex = """final RegExp regex = RegExp('var\\\\s+csrf_token\\\\s*=\\\\s*["\\']([^"\']+)["\']');"""

# To be absolutely sure it compiles in dart:
super_safe = """final RegExp regex = RegExp(r'var\s+csrf_token\s*=\s*"([^"]+)"');"""
super_safe2 = """final RegExp regex = RegExp(r"var\s+csrf_token\s*=\s*'([^']+)'");"""

# Actually unraid source uses: var csrf_token = "XXXX";
# So let's just match double quotes to avoid quote escaping hell in Dart regex

replace_str = "final RegExp regex = RegExp(r'var\\s+csrf_token\\s*=\\s*\"([^\"]+)\"');"

code = re.sub(r"final RegExp regex = RegExp\(.*?\);", replace_str, code)

with open('lib/api/unraid_web_client.dart', 'w', encoding='utf-8') as f:
    f.write(code)
