import sys

with open('lib/providers/server_provider.dart', 'r', encoding='utf-8') as f:
    prov = f.read()

with open('lib/screens/vm_view.dart', 'r', encoding='utf-8') as f:
    vmv = f.read()

print("server_provider contains 开发中?", "开发中" in prov)
print("vm_view contains 开发中?", "开发中" in vmv)

