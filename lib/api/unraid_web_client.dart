import 'package:dio/dio.dart';
import '../utils/app_config.dart';

class UnraidWebClient {
  final Dio _dio = Dio();
  String _csrfToken = '';
  String getCsrfToken() => _csrfToken;
  String _cookie = '';

  
  UnraidWebClient() {
    _dio.options.validateStatus = (status) => true;
    _dio.options.followRedirects = false; // Important for login capture
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
  }


  Future<bool> login() async {
    await AppConfig.load();
    if (AppConfig.baseDomain.isEmpty) return false;

    try {
      String debugInfo = "";
      
      // Try GET /VMs
      final res1 = await _dio.get('${AppConfig.baseDomain}/VMs', options: Options(headers: {'Cookie': _cookie}));
      debugInfo += "[/VMs] Status: ${res1.statusCode} Length: ${res1.data.toString().length}
";
      
      // Try POST /webGui/scripts/vmmanager
      final res2 = await _dio.post('${AppConfig.baseDomain}/webGui/scripts/vmmanager', options: Options(headers: {'Cookie': _cookie}));
      debugInfo += "[/vmmanager] Status: ${res2.statusCode} Length: ${res2.data.toString().length}
";

      // Try GET /webGui/scripts/vmmanager
      final res3 = await _dio.get('${AppConfig.baseDomain}/webGui/scripts/vmmanager', options: Options(headers: {'Cookie': _cookie}));
      debugInfo += "[/vmmanager_GET] Status: ${res3.statusCode} Length: ${res3.data.toString().length}
";

      return {'data': debugInfo};
    } catch (e) {
      return {'error': '多重探测失败: $e'};
    }
    } catch (e) {
      return {'error': '网络异常: $e'};
    }
  }
}
