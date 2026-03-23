with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

if "runApp(const MainNavigationPage())" in code:
    print("WARNING: runApp was changed wrongly!")
    code = code.replace("runApp(const MainNavigationPage())", "runApp(const UnraidApp())")
    
    with open('lib/main.dart', 'w', encoding='utf-8') as f:
        f.write(code)
    print("Fixed runApp.")
