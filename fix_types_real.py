with open('lib/providers/server_provider.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Make sure gpuUsage is actually there
if 'String gpuUsage' not in code:
    code = code.replace("String uptime = '未知';", "String uptime = '未知';\n  String gpuUsage = 'N/A';\n  String gpuTemp = 'N/A';")

with open('lib/providers/server_provider.dart', 'w', encoding='utf-8') as f:
    f.write(code)

