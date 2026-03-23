import re

with open('lib/providers/server_provider.dart', 'r', encoding='utf-8') as f:
    server_code = f.read()

# Glances v4 doesn't use `docker` key, it uses `containers` directly and it's a list!
# Let's rewrite the parsing logic.

parse_docker = """    // Parse Docker Containers
    if (data['containers'] != null) {
       rawDockerResponse = 'Found containers array';
       if (data['containers'] is List) {
         dockerContainers = data['containers'];
         dockerContainers.sort((a, b) {
           String statusA = a['status']?.toString().toLowerCase() ?? '';
           String statusB = b['status']?.toString().toLowerCase() ?? '';
           // Usually running, healthy, up, etc.
           bool isRunningA = statusA.contains('running') || statusA.contains('healthy') || statusA.contains('up');
           bool isRunningB = statusB.contains('running') || statusB.contains('healthy') || statusB.contains('up');
           if (isRunningA && !isRunningB) return -1;
           if (isRunningB && !isRunningA) return 1;
           return 0;
         });
       }
    } else if (data['docker'] != null) {
       rawDockerResponse = 'Found docker object';
       if (data['docker']['containers'] != null) {
         dockerContainers = data['docker']['containers'];
         dockerContainers.sort((a, b) {
           String statusA = a['Status'] ?? a['status'] ?? '';
           String statusB = b['Status'] ?? b['status'] ?? '';
           if (statusA.toLowerCase() == 'running' && statusB.toLowerCase() != 'running') return -1;
           if (statusB.toLowerCase() == 'running' && statusA.toLowerCase() != 'running') return 1;
           return 0;
         });
       } else if (data['docker'] is List) {
         dockerContainers = data['docker'];
       }
    } else {
       dockerContainers = [];
       rawDockerResponse = '未在响应中找到 containers 节点。您可能需要开启 Glances 容器插件。';
    }"""

server_code = re.sub(r"// Parse Docker Containers.*?\} else \{.*?\}", parse_docker, server_code, flags=re.DOTALL)

with open('lib/providers/server_provider.dart', 'w', encoding='utf-8') as f:
    f.write(server_code)


with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Make sure isRunning detection covers 'healthy' and 'up' which Glances v4 uses!
code = code.replace("final isRunning = status.toString().toLowerCase() == 'running';", 
                    "final statusStr = status.toString().toLowerCase();\n          final isRunning = statusStr.contains('running') || statusStr.contains('healthy') || statusStr.contains('up');")

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

