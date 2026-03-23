import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# In main.dart:
# progress: serverProvider.memUsage / 100.0
# since serverProvider.memUsage is now a String ('API 切换中'), we cannot do math on it.
# Let's just pass `progress: 0.0` or parse it safely.

safe_mem = "progress: double.tryParse(serverProvider.memUsage.replaceAll('%', '')) != null ? (double.parse(serverProvider.memUsage.replaceAll('%', '')) / 100.0) : 0.0"
code = re.sub(r"progress:\s*serverProvider\.memUsage\s*/\s*100\.0", safe_mem, code)

# CPU usage is also used somewhere?
safe_cpu = "progress: double.tryParse(serverProvider.cpuUsage.replaceAll('%', '')) != null ? (double.parse(serverProvider.cpuUsage.replaceAll('%', '')) / 100.0) : 0.0"
code = re.sub(r"progress:\s*serverProvider\.cpuUsage\s*/\s*100\.0", safe_cpu, code)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

