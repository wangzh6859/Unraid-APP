import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Import vm_view
if "import 'screens/vm_view.dart';" not in code:
    code = code.replace("import 'screens/login_screen.dart';", "import 'screens/login_screen.dart';\nimport 'screens/vm_view.dart';")

# Replace _pages
pages_old = """  final List<Widget> _pages = [
    const DashboardView(),
    const FileBrowserView(),
    const MediaClientView(), // 全新的 Emby 客户端视图
    const SettingsView(),
  ];"""

pages_new = """  final List<Widget> _pages = [
    const DashboardView(),
    const VmView(),
    const MediaClientView(), // 全新的 Emby 客户端视图
    const SettingsView(),
  ];"""

code = code.replace(pages_old, pages_new)

# Replace destinations
dest_old = """        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard, color: Color(0xFFFF5722)), label: '首页'),
          NavigationDestination(icon: Icon(Icons.folder_outlined), selectedIcon: Icon(Icons.folder, color: Color(0xFFFF5722)), label: '文件'),
          NavigationDestination(icon: Icon(Icons.play_circle_outline), selectedIcon: Icon(Icons.play_circle_fill, color: Color(0xFFFF5722)), label: '影音'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings, color: Color(0xFFFF5722)), label: '设置'),
        ],"""

dest_new = """        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard, color: Color(0xFFFF5722)), label: '首页'),
          NavigationDestination(icon: Icon(Icons.computer_outlined), selectedIcon: Icon(Icons.computer, color: Color(0xFFFF5722)), label: '虚拟机'),
          NavigationDestination(icon: Icon(Icons.play_circle_outline), selectedIcon: Icon(Icons.play_circle_fill, color: Color(0xFFFF5722)), label: '影音'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings, color: Color(0xFFFF5722)), label: '设置'),
        ],"""

code = code.replace(dest_old, dest_new)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

