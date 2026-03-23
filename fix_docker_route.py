import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Error: Couldn't find constructor 'DockerMainView'
# I reverted DockerMainView approach in the previous Python script when I realized I can just put a Compose button on the DockerView Appbar!
# But my Python script STILL changed the Dashboard routing to `DockerMainView`!
# Let's fix Dashboard routing back to `DockerView`.

code = code.replace("Navigator.push(context, MaterialPageRoute(builder: (_) => const DockerMainView()));", "Navigator.push(context, MaterialPageRoute(builder: (_) => const DockerView()));")

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

