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

      // Unraid API 插件通常使用的是 GraphQL
      final response = await _dio.post(
        '/graphql',
        data: {
          "query": "query { system { state { cpuLoad } } }"
        },
      );
      
      if (response.data is String) {
        try {
          return jsonDecode(response.data) as Map<String, dynamic>;
        } catch (_) {
          return {'error': '收到非JSON数据 (可能端口填错了，连到了别的网页): ${response.data.toString().substring(0, 30)}...'};
        }
      }
      
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      
      return {'error': '未知的数据格式'};
      
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
         return {'error': '404 未找到接口: 请确认端口是否为19009'};
      }
      return {'error': e.message ?? e.toString()};
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
