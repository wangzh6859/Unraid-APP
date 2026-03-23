import 'package:flutter/material.dart';
import '../api/unraid_client.dart';

class ServerProvider with ChangeNotifier {
  final UnraidClient _api = UnraidClient();
  
  bool isLoading = false;
  bool isConnected = false;
  String cpuUsage = '0%';
  String memUsage = '0%';
  String errorMsg = '';
  
  ServerProvider() {
    refreshData();
  }

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
}
