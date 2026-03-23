with open('lib/api/portainer_client.dart', 'r', encoding='utf-8') as f:
    code = f.read()

code = code.replace("AppConfig.username", "AppConfig.activePortainerUser")
code = code.replace("AppConfig.password", "AppConfig.activePortainerPass")

with open('lib/api/portainer_client.dart', 'w', encoding='utf-8') as f:
    f.write(code)
