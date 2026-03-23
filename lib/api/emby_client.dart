import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmbyClient {
  final Dio _dio = Dio();

  Future<Map<String, dynamic>?> getLatestMedia() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String embyUrl = prefs.getString('emby_url') ?? '';
      final String embyKey = prefs.getString('emby_api_key') ?? '';

      if (embyUrl.isEmpty || embyKey.isEmpty) {
        return {'error': '请在设置中配置 Emby 地址和 API Key'};
      }

      // 获取最新入库的内容
      // /Users/{UserId}/Items/Latest 不太好用如果不知道 UserId
      // 使用 /Items?SortBy=DateCreated&SortOrder=Descending&Limit=10&Recursive=true&IncludeItemTypes=Movie,Series
      final url = '$embyUrl/Items';
      final response = await _dio.get(
        url,
        queryParameters: {
          'api_key': embyKey,
          'SortBy': 'DateCreated',
          'SortOrder': 'Descending',
          'Limit': 10,
          'Recursive': 'true',
          'IncludeItemTypes': 'Movie,Series',
          'Fields': 'PrimaryImageAspectRatio'
        },
        options: Options(validateStatus: (_) => true),
      );

      if (response.statusCode == 200) {
        return {'data': response.data};
      } else {
        return {'error': '连接 Emby 失败，HTTP状态码: ${response.statusCode}'};
      }
    } catch (e) {
      return {'error': '网络异常: $e'};
    }
  }
}
