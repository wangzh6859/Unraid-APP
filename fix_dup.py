import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Error: 'statusStr' is already declared in this scope.
# The error means I defined `final statusStr = ...` and `final isRunning = ...` twice inside the ListView.builder.
# Let's remove the second declaration.

# First block:
# final statusStr = status.toString().toLowerCase();
# final isRunning = statusStr.contains('running') || statusStr.contains('healthy') || statusStr.contains('up');

code = code.replace("""          final statusStr = status.toString().toLowerCase();
          final isRunning = statusStr.contains('running') || statusStr.contains('healthy') || statusStr.contains('up');
          
          // Portainer list doesn't return live CPU/Mem""", """          // Portainer list doesn't return live CPU/Mem""")

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

