import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UnraidClient {
  final Dio _dio = Dio();
  String? baseUrl;
  
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    baseUrl = prefs.getString('unraid_url') ?? 'http://192.168.1.100';
    _dio.options.baseUrl = baseUrl!;
    _dio.options.connectTimeout = const Duration(seconds: 5);
  }

  // 预留的获取服务器信息接口
  Future<Map<String, dynamic>?> getServerStats() async {
    try {
      // TODO: 对接真实 Unraid API 路径
      // final response = await _dio.get('/api/getSystemStats');
      // return response.data;
      
      // 模拟网络延迟
      await Future.delayed(const Duration(seconds: 1));
      return null; // 暂无真实接口
    } catch (e) {
      print('获取 Unraid 数据失败: $e');
      return null;
    }
  }
}
