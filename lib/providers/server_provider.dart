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
        // GraphQL 错误
        isConnected = false;
        errorMsg = 'GraphQL报错: ' + (data['errors'][0]['message'] ?? '未知错误');
      } else {
        isConnected = true;
        // 尝试解析真实的 info 数据
        try {
          final info = data['data']['info'];
          // 暂时用占位，证明拿到了
          cpuUsage = info['cpu']['cores'].toString() + ' 核';
          memUsage = '已获取'; 
        } catch (e) {
          errorMsg = '数据解析失败: 请确认您的Unraid版本是否支持此查询';
          isConnected = false;
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
