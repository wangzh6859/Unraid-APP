import 'dart:convert';
import 'package:dio/dio.dart';
import '../utils/app_config.dart';

class GlancesClient {
  final Dio _dio = Dio();

  Future<Map<String, dynamic>?> getServerStats() async {
    try {
      await AppConfig.load();
      if (AppConfig.baseDomain.isEmpty) return {'error': '未配置主服务器'};

      String basicAuth = 'Basic ' + base64Encode(utf8.encode('${AppConfig.username}:${AppConfig.password}'));
      
      // Try Glances API v3
      String targetUrl = '${AppConfig.glancesUrl}/api/3/all';
      Response response = await _dio.get(
        targetUrl,
        options: Options(
          headers: {'Authorization': basicAuth},
          validateStatus: (_) => true,
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      // If 404, maybe it's Glances API v4 (newer versions) or api/2
      if (response.statusCode == 404) {
         targetUrl = '${AppConfig.glancesUrl}/api/4/all';
         response = await _dio.get(
           targetUrl,
           options: Options(
             headers: {'Authorization': basicAuth},
             validateStatus: (_) => true,
             receiveTimeout: const Duration(seconds: 5),
           ),
         );
      }

      if (response.statusCode == 401) {
         return {'error': 'Glances 认证失败，请检查账户密码\n地址: ${AppConfig.glancesUrl}'};
      }
      if (response.statusCode == 404) {
         return {'error': 'Glances 404: 找不到API接口。\n请确认:\n1. https://glances.您的域名 是否配置了反向代理。\n2. 代理是否正确指向了 Glances 的 61208 端口。'};
      }
      if (response.statusCode != 200) {
         return {'error': 'Glances 异常，代码: ${response.statusCode}\n尝试访问: $targetUrl'};
      }
      return {'data': response.data};
    } catch (e) {
      return {'error': '网络异常: ${e.toString().split('\n').first}\n地址: ${AppConfig.glancesUrl}'};
    }
  }
}
