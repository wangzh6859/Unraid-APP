with open('lib/api/unraid_client.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# The regex replacement duplicated some text:
# "query": "query { info { cpu { brand cores threads } } system { state { cpuLoad, memory { free, total } } } }" cpu { brand cores threads } } }"

import re
pattern = r'"query": "query.*?" cpu.*?"'
replacement = r'"query": "query { info { cpu { brand cores threads } } system { state { cpuLoad, memory { free, total } } } }"'
code = re.sub(pattern, replacement, code)

with open('lib/api/unraid_client.dart', 'w', encoding='utf-8') as f:
    f.write(code)
