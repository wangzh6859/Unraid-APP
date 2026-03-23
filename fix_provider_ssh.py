import re

with open('lib/providers/server_provider.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Add SSH fields and the service
new_imports = """import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/unraid_client.dart';
import '../api/ssh_client.dart';
"""

code = code.replace("import 'package:flutter/material.dart';\nimport '../api/unraid_client.dart';", new_imports)

# Add properties
props = """
  final UnraidClient _api = UnraidClient();
  final SSHService _ssh = SSHService();
  
  bool isLoading = false;
  bool isConnected = false;
  String cpuUsage = '0%';
  String memUsage = '0%';
  String gpuUsage = '未知';
  String gpuTemp = '--°C';
  String errorMsg = '';
"""
code = re.sub(r"final UnraidClient _api = UnraidClient\(\);.*?String errorMsg = '';", props.strip(), code, flags=re.DOTALL)

# Add SSH fetching into refreshData
ssh_fetch = """
    // 尝试通过 SSH 获取 GPU 数据
    try {
      final prefs = await SharedPreferences.getInstance();
      final host = prefs.getString('ssh_host') ?? '';
      final port = prefs.getInt('ssh_port') ?? 22;
      final user = prefs.getString('ssh_user') ?? '';
      final pass = prefs.getString('ssh_pass') ?? '';

      if (host.isNotEmpty && user.isNotEmpty && pass.isNotEmpty) {
        await _ssh.connect(host, port, user, pass);
        // 如果是 Nvidia 显卡，使用 nvidia-smi 提取使用率和温度
        final nvidiaSmi = await _ssh.executeCommand("nvidia-smi --query-gpu=utilization.gpu,temperature.gpu --format=csv,noheader,nounits");
        if (nvidiaSmi.isNotEmpty && !nvidiaSmi.contains("Error") && !nvidiaSmi.contains("command not found")) {
           final parts = nvidiaSmi.split(',');
           if (parts.length >= 2) {
             gpuUsage = "${parts[0].trim()}%";
             gpuTemp = "${parts[1].trim()}°C";
           }
        } else {
          // 如果是 Intel 核显，通常可以使用 intel_gpu_top (但解析较复杂，暂以未知处理或使用自定义命令)
          gpuUsage = "核显";
        }
        _ssh.disconnect();
      }
    } catch (e) {
      print('SSH fetch failed: $e');
    }
    
    isLoading = false;
"""
code = code.replace("isLoading = false;\n    notifyListeners();", ssh_fetch + "\n    notifyListeners();")

with open('lib/providers/server_provider.dart', 'w', encoding='utf-8') as f:
    f.write(code)

