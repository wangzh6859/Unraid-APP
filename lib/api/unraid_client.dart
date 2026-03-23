import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UnraidClient {
  final Dio _dio = Dio();
  String? baseUrl;
  String? apiKey;
  
  
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    String? rawUrl = prefs.getString('unraid_ip');
    apiKey = prefs.getString('unraid_api_key');
    
    if (rawUrl != null && rawUrl.isNotEmpty) {
      // 容错处理: 如果用户输入了结尾多余的字符清理掉，确保是合法的 baseUrl
      rawUrl = rawUrl.trim();
      if (!rawUrl.startsWith('http')) {
        rawUrl = 'http://' + rawUrl;
      }
      if (rawUrl.endsWith('/')) {
        rawUrl = rawUrl.substring(0, rawUrl.length - 1);
      }
      baseUrl = rawUrl;
      _dio.options.baseUrl = baseUrl!;
    }
    
    if (apiKey != null && apiKey!.isNotEmpty) {
      _dio.options.headers['x-api-key'] = apiKey;
    }
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
  }

  // 获取 CPU 等统计信息
  Future<Map<String, dynamic>?> getServerStats() async {
    try {
      await init();
      if (baseUrl == null || baseUrl!.isEmpty) return null;

      final response = await _dio.get('/api/system');
      
      // 容错处理: 有时服务器没返回 application/json，Dio 会把它当 String 处理
      if (response.data is String) {
        try {
          return jsonDecode(response.data) as Map<String, dynamic>;
        } catch (_) {
          return {'error': '收到非 JSON 数据: ${response.data.toString().substring(0, 30)}...'};
        }
      }
      
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      
      return {'error': '未知的数据格式'};
      
    } on DioException catch (e) {
      print('HTTP Request failed: ${e.message}');
      return {'error': e.message ?? e.toString()};
    } catch (e) {
      print('Unknown Error: $e');
      return {'error': e.toString()};
    }
  }
}
