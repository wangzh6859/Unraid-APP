import re

with open('lib/api/unraid_client.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Fallback to the simplest guaranteed query.
new_query = r'"query": "query { info { cpu { brand cores threads } os { uptime } } }"'
code = re.sub(r'"query": "query \{ info.*?\} "', new_query, code)

with open('lib/api/unraid_client.dart', 'w', encoding='utf-8') as f:
    f.write(code)

with open('lib/providers/server_provider.dart', 'r', encoding='utf-8') as f:
    prov_code = f.read()

# Make sure we use the CPU model!
# Also update the logic since we removed system.state to avoid 400
provider_refresh = """
  String cpuModel = 'Intel Core i5-13500 · 14 Cores'; // 默认

  Future<void> refreshData() async {
    isLoading = true;
    errorMsg = '';
    notifyListeners();

    final data = await _api.getServerStats();
    
    if (data != null) {
      if (data.containsKey('error')) {
        isConnected = false;
        errorMsg = data['error'];
      } else if (data.containsKey('errors')) {
        isConnected = false;
        errorMsg = 'GraphQL报错: ' + (data['errors'][0]['message'] ?? '未知错误');
      } else {
        isConnected = true;
        try {
          final resData = data['data'];
          final info = resData['info'];
          if (info != null && info['cpu'] != null) {
             cpuModel = '${info['cpu']['brand']}';
             cpuUsage = info['cpu']['cores'].toString() + '核'; // 暂时用核心数占位，等用 SSH 查
          }
        } catch (e) {
          errorMsg = '数据解析异常';
        }
      }
    } else {
      isConnected = false;
      errorMsg = "网络请求失败";
    }

    // 尝试通过 SSH 获取 GPU 和真实的 CPU/内存 数据
    try {
      final prefs = await SharedPreferences.getInstance();
      final host = prefs.getString('ssh_host') ?? '';
      final port = prefs.getInt('ssh_port') ?? 22;
      final user = prefs.getString('ssh_user') ?? '';
      final pass = prefs.getString('ssh_pass') ?? '';

      if (host.isNotEmpty && user.isNotEmpty && pass.isNotEmpty) {
        await _ssh.connect(host, port, user, pass);
        
        // 抓取 GPU
        final nvidiaSmi = await _ssh.executeCommand("nvidia-smi --query-gpu=utilization.gpu,temperature.gpu --format=csv,noheader,nounits");
        if (nvidiaSmi.isNotEmpty && !nvidiaSmi.contains("Error") && !nvidiaSmi.contains("command not found")) {
           final parts = nvidiaSmi.split(',');
           if (parts.length >= 2) {
             gpuUsage = "${parts[0].trim()}%";
             gpuTemp = "${parts[1].trim()}°C";
           }
        } else {
           gpuUsage = "核显/待机";
        }

        // 既然 GraphQL API 老是变，直接用 SSH 抓取真实的 CPU 和内存负载！
        // CPU 占用率通过 top 计算
        final topCpu = await _ssh.executeCommand("top -bn1 | grep 'Cpu(s)' | awk '{print $2 + $4}'");
        if (topCpu.isNotEmpty) {
           cpuUsage = "${topCpu.trim()}%";
        }

        // 内存占用率通过 free 计算
        final freeMem = await _ssh.executeCommand("free | grep Mem | awk '{print $3/$2 * 100.0}'");
        if (freeMem.isNotEmpty) {
           double memPct = double.tryParse(freeMem.trim()) ?? 0;
           memUsage = "${memPct.toStringAsFixed(1)}%";
        }

        _ssh.disconnect();
      }
    } catch (e) {
      print('SSH fetch failed: $e');
    }
    
    isLoading = false;
    notifyListeners();
  }
"""
prov_code = re.sub(r"Future<void> refreshData\(\) async \{.*?\n  \}", provider_refresh.strip(), prov_code, flags=re.DOTALL)
# Also need to make sure cpuModel property exists in class
if "String cpuModel =" not in prov_code:
    prov_code = prov_code.replace("String errorMsg = '';", "String errorMsg = '';\n  String cpuModel = 'Intel Core i5-13500 · 14 Cores';")

with open('lib/providers/server_provider.dart', 'w', encoding='utf-8') as f:
    f.write(prov_code)

