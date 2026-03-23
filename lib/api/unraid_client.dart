import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UnraidClient {
  final Dio _dio = Dio();
  String? baseUrl;
  String? apiKey;
  
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    baseUrl = prefs.getString('unraid_ip');
    apiKey = prefs.getString('unraid_api_key');
    
    if (baseUrl != null && baseUrl!.isNotEmpty) {
      _dio.options.baseUrl = baseUrl!;
    }
    
    if (apiKey != null && apiKey!.isNotEmpty) {
      _dio.options.headers['x-api-key'] = apiKey; // Depending on API version, might be Authorization: Bearer
    }
    _dio.options.connectTimeout = const Duration(seconds: 5);
    _dio.options.receiveTimeout = const Duration(seconds: 5);
  }

  // 获取 CPU 等统计信息
  Future<Map<String, dynamic>?> getServerStats() async {
    try {
      await init();
      if (baseUrl == null || baseUrl!.isEmpty) return null;

      // 尝试调用 Unraid API 常见的系统状态接口 
      // 常见路径有 /api/system/info 或者 /api/v1/system 等，这里先用 GraphQL 请求或通用的 info
      final response = await _dio.get('/api/system');
      
      return response.data;
    } on DioException catch (e) {
      print('HTTP Request failed: ${e.message}');
      return {'error': e.message};
    } catch (e) {
      print('Unknown Error: $e');
      return {'error': e.toString()};
    }
  }
}
