import 'dart:convert';
import 'package:dio/dio.dart';
import '../utils/app_config.dart';

class GlancesClient {
  final Dio _dio = Dio();

  Future<Map<String, dynamic>?> getServerStats() async {
    try {
      await AppConfig.load();
      if (AppConfig.baseDomain.isEmpty) return {'error': '未配置服务器'};

      String basicAuth = 'Basic ' + base64Encode(utf8.encode('${AppConfig.username}:${AppConfig.password}'));
      final response = await _dio.get(
        '${AppConfig.glancesUrl}/api/3/all',
        options: Options(
          headers: {'Authorization': basicAuth},
          validateStatus: (_) => true,
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 401) {
         return {'error': 'Glances 认证失败，请检查账户密码'};
      }
      if (response.statusCode != 200) {
         return {'error': 'Glances 异常，代码: ${response.statusCode}\n尝试访问: ${AppConfig.glancesUrl}'};
      }
      return {'data': response.data};
    } catch (e) {
      return {'error': '网络异常，请检查Glances地址: ${AppConfig.glancesUrl}'};
    }
  }
}
