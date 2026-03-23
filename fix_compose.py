import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Remove the Compose icon from DockerView AppBar
compose_icon = """          IconButton(
            icon: const Icon(Icons.account_tree),
            tooltip: 'Docker Compose',
            onPressed: () {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Docker Compose 解析器正在开发中...')));
            },
          ),"""

code = code.replace(compose_icon, "")

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)
