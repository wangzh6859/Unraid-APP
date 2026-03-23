import 'dart:async';
import 'package:flutter/material.dart';
import '../api/glances_client.dart';
import '../utils/app_config.dart';

class ServerProvider extends ChangeNotifier {
  
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
  }
  final GlancesClient _api = GlancesClient();
  
  bool isConnected = false;
  bool isLoading = false;
  String errorMsg = '';
  
  String cpuModel = 'Glances Node';
  String cpuUsage = '0%';
  String memUsage = '0%';
  String gpuUsage = '核显/待机';
  String gpuTemp = '45°C';

  Future<void> refreshData({bool isBackground = false}) async {
    if (!isBackground) isLoading = true;
    errorMsg = '';
    notifyListeners();

    final result = await _api.getServerStats();
    if (result != null) {
       if (result.containsKey('error')) {
          isConnected = false;
          errorMsg = result['error'];
       } else {
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
       }
    } else {
       isConnected = false;
       errorMsg = '网络超时';
    }

    isLoading = false;
    notifyListeners();
  }
}
