import 'package:dio/dio.dart';
import '../utils/app_config.dart';

class PortainerClient {
  final Dio _dio = Dio();
  int? endpointId;

  /// Compute CPU% from Docker stats payload.
  double _calcCpuPercent(Map<String, dynamic> stats) {
    try {
      final cpuStats = stats['cpu_stats'] as Map<String, dynamic>?;
      final precpuStats = stats['precpu_stats'] as Map<String, dynamic>?;
      if (cpuStats == null || precpuStats == null) return 0.0;

      final cpuUsage = cpuStats['cpu_usage'] as Map<String, dynamic>?;
      final precpuUsage = precpuStats['cpu_usage'] as Map<String, dynamic>?;
      if (cpuUsage == null || precpuUsage == null) return 0.0;

      final total = (cpuUsage['total_usage'] as num?)?.toDouble() ?? 0.0;
      final preTotal = (precpuUsage['total_usage'] as num?)?.toDouble() ?? 0.0;
      final system = (cpuStats['system_cpu_usage'] as num?)?.toDouble() ?? 0.0;
      final preSystem = (precpuStats['system_cpu_usage'] as num?)?.toDouble() ?? 0.0;

      final cpuDelta = total - preTotal;
      final systemDelta = system - preSystem;

      final online = (cpuStats['online_cpus'] as num?)?.toDouble() ??
          ((cpuUsage['percpu_usage'] is List) ? (cpuUsage['percpu_usage'] as List).length.toDouble() : 1.0);

      if (systemDelta <= 0 || cpuDelta <= 0) return 0.0;
      return (cpuDelta / systemDelta) * online * 100.0;
    } catch (_) {
      return 0.0;
    }
  }

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
          "Username": AppConfig.activePortainerUser,
          "Password": AppConfig.activePortainerPass
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

  Future<Map<String, dynamic>?> getContainerStats(String containerId) async {
    try {
      if (endpointId == null) await login();
      if (endpointId == null) return {'error': 'Portainer 未登录'};

      final url = '${AppConfig.portainerUrl}/api/endpoints/$endpointId/docker/containers/$containerId/stats?stream=false';
      final response = await _dio.get(
        url,
        options: Options(
          headers: {'Authorization': 'Bearer ${AppConfig.portainerToken}'},
          validateStatus: (_) => true,
        ),
      );

      if (response.statusCode == 200 && response.data is Map) {
        final stats = Map<String, dynamic>.from(response.data);
        final memStats = stats['memory_stats'] as Map<String, dynamic>?;
        final memUsage = (memStats?['usage'] as num?)?.toDouble() ?? 0.0;
        final memLimit = (memStats?['limit'] as num?)?.toDouble() ?? 0.0;

        return {
          'cpuPercent': _calcCpuPercent(stats),
          'memUsageBytes': memUsage,
          'memLimitBytes': memLimit,
        };
      }

      return {'error': 'Portainer stats HTTP ${response.statusCode}'};
    } catch (e) {
      return {'error': 'Portainer stats 异常: $e'};
    }
  }
}
