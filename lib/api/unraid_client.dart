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

      // Unraid 官方 GraphQL 接口查询系统信息
      final response = await _dio.post(
        '/graphql',
        data: {
          "query": "query { info { os { uptime } cpu { brand cores threads } } }"
        },
      );
      
      if (response.data is String) {
        try {
          return jsonDecode(response.data) as Map<String, dynamic>;
        } catch (_) {
          // 如果返回了纯 HTML 页面，提示端口不对
          String preview = response.data.toString().replaceAll('
', ' ').trim();
          if (preview.length > 50) preview = preview.substring(0, 50) + '...';
          return {'error': '收到网页而非接口数据: 可能是填错了端口（如果是v7.2+直接填控制台地址，如果是旧版填插件端口）。
返回内容: $preview'};
        }
      }
      
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      
      return {'error': '未知的数据格式'};
      
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
         return {'error': '404 未找到接口: 请确认地址后是否需要加端口号，或者是否在设置中开启了 API。'};
      }
      return {'error': e.message ?? e.toString()};
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
