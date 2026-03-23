with open('lib/providers/server_provider.dart', 'r', encoding='utf-8') as f:
    code = f.read()

code = code.replace("rawVmResponse = '原生页面抓取成功，正则解析模块开发中...';", "rawVmResponse = vmResult['data'].toString();")

with open('lib/providers/server_provider.dart', 'w', encoding='utf-8') as f:
    f.write(code)

