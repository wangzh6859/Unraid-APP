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
      final response = await _dio.post(
        '${AppConfig.baseDomain}/login',
        data: {
          'username': AppConfig.username,
          'password': AppConfig.password,
        },
        options: Options(
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        ),
      );

      final cookies = response.headers['set-cookie'];
      if (cookies != null && cookies.isNotEmpty) {
        _cookie = cookies.first.split(';').first;
      }

      final dashResp = await _dio.get(
        '${AppConfig.baseDomain}/Dashboard',
        options: Options(headers: {'Cookie': _cookie}),
      );

      if (dashResp.statusCode == 200) {
        final html = dashResp.data.toString();
        final RegExp regex = RegExp(r'var\s+csrf_token\s*=\s*"([^"]+)"');
        final match = regex.firstMatch(html);
        if (match != null && match.groupCount >= 1) {
          _csrfToken = match.group(1)!;
          return true;
        } else {
           throw Exception("未能在 Dashboard 找到 csrf_token");
        }
      } else {
         throw Exception("Dashboard 响应码: ${dashResp.statusCode}");
      }
    } catch (e) {
      throw Exception("登录请求异常: $e");
    }
  }

  Future<Map<String, dynamic>?> getDashboardStats() async {
    if (_csrfToken.isEmpty || _cookie.isEmpty) {
      bool ok = await login();
      if (!ok) return {'error': 'Unraid 原生登录失败 (请检查密码是否为 root 密码)'};
    }
    
    try {
      final response = await _dio.post(
        '${AppConfig.baseDomain}/update.htm',
        data: {'csrf_token': _csrfToken, 'api': 'sys'},
        options: Options(
          headers: {'Cookie': _cookie},
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      if (response.statusCode == 200) {
        return {'data': response.data.toString()};
      }
      return {'error': '无法加载主界面数据: ${response.statusCode}'};
    } catch (e) {
      return {'error': '网络连接异常: $e'};
    }
  }

  Future<Map<String, dynamic>?> getVms() async {
    // Unraid 7.x: /VMs page body does NOT contain the VM list.
    // The table <tbody id="kvm_list"> is filled by XHR:
    // GET /plugins/dynamix.vm.manager/include/VMMachines.php
    if (_csrfToken.isEmpty || _cookie.isEmpty) {
      bool ok = await login();
      if (!ok) return {'error': 'Unraid 登录失败'};
    }

    try {
      String debugInfo = "";
      debugInfo += "csrf_token: ${_csrfToken.isEmpty ? 'EMPTY' : 'OK'}\n";
      debugInfo += "cookie: ${_cookie.isEmpty ? 'EMPTY' : 'OK'}\n\n";

      // 1) Fetch /VMs (optional, only for debug / sanity)
      final resPage = await _dio.get(
        '${AppConfig.baseDomain}/VMs',
        options: Options(headers: {'Cookie': _cookie}),
      );
      final pageBody = resPage.data?.toString() ?? '';
      debugInfo += "[/VMs] Status: ${resPage.statusCode} Length: ${pageBody.length}\n";

      // 2) Fetch dynamic VM list HTML
      final resList = await _dio.get(
        '${AppConfig.baseDomain}/plugins/dynamix.vm.manager/include/VMMachines.php',
        queryParameters: {
          // 'show' corresponds to $.cookie('vmshow') in WebGUI; optional.
        },
        options: Options(headers: {'Cookie': _cookie}),
      );
      final listBody = resList.data?.toString() ?? '';
      debugInfo += "[/VMMachines.php] Status: ${resList.statusCode} Length: ${listBody.length}\n";

      if (resList.statusCode == 200 && listBody.isNotEmpty) {
        // VMMachines.php returns: "<tr>...</tr>...\0<script>...</script>"
        // We keep the raw response for parsing.
        return {'data': debugInfo, 'raw': listBody};
      }

      return {
        'error': '无法获取 VMMachines.php: HTTP ${resList.statusCode} (len=${listBody.length})',
        'data': debugInfo,
      };
    } catch (e) {
      return {'error': '抓取 VM 列表失败: $e'};
    }
  }
}


