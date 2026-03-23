import 'package:dio/dio.dart';
import '../utils/app_config.dart';

class EmbyClient {
  final Dio _dio = Dio();

  Future<bool> login() async {
    await AppConfig.load();
    if (AppConfig.embyToken.isNotEmpty) return true;
    if (AppConfig.baseDomain.isEmpty) return false;
    
    try {
      final url = '${AppConfig.embyUrl}/Users/AuthenticateByName';
      final response = await _dio.post(
        url,
        data: {
          "Username": AppConfig.activeEmbyUser,
          "Pw": AppConfig.activeEmbyPass
        },
        options: Options(
          headers: {
            'X-Emby-Authorization': 'MediaBrowser Client="UnraidApp", Device="Android", DeviceId="UnraidApp123", Version="1.0.0"'
          },
          validateStatus: (_) => true
        )
      );

      if (response.statusCode == 200 && response.data != null) {
         final token = response.data['AccessToken'];
         final userId = response.data['User']['Id'];
         
         await AppConfig.saveEmbyAuth(token, userId);
         return true;
      }
    } catch (e) {
       print('Emby login error: $e');
    }
    return false;
  }

  Future<Map<String, dynamic>?> getLatestMedia() async {
    try {
      bool loggedIn = await login();
      if (!loggedIn) return {'error': 'Emby 登录认证失败，尝试访问: ${AppConfig.embyUrl}'};

      final url = '${AppConfig.embyUrl}/Users/${AppConfig.embyUserId}/Items/Latest';
      final response = await _dio.get(
        url,
        queryParameters: {
          'Limit': 20,
          'Fields': 'PrimaryImageAspectRatio',
          'IsFolder': false
        },
        options: Options(
          headers: {
            'X-Emby-Token': AppConfig.embyToken
          },
          validateStatus: (_) => true
        ),
      );

      if (response.statusCode == 200) {
        return {'data': {'Items': response.data}};
      } else {
        return {'error': '获取 Emby 影视失败: ${response.statusCode}'};
      }
    } catch (e) {
      return {'error': '网络异常，请检查Emby地址: ${AppConfig.embyUrl}'};
    }
  }
}
