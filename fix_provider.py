import re

with open('lib/providers/server_provider.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# We need to update the unraid_client to query the actual usage and memory and update the provider
with open('lib/api/unraid_client.dart', 'r', encoding='utf-8') as f:
    api_code = f.read()

# According to typical Unraid GraphQL schema, usage data is usually under `state` or `system`
# Let's request both info and system/state if available, or just request a broad query so we can see the data structure if it fails.
new_query = """
          "query": "query { info { cpu { brand cores threads } } system { state { cpuLoad, memory { free, total } } } }"
"""
api_code = re.sub(r'"query": "query \{ info \{ os.*?\}', new_query.strip(), api_code)

with open('lib/api/unraid_client.dart', 'w', encoding='utf-8') as f:
    f.write(api_code)

# Now update the provider to parse the real CPU usage and Memory usage
new_refresh = """
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
          
          // CPU 占用率解析 (尝试从 system.state.cpuLoad 获取)
          if (resData['system'] != null && resData['system']['state'] != null) {
            var load = resData['system']['state']['cpuLoad'];
            if (load != null) {
               cpuUsage = '${load.toString()}%';
            }
            
            // 内存解析
            var mem = resData['system']['state']['memory'];
            if (mem != null) {
               double free = (mem['free'] ?? 0) / 1024 / 1024 / 1024; // 假设返回的是 bytes
               double total = (mem['total'] ?? 1) / 1024 / 1024 / 1024;
               if (total > 0) {
                 double usage = ((total - free) / total) * 100;
                 memUsage = '${usage.toStringAsFixed(1)}%';
               }
            }
          } else {
             // 如果没拿到 system.state，降级显示核心数以防报错
             final info = resData['info'];
             if (info != null && info['cpu'] != null) {
                cpuUsage = info['cpu']['cores'].toString() + ' 核';
                memUsage = '未知';
             }
          }
        } catch (e) {
          errorMsg = '数据解析异常，数据结构不匹配';
        }
      }
    } else {
      isConnected = false;
      errorMsg = "未配置IP或连接超时";
    }

    isLoading = false;
    notifyListeners();
  }
"""
code = re.sub(r"Future<void> refreshData\(\) async \{.*?\n  \}", new_refresh.strip(), code, flags=re.DOTALL)

with open('lib/providers/server_provider.dart', 'w', encoding='utf-8') as f:
    f.write(code)

