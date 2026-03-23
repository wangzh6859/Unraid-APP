import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# 1. Remove the custom Docker icons, fallback to standard icon, but use color to distinguish running vs not running.
# Let's remove `_getDockerIcon` function and just use Icons.view_in_ar_rounded or Icons.stop_circle for everything.
old_icon_call = "Icon(\n                  _getDockerIcon(name),\n                  color: isRunning ? Colors.green : Colors.grey,\n                ),"
new_icon_call = "Icon(\n                  isRunning ? Icons.view_in_ar_rounded : Icons.stop_circle_outlined,\n                  color: isRunning ? Colors.green : Colors.grey,\n                ),"
code = code.replace(old_icon_call, new_icon_call)

# 2. Add Docker Compose placeholder view. We'll add a TabBar to DockerView.
# Oh, that requires rewriting the DockerView scaffold.

# Instead of rewriting the whole thing, let's create a new DockerMainView which has tabs for Containers and Compose.

docker_main_view = """
class DockerMainView extends StatelessWidget {
  const DockerMainView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Docker 控制台', style: TextStyle(fontWeight: FontWeight.bold)),
          bottom: const TabBar(
            tabs: [
              Tab(text: '容器列表'),
              Tab(text: 'Compose'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            DockerView(),
            ComposeView(),
          ],
        ),
      ),
    );
  }
}

class ComposeView extends StatelessWidget {
  const ComposeView({super.key});
  
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Docker Compose 管理功能正在开发中...', style: TextStyle(fontSize: 16, color: Colors.grey)),
    );
  }
}
"""

# We need to change navigation in DashboardView to route to DockerMainView instead of DockerView.
code = code.replace("Navigator.push(context, MaterialPageRoute(builder: (_) => const DockerView()));", "Navigator.push(context, MaterialPageRoute(builder: (_) => const DockerMainView()));")

# And we remove the AppBar from DockerView since it's now inside a TabBarView!
# Wait, DockerView has its own AppBar with the sort button. 
# We should keep it as a standalone widget, but return it without Scaffold's AppBar, OR keep it as Scaffold and just push DockerMainView.
# If DockerView is a child of TabBarView, it shouldn't have its own AppBar.
# Let's just move the sort and refresh buttons to DockerMainView! No, that's complex because of state.
# EASIER APPROACH: Add a "Docker Compose" tab in the bottom navigation? No, that's too prominent.
# Just add a "Compose" button to the DockerView AppBar!

old_appbar = """      appBar: AppBar(
        title: const Text('Docker 控制台', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          PopupMenuButton<String>("""

new_appbar = """      appBar: AppBar(
        title: const Text('Docker 控制台', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_tree),
            tooltip: 'Docker Compose',
            onPressed: () {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Docker Compose 解析器正在开发中...')));
            },
          ),
          PopupMenuButton<String>("""

code = code.replace(old_appbar, new_appbar)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

