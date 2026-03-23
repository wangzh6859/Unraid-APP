import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# We need to adapt the mapping because Portainer returns Docker Engine raw JSON
# name is in `Names` array like `["/nginx"]`
# Status string is in `State` (e.g. "running", "exited")
# ID is in `Id`
# Portainer doesn't return CPU/Mem usage directly in the container list API! (It requires stats API per container). 
# We'll just show 'Status' instead of cpu/mem if we don't have it.

# Find the itemBuilder mapping
mapping_old = """          final container = displayList[index];
          final name = container['name'] ?? container['Names'] ?? '未知容器';
          final status = container['Status'] ?? container['status'] ?? 'unknown';
          final cpu = container['cpu']?.containsKey('total') == true ? container['cpu']['total'] : 0.0;
          final mem = container['memory']?.containsKey('usage') == true 
              ? (container['memory']['usage'] / 1024 / 1024).toStringAsFixed(1) 
              : '0.0';"""

mapping_new = """          final container = displayList[index];
          
          // Handle both Glances and Portainer formats
          String name = '未知容器';
          if (container['Names'] != null && container['Names'] is List && container['Names'].isNotEmpty) {
             name = container['Names'][0].toString().replaceAll('/', ''); // Portainer format
          } else if (container['name'] != null) {
             name = container['name']; // Glances format
          } else if (container['Names'] is String) {
             name = container['Names'];
          }
          
          final String containerId = container['Id'] ?? container['id'] ?? '';
          final status = container['State'] ?? container['Status'] ?? container['status'] ?? 'unknown';
          final statusStr = status.toString().toLowerCase();
          final isRunning = statusStr.contains('running') || statusStr.contains('healthy') || statusStr.contains('up');
          
          // Portainer list doesn't return live CPU/Mem, so we display Image name or State if cpu/mem is missing
          final hasCpu = container['cpu'] != null;
          final cpu = container['cpu']?.containsKey('total') == true ? container['cpu']['total'] : 0.0;
          final mem = container['memory']?.containsKey('usage') == true 
              ? (container['memory']['usage'] / 1024 / 1024).toStringAsFixed(1) 
              : '0.0';
          
          final image = container['Image'] ?? '';"""

code = code.replace(mapping_old, mapping_new)

# Update the Subtitle to conditionally show CPU/MEM or Image
subtitle_old = """                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Row(
                                children: [
                                  Icon(Icons.memory, size: 14, color: Colors.blue.shade400),
                                  const SizedBox(width: 4),
                                  Text('${cpu.toStringAsFixed(1)}%'),
                                  const SizedBox(width: 16),
                                  Icon(Icons.storage, size: 14, color: Colors.orange.shade400),
                                  const SizedBox(width: 4),
                                  Text('${mem} MB'),
                                ],
                              ),
                            ),"""

subtitle_new = """                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: hasCpu ? Row(
                                children: [
                                  Icon(Icons.memory, size: 14, color: Colors.blue.shade400),
                                  const SizedBox(width: 4),
                                  Text('${cpu.toStringAsFixed(1)}%'),
                                  const SizedBox(width: 16),
                                  Icon(Icons.storage, size: 14, color: Colors.orange.shade400),
                                  const SizedBox(width: 4),
                                  Text('$mem MB'),
                                ],
                              ) : Row(
                                children: [
                                  Icon(Icons.layers, size: 14, color: Colors.grey.shade500),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text(image.toString(), overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade500, fontSize: 12))),
                                ],
                              ),
                            ),"""
                            
code = code.replace(subtitle_old, subtitle_new)

# Update PopupMenu onSelected to call provider action
action_old = """                onSelected: (value) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('已发送 $value 指令 (功能接入中...)')),
                  );
                },"""
action_new = """                onSelected: (value) async {
                  if (containerId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('容器ID为空，无法操作')));
                    return;
                  }
                  
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('正在发送 $value 指令...')));
                  bool success = await server.controlContainer(containerId, value);
                  if (success) {
                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('指令 $value 执行成功！', style: const TextStyle(color: Colors.green))));
                  } else {
                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('指令 $value 执行失败！', style: const TextStyle(color: Colors.red))));
                  }
                },"""

code = code.replace(action_old, action_new)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

