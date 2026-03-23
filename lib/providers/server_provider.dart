import 'package:flutter/material.dart';
import '../api/glances_client.dart';

class ServerProvider extends ChangeNotifier {
  final GlancesClient _api = GlancesClient();
  
  bool isConnected = false;
  bool isLoading = false;
  String errorMsg = '';
  
  String cpuModel = 'Glances Node';
  String cpuUsage = '0%';
  String memUsage = '0%';
  String gpuUsage = '核显/待机';
  String gpuTemp = '45°C';

  Future<void> refreshData() async {
    isLoading = true;
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
            if (data['system'] != null) {
               cpuModel = '${data['system']['os_name']} · ${data['system']['hostname']}';
            }
            if (data['cpu'] != null) {
               cpuUsage = '${data['cpu']['total']}%';
            }
            if (data['mem'] != null) {
               memUsage = '${data['mem']['percent']}%';
            }
            if (data['gpu'] != null && data['gpu'].isNotEmpty) {
               gpuUsage = '${data['gpu'][0]['proc']}%';
               gpuTemp = '${data['gpu'][0]['temperature'] ?? 'N/A'}°C';
            } else {
               gpuUsage = '未检测到独立GPU';
               gpuTemp = '--';
            }
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
