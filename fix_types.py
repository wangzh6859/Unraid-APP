import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Error 1: getter 'isConnected' isn't defined for the class 'ServerProvider'.
# Error 2: The argument type 'int' can't be assigned to the parameter type 'String'. (cpuUsage and memUsage)

# In my earlier `server_provider.dart` rewrite to support Docker, I removed `isConnected` and changed cpuUsage/memUsage from String to int!
# Let's add `isConnected` back to ServerProvider and change int usages to string in main.dart.

with open('lib/providers/server_provider.dart', 'r', encoding='utf-8') as f:
    server_code = f.read()

if "bool isConnected" not in server_code:
    server_code = server_code.replace("bool isLoading = false;", "bool isLoading = false;\n  bool get isConnected => errorMsg.isEmpty && cpuModel != '未知 CPU';")
    with open('lib/providers/server_provider.dart', 'w', encoding='utf-8') as f:
        f.write(server_code)

# In main.dart, change _buildSquareCard(..., serverProvider.cpuUsage, ...)
# cpuUsage is now int, but _buildSquareCard expects a String.
code = re.sub(r"_buildSquareCard\(context, 'CPU', serverProvider\.cpuUsage, '(.*?)', Icons\.memory, Colors\.blue\)",
              r"_buildSquareCard(context, 'CPU', '${serverProvider.cpuUsage}%', '\1', Icons.memory, Colors.blue)", code)

code = re.sub(r"_buildWideCard\(context, '内存使用率', serverProvider\.memUsage, '(.*?)', Icons\.memory_sharp, Colors\.purple, progress: 0.45\)",
              r"_buildWideCard(context, '内存使用率', '${serverProvider.memUsage}%', '\1', Icons.memory_sharp, Colors.purple, progress: serverProvider.memUsage / 100.0)", code)


with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

