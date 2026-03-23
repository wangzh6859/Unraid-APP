with open('lib/api/unraid_web_client.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# I need to find whatever the current line is. Let's just rewrite the whole get dashboard logic.
import re
new_code = re.sub(r"final RegExp regex = RegExp\(.*?\);", "final RegExp regex = RegExp(r'var\\\\s+csrf_token\\\\s*=\\\\s*\"([^\"]+)\"');", code)

with open('lib/api/unraid_web_client.dart', 'w', encoding='utf-8') as f:
    f.write(new_code)
