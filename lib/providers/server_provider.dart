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
      } else {
        isConnected = true;
        // Mock parsing since we need to see the actual JSON structure first
        cpuUsage = '22%'; 
        memUsage = '45%';
      }
    } else {
      isConnected = false;
      errorMsg = "未配置IP或连接超时";
    }

    isLoading = false;
    notifyListeners();
  }
}
