import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Import vm_view
if "import 'screens/vm_view.dart';" not in code:
    code = code.replace("import 'screens/login_screen.dart';", "import 'screens/login_screen.dart';\nimport 'screens/vm_view.dart';")

# Add to _pages
code = code.replace("""  final List<Widget> _pages = [
    const DashboardView(),
    const DockerView(),
    const MediaClientView(),
  ];""", """  final List<Widget> _pages = [
    const DashboardView(),
    const DockerView(),
    const VmView(),
    const MediaClientView(),
  ];""")

# Add to BottomNavigationBar items
code = code.replace("""          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: '大盘'),
          BottomNavigationBarItem(icon: Icon(Icons.view_in_ar), label: '容器'),
          BottomNavigationBarItem(icon: Icon(Icons.movie), label: '影视'),""", """          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: '大盘'),
          BottomNavigationBarItem(icon: Icon(Icons.view_in_ar), label: '容器'),
          BottomNavigationBarItem(icon: Icon(Icons.computer), label: '虚拟机'),
          BottomNavigationBarItem(icon: Icon(Icons.movie), label: '影视'),""")

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

