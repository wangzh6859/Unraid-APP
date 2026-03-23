import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Fix icon helper to handle null name
icon_helper_old = """IconData _getDockerIcon(String name) {
    name = name.toLowerCase();"""
icon_helper_new = """IconData _getDockerIcon(String? name) {
    if (name == null) return Icons.view_in_ar_rounded;
    name = name.toLowerCase();"""

code = code.replace(icon_helper_old, icon_helper_new)


# Now add sorting options. I will replace the AppBar actions of DockerView.
old_app_bar = """      appBar: AppBar(
        title: const Text('Docker 控制台', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => server.fetchStats(),
          ),
        ],
      ),"""

new_app_bar = """      appBar: AppBar(
        title: const Text('Docker 控制台', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: '排序方式',
            onSelected: (value) {
              setState(() {
                _sortMode = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'status', child: Text('按运行状态')),
              const PopupMenuItem(value: 'name', child: Text('按名称字母')),
              const PopupMenuItem(value: 'cpu', child: Text('按 CPU 占用')),
              const PopupMenuItem(value: 'mem', child: Text('按 内存占用')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => server.fetchStats(),
          ),
        ],
      ),"""

code = code.replace(old_app_bar, new_app_bar)

# Add _sortMode variable and sorting logic
state_class_start = """class _DockerViewState extends State<DockerView> {"""
state_class_new = """class _DockerViewState extends State<DockerView> {
  String _sortMode = 'status'; // default sort by status"""

code = code.replace(state_class_start, state_class_new)

# Find the start of the list builder to inject sorting logic
list_builder_old = """      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: server.dockerContainers.length,"""

list_builder_new = """      List<dynamic> displayList = List.from(server.dockerContainers);
      
      displayList.sort((a, b) {
        if (_sortMode == 'name') {
           String nameA = a['name'] ?? a['Names'] ?? '';
           String nameB = b['name'] ?? b['Names'] ?? '';
           return nameA.toLowerCase().compareTo(nameB.toLowerCase());
        } else if (_sortMode == 'cpu') {
           double cpuA = a['cpu']?.containsKey('total') == true ? (a['cpu']['total'] as num).toDouble() : 0.0;
           double cpuB = b['cpu']?.containsKey('total') == true ? (b['cpu']['total'] as num).toDouble() : 0.0;
           return cpuB.compareTo(cpuA); // descending
        } else if (_sortMode == 'mem') {
           double memA = a['memory']?.containsKey('usage') == true ? (a['memory']['usage'] as num).toDouble() : 0.0;
           double memB = b['memory']?.containsKey('usage') == true ? (b['memory']['usage'] as num).toDouble() : 0.0;
           return memB.compareTo(memA); // descending
        } else {
           // Default status sorting: Running first
           String statusA = a['status']?.toString().toLowerCase() ?? a['Status']?.toString().toLowerCase() ?? '';
           String statusB = b['status']?.toString().toLowerCase() ?? b['Status']?.toString().toLowerCase() ?? '';
           bool aUp = statusA.contains('running') || statusA.contains('healthy') || statusA.contains('up');
           bool bUp = statusB.contains('running') || statusB.contains('healthy') || statusB.contains('up');
           if (aUp && !bUp) return -1;
           if (bUp && !aUp) return 1;
           return 0;
        }
      });

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: displayList.length,"""

code = code.replace(list_builder_old, list_builder_new)

# Also fix the usage of `server.dockerContainers[index]` to `displayList[index]` inside the itemBuilder
item_builder_old = """        itemBuilder: (context, index) {
          final container = server.dockerContainers[index];"""
item_builder_new = """        itemBuilder: (context, index) {
          final container = displayList[index];"""

code = code.replace(item_builder_old, item_builder_new)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

