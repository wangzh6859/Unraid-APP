with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

if "const VmView()," in code:
    print("VmView is in _pages")
else:
    print("VmView is MISSING in _pages")

if "BottomNavigationBarItem(icon: Icon(Icons.computer), label: '虚拟机')," in code:
    print("VmView is in BottomNavigationBarItem")
else:
    print("VmView is MISSING in BottomNavigationBarItem")

