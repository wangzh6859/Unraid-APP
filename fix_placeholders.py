import os
import re

for root, dirs, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            path = os.path.join(root, file)
            with open(path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            if "虚拟机管理功能开发中" in content:
                print(f"Replacing in {path}")
                # We will replace the whole text widget or scaffold body with our text
                content = content.replace("Text('虚拟机管理功能开发中...')", "Text(Provider.of<ServerProvider>(context).rawVmResponse.isEmpty ? '等待数据返回中...' : Provider.of<ServerProvider>(context).rawVmResponse)")
                content = content.replace("const Center(", "Center(")
                
                # Make sure provider is imported
                if "import '../providers/server_provider.dart';" not in content and "import 'package:provider/provider.dart';" not in content:
                    content = "import 'package:provider/provider.dart';\nimport '../providers/server_provider.dart';\n" + content
                
                with open(path, 'w', encoding='utf-8') as f:
                    f.write(content)

