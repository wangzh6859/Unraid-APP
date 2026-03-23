import 'package:dio/dio.dart';
import '../utils/app_config.dart';

class PortainerClient {
  final Dio _dio = Dio();
  int? endpointId;

  Future<bool> login() async {
    await AppConfig.load();
    if (AppConfig.baseDomain.isEmpty) return false;
    
    // Check if token is still valid by getting endpoints
    if (AppConfig.portainerToken.isNotEmpty && endpointId != null) return true;

    try {
      final url = '${AppConfig.portainerUrl}/api/auth';
      final response = await _dio.post(
        url,
        data: {
          "Username": AppConfig.username,
          "Password": AppConfig.password
        },
        options: Options(validateStatus: (_) => true),
      );

      if (response.statusCode == 200 && response.data != null) {
         final token = response.data['jwt'];
         await AppConfig.savePortainerToken(token);
         
         // Fetch endpoint ID (Local environment is usually 1, but let's fetch to be sure)
         return await _fetchEndpointId();
      }
    } catch (e) {
       print('Portainer login error: $e');
    }
    return false;
  }

  Future<bool> _fetchEndpointId() async {
    try {
      final response = await _dio.get(
        '${AppConfig.portainerUrl}/api/endpoints',
        options: Options(
          headers: {'Authorization': 'Bearer ${AppConfig.portainerToken}'},
          validateStatus: (_) => true
        )
      );
      if (response.statusCode == 200 && response.data is List && response.data.isNotEmpty) {
         // Default to the first environment
         endpointId = response.data[0]['Id'];
         return true;
      }
    } catch (e) {
      print('Portainer get endpoints error: $e');
    }
    return false;
  }

  Future<Map<String, dynamic>?> getContainers() async {
    try {
      bool loggedIn = await login();
      if (!loggedIn || endpointId == null) return {'error': 'Portainer 认证失败，尝试访问: ${AppConfig.portainerUrl}'};

      final url = '${AppConfig.portainerUrl}/api/endpoints/$endpointId/docker/containers/json?all=1';
      final response = await _dio.get(
        url,
        options: Options(
          headers: {'Authorization': 'Bearer ${AppConfig.portainerToken}'},
          validateStatus: (_) => true
        ),
      );

      if (response.statusCode == 200) {
        return {'data': response.data};
      } else {
        return {'error': '获取 Portainer 容器失败: ${response.statusCode}'};
      }
    } catch (e) {
      return {'error': 'Portainer 网络异常: ${AppConfig.portainerUrl}'};
    }
  }

  Future<bool> containerAction(String containerId, String action) async {
    try {
      if (endpointId == null) await login();
      if (endpointId == null) return false;

      final url = '${AppConfig.portainerUrl}/api/endpoints/$endpointId/docker/containers/$containerId/$action';
      final response = await _dio.post(
        url,
        options: Options(
          headers: {'Authorization': 'Bearer ${AppConfig.portainerToken}'},
          validateStatus: (_) => true
        ),
      );
      // 204 No Content is success for docker actions
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }
}
