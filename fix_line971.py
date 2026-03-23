import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# The error: `未发现运行中的 Docker 容器\n请确认 Glances 已启用 Docker 监控插件', textAlign: TextAlign.center))`
# I used `\n` inside the string, but wait, look at the error log:
# lib/main.dart:970:40: Error: Too many positional arguments: 1 allowed, but 7 found.
#         return const Center(child: Text('未发现运行中的 Docker 容器
# Ah! I used a literal newline instead of \n!
# Let's fix that.

code = code.replace("未发现运行中的 Docker 容器\n请确认 Glances 已启用 Docker 监控插件", "未发现运行中的 Docker 容器\\n请确认 Glances 已启用 Docker 监控插件")

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

