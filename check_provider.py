with open('lib/providers/server_provider.dart', 'r', encoding='utf-8') as f:
    code = f.read()

code = code.replace("String rawVmResponse = '';", "String rawVmResponse = '正在执行抓取...';")

with open('lib/providers/server_provider.dart', 'w', encoding='utf-8') as f:
    f.write(code)
