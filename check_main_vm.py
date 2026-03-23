with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

if "class VmView extends" in code:
    print("YES! VmView class exists inside main.dart!")
    
    # We need to delete it from main.dart so it uses the one from screens/vm_view.dart
    import re
    # This regex is tricky, let's just find where it starts and ends
    start = code.find("class VmView extends")
    if start != -1:
        end = code.find("}", start)
        # Wait, build method has braces.
        # Let's just use regex to remove the whole class
        code = re.sub(r"class VmView extends.*?\}\n\}", "", code, flags=re.DOTALL)
        with open('lib/main.dart', 'w', encoding='utf-8') as f:
            f.write(code)

