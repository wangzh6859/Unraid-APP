import 'package:flutter/material.dart';
import '../api/unraid_client.dart';

class ServerProvider with ChangeNotifier {
  final UnraidClient _api = UnraidClient();
  
  bool isLoading = false;
  String cpuUsage = '0%';
  String memUsage = '0%';
  
  ServerProvider() {
    _init();
  }

  Future<void> _init() async {
    await _api.init();
    fetchData();
  }

  Future<void> fetchData() async {
    isLoading = true;
    notifyListeners();

    final data = await _api.getServerStats();
    if (data != null) {
      // 解析真实数据
    }

    isLoading = false;
    notifyListeners();
  }
}
