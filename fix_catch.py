with open('lib/api/unraid_client.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# I wrote `} catch (e) {` without giving `e` a type, but inside I was using e.toString(). 
# Wait, actually the error says "The method 'catch' isn't defined for the class 'UnraidClient'."
# This means there is a syntax error causing the catch block to be outside the method or malformed!

# Let's check the code replacement from previous step:
# It seems my regex replaced something badly. Let's look at the method again.

new_method = """
  // 获取 CPU 等统计信息
  Future<Map<String, dynamic>?> getServerStats() async {
    try {
      await init();
      if (baseUrl == null || baseUrl!.isEmpty) return null;

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
          String preview = response.data.toString().replaceAll('\\n', ' ').trim();
          if (preview.length > 50) preview = preview.substring(0, 50) + '...';
          return {'error': '收到网页而非接口数据: 可能是填错了端口（如果是v7.2+直接填控制台地址，如果是旧版填插件端口）。\\n返回内容: $preview'};
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
"""

import re
# We just replace the whole getServerStats block safely.
pattern = r"// 获取 CPU 等统计信息\s*Future<Map<String, dynamic>\?> getServerStats\(\) async \{.*?(?=^\s*\w|\Z)"
code = re.sub(pattern, new_method, code, flags=re.DOTALL | re.MULTILINE)

# The regex above might be dangerous if it goes too far. Let's just find the exact block since there is only one method left in the class.
# Wait, let's just rewrite unraid_client.dart completely to be safe.

full_code = """import 'dart:convert';
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
          String preview = response.data.toString().replaceAll('\\n', ' ').trim();
          if (preview.length > 50) preview = preview.substring(0, 50) + '...';
          return {'error': '收到网页而非接口数据: 可能是填错了端口（如果是v7.2+直接填控制台地址，如果是旧版填插件端口）。\\n返回内容: $preview'};
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
"""

with open('lib/api/unraid_client.dart', 'w', encoding='utf-8') as f:
    f.write(full_code)
