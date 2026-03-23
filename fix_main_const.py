import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Fix the const error: Text(serverProvider.cpuModel, style: const TextStyle...
# Actually the error is that Text is inside a const Column or const Row!
# Let's find it.
# Column(
#   crossAxisAlignment: CrossAxisAlignment.start,
#   mainAxisSize: MainAxisSize.min,
#   children: [
#     const Text('主服务器', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2, fontSize: 22)),
#     Text(serverProvider.cpuModel, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.normal)),
#   ],
# ),
# But if Column has `const` modifier, `Text(serverProvider...` will fail.
code = code.replace("const Column(\n                crossAxisAlignment", "Column(\n                crossAxisAlignment")

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

with open('lib/providers/server_provider.dart', 'r', encoding='utf-8') as f:
    prov_code = f.read()

# The awk script issue still persists? Ah! Dart uses \ to escape, but I wrote \\$ in python string, so it became \$ which dart interprets correctly. 
# Wait, if I look at the logs: "Error: A '$' has special meaning inside a string..."
# I need to make the string a RAW string in Dart: r"top -bn1 | grep 'Cpu(s)' | awk '{print $2 + $4}'"
prov_code = prov_code.replace('executeCommand("top -bn1 | grep \'Cpu(s)\' | awk \'{print \\$2 + \\$4}\'")', "executeCommand(r\"top -bn1 | grep 'Cpu(s)' | awk '{print $2 + $4}'\")")
prov_code = prov_code.replace('executeCommand("free | grep Mem | awk \'{print \\$3/\\$2 * 100.0}\'")', "executeCommand(r\"free | grep Mem | awk '{print $3/$2 * 100.0}'\")")

with open('lib/providers/server_provider.dart', 'w', encoding='utf-8') as f:
    f.write(prov_code)
