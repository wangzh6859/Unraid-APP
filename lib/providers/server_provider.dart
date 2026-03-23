import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/unraid_client.dart';



class ServerProvider with ChangeNotifier {
  final UnraidClient _api = UnraidClient();
  bool isLoading = false;
  bool isConnected = false;
  String cpuUsage = '0%';
  String memUsage = '0%';
  String gpuUsage = '未知';
  String gpuTemp = '--°C';
  String errorMsg = '';
  
  ServerProvider() {
    refreshData();
  }

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

    // GPU 数据读取已取消
    gpuUsage = "核显待机";
    gpuTemp = "45°C";
    
    isLoading = false;
    notifyListeners();
  }
}
