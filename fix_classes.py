import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# I see MainNavigationPage is the one! Wait, UnraidApp is the root widget.
# Looking at the code: `home: !_isReady ? ... : (_hasLogin ? const UnraidApp() : const LoginScreen())`
# But UnraidApp is calling ITSELF!
# Let's see what `home:` is set to.
print("Home line:", re.search(r"home:.*", code).group(0))

# We need to change the constructor call `const UnraidApp()` inside `UnraidApp` to `const MainNavigationPage()` 
# which is the one that has BottomNavigationBar!

code = code.replace("const UnraidApp()", "const MainNavigationPage()")

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

with open('lib/screens/login_screen.dart', 'r', encoding='utf-8') as f:
    login_code = f.read()

# Fix LoginScreen routing to MainNavigationPage
login_code = login_code.replace("const UnraidApp()", "const MainNavigationPage()")
login_code = login_code.replace("const MainScreen()", "const MainNavigationPage()") # Just in case

with open('lib/screens/login_screen.dart', 'w', encoding='utf-8') as f:
    f.write(login_code)

