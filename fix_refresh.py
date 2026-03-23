import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Error: The method 'refreshData' isn't defined for the class 'ServerProvider'.
# Because I renamed it to `fetchStats`!
code = code.replace("serverProvider.refreshData()", "serverProvider.fetchStats()")

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

