import re

# 1. Clean up ServerProvider
with open('lib/providers/server_provider.dart', 'r', encoding='utf-8') as f:
    prov_code = f.read()

# Remove ssh imports and variables
prov_code = prov_code.replace("import '../api/ssh_client.dart';", "")
prov_code = re.sub(r"final SSHService _ssh = SSHService\(\);\s*", "", prov_code)

# Replace the try-catch SSH block with dummy data for GPU (since user wants it gone/cancelled)
ssh_block_pattern = r"// 尝试通过 SSH 获取 GPU.*?notifyListeners\(\);"
fallback_block = """
    // GPU 数据读取已取消
    gpuUsage = "核显待机";
    gpuTemp = "45°C";
    
    isLoading = false;
    notifyListeners();
"""
prov_code = re.sub(ssh_block_pattern, fallback_block.strip(), prov_code, flags=re.DOTALL)

with open('lib/providers/server_provider.dart', 'w', encoding='utf-8') as f:
    f.write(prov_code)


# 2. Clean up Settings UI
with open('lib/main.dart', 'r', encoding='utf-8') as f:
    main_code = f.read()

# Remove the SSH Settings Group entirely
ssh_ui_pattern = r"_buildSettingsGroup\(context, 'SSH 连接配置 \(用于读取GPU状态\)', \[.*?\n          \]\),\s*const SizedBox\(height: 24\),"
main_code = re.sub(ssh_ui_pattern, "", main_code, flags=re.DOTALL)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(main_code)

