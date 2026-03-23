import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Add vm_view import
if "import 'screens/vm_view.dart';" not in code:
    code = code.replace("import 'screens/login_screen.dart';", "import 'screens/login_screen.dart';\nimport 'screens/vm_view.dart';")

# Add to _pages
pages_old = """  final List<Widget> _pages = [
    const DashboardView(),
    const DockerView(),
    const MediaClientView(),
  ];"""

pages_new = """  final List<Widget> _pages = [
    const DashboardView(),
    const DockerView(),
    const VmView(),
    const MediaClientView(),
  ];"""

code = code.replace(pages_old, pages_new)

# Add to BottomNavigationBar items
nav_old = """          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: '大盘'),
          BottomNavigationBarItem(icon: Icon(Icons.view_in_ar), label: '容器'),
          BottomNavigationBarItem(icon: Icon(Icons.movie), label: '影视'),"""

nav_new = """          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: '大盘'),
          BottomNavigationBarItem(icon: Icon(Icons.view_in_ar), label: '容器'),
          BottomNavigationBarItem(icon: Icon(Icons.computer), label: '虚拟机'),
          BottomNavigationBarItem(icon: Icon(Icons.movie), label: '影视'),"""

code = code.replace(nav_old, nav_new)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

