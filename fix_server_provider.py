import re

with open('lib/providers/server_provider.dart', 'r', encoding='utf-8') as f:
    prov_code = f.read()

# We need to add a Timer to refresh every 3 seconds.
if "import 'dart:async';" not in prov_code:
    prov_code = "import 'dart:async';\n" + prov_code

provider_class_pattern = r"class ServerProvider extends ChangeNotifier \{"

provider_vars = """class ServerProvider extends ChangeNotifier {
  final GlancesClient _api = GlancesClient();
  Timer? _timer;
  
  ServerProvider() {
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    refreshData(isBackground: false);
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (AppConfig.baseDomain.isNotEmpty) {
        refreshData(isBackground: true);
      }
    });
  }"""

prov_code = re.sub(provider_class_pattern, provider_vars, prov_code)
prov_code = prov_code.replace("Future<void> refreshData() async {", "Future<void> refreshData({bool isBackground = false}) async {")
prov_code = prov_code.replace("isLoading = true;", "if (!isBackground) isLoading = true;")
prov_code = prov_code.replace("AppConfig.baseDomain", "AppConfig.baseDomain") # ensure AppConfig is imported

if "import '../utils/app_config.dart';" not in prov_code:
    prov_code = prov_code.replace("import '../api/glances_client.dart';", "import '../api/glances_client.dart';\nimport '../utils/app_config.dart';")

# Fix CPU / GPU temperature and model parsing from Glances
# Glances cpu model is usually not in standard api/3/all 'cpu' block. It's in 'quicklook' or 'sensors'.
# 'quicklook' has cpu_name. 'sensors' has temperatures.
parsing_block = """
          isConnected = true;
          try {
            final data = result['data'];
            
            // 尝试获取真实的 CPU 型号
            if (data['quicklook'] != null && data['quicklook']['cpu_name'] != null) {
               cpuModel = '${data['system']['os_name']} · ${data['quicklook']['cpu_name']}';
            } else if (data['system'] != null) {
               cpuModel = '${data['system']['os_name']} · ${data['system']['hostname']}';
            }

            if (data['cpu'] != null) {
               cpuUsage = '${data['cpu']['total'].toStringAsFixed(1)}%';
            }
            if (data['mem'] != null) {
               memUsage = '${data['mem']['percent'].toStringAsFixed(1)}%';
            }
            
            // 尝试获取真实的 GPU 数据及温度
            if (data['gpu'] != null && data['gpu'].isNotEmpty) {
               final mainGpu = data['gpu'][0];
               gpuUsage = '${mainGpu['proc'] ?? 0}%';
               gpuTemp = '${mainGpu['temperature'] ?? 'N/A'}°C';
            } else {
               gpuUsage = '核显/未检测';
               gpuTemp = '--';
            }

            // 如果 sensors 里有温度，尝试提取 CPU 温度追加到 CPU 占用率旁，或者替换
            // 暂时不改 UI 结构，将它留存
            
          } catch (e) {
            errorMsg = '数据解析异常';
          }
"""
prov_code = re.sub(r"isConnected = true;\s*try \{.*?\} catch \(e\) \{\s*errorMsg = '数据解析异常';\s*\}", parsing_block.strip(), prov_code, flags=re.DOTALL)

with open('lib/providers/server_provider.dart', 'w', encoding='utf-8') as f:
    f.write(prov_code)

