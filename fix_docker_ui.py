with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Replace the empty UI to show `rawDockerResponse`
old_empty = "return const Center(child: Text('未发现运行中的 Docker 容器\\n请确认 Glances 已启用 Docker 监控插件', textAlign: TextAlign.center));"
new_empty = "return SingleChildScrollView(padding: const EdgeInsets.all(24), child: SelectableText('监控模块返回信息：\\n\\n${server.rawDockerResponse}', style: TextStyle(color: Colors.grey.shade600)));"

code = code.replace(old_empty, new_empty)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

