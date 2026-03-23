import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Find the name of the main widget (the one with BottomNavigationBar)
# Looking for `class ... extends StatefulWidget` that contains `BottomNavigationBar`
match = re.search(r"class (\w+) extends StatefulWidget \{[^\}]*?\}[\s\S]*?class _\1State extends State<\1> \{[\s\S]*?BottomNavigationBar", code)
if match:
    main_widget_name = match.group(1)
    print("Found main widget name:", main_widget_name)
    code = code.replace("const MainScreen()", f"const {main_widget_name}()")
else:
    print("Could not find main widget, searching for the first StatefulWidget after MyApp")
    # Usually it's `MainScreen` in some templates, but in this one it might be `MainView` or `DashboardView` 
    # The bottom nav is in a class. Let's find any class with `_currentIndex`.
    match2 = re.search(r"class (\w+) extends StatefulWidget \{[^\}]*?\}[\s\S]*?int _currentIndex", code)
    if match2:
        main_widget_name = match2.group(1)
        print("Found main widget name via _currentIndex:", main_widget_name)
        code = code.replace("const MainScreen()", f"const {main_widget_name}()")

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

with open('lib/screens/login_screen.dart', 'r', encoding='utf-8') as f:
    login_code = f.read()
    if match or match2:
        login_code = login_code.replace("const MainScreen()", f"const {main_widget_name}()")
        # Also need to update user requirements: allow changing emby address in the UI instead of just deriving it.
        # Oh, the user explicitly asked: "影视界面保留切换用户的选项，可以在影视界面自主选择登录的账户并进行更改"
with open('lib/screens/login_screen.dart', 'w', encoding='utf-8') as f:
    f.write(login_code)

