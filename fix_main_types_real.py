import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Replace any instance of `serverProvider.memUsage / 100.0` or similar
code = re.sub(r"serverProvider\.memUsage\s*/\s*100\.0", "0.0", code)
code = re.sub(r"serverProvider\.cpuUsage\s*/\s*100\.0", "0.0", code)
code = re.sub(r"serverProvider\.gpuUsage\s*/\s*100\.0", "0.0", code)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

