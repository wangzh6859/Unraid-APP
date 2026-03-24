import 'package:dio/dio.dart';
import '../utils/app_config.dart';

class UnraidWebClient {
  final Dio _dio = Dio();
  String _csrfToken = '';
  String getCsrfToken() => _csrfToken;
  String _cookie = '';

  Future<bool> _ensureLogin() async {
    if (_csrfToken.isNotEmpty && _cookie.isNotEmpty) return true;
    return await login();
  }

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
    final ok = await _ensureLogin();
    if (!ok) return {'error': 'Unraid 原生登录失败 (请检查密码是否为 root 密码)'};
    
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
    final ok = await _ensureLogin();
    if (!ok) return {'error': 'Unraid 登录失败'};

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

  Future<Map<String, dynamic>> vmAction(String uuid, String action) async {
    // action: domain-start | domain-stop | domain-restart | domain-force-stop
    final ok = await _ensureLogin();
    if (!ok) return {'error': 'Unraid 登录失败'};

    try {
      final res = await _dio.post(
        '${AppConfig.baseDomain}/plugins/dynamix.vm.manager/include/VMajax.php',
        data: {
          'csrf_token': _csrfToken,
          'action': action,
          'uuid': uuid,
          'response': 'json',
        },
        options: Options(
          headers: {
            'Cookie': _cookie,
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        ),
      );

      // Unraid sometimes returns JSON or plain text. We just return debug info.
      return {
        'status': res.statusCode ?? 0,
        'data': res.data,
      };
    } catch (e) {
      return {'error': 'VM 操作失败: $e'};
    }
  }

  Future<Map<String, dynamic>?> getDockerContainers() async {
    // Unraid WebGUI fills Docker list dynamically as well.
    // Common endpoints (vary by version):
    // - /plugins/dynamix.docker.manager/include/DockerContainers.php
    // - /plugins/dynamix.docker.manager/include/DockerUpdate.php
    final ok = await _ensureLogin();
    if (!ok) return {'error': 'Unraid 登录失败'};

    try {
      String debugInfo = "";
      debugInfo += "csrf_token: ${_csrfToken.isEmpty ? 'EMPTY' : 'OK'}\n";
      debugInfo += "cookie: ${_cookie.isEmpty ? 'EMPTY' : 'OK'}\n\n";

      // 1) Fetch /Docker page for sanity (optional)
      final resPage = await _dio.get(
        '${AppConfig.baseDomain}/Docker',
        options: Options(headers: {'Cookie': _cookie}),
      );
      final pageBody = resPage.data?.toString() ?? '';
      debugInfo += "[/Docker] Status: ${resPage.statusCode} Length: ${pageBody.length}\n";

      // 2) Fetch dynamic Docker list HTML
      final candidates = [
        '/plugins/dynamix.docker.manager/include/DockerContainers.php',
        '/plugins/dynamix.docker.manager/include/DockerUpdate.php',
      ];

      for (final p in candidates) {
        final res = await _dio.get(
          '${AppConfig.baseDomain}$p',
          options: Options(headers: {'Cookie': _cookie}),
        );
        final body = res.data?.toString() ?? '';
        debugInfo += "[$p] Status: ${res.statusCode} Length: ${body.length}\n";

        if (res.statusCode == 200 && body.isNotEmpty) {
          return {'data': debugInfo, 'raw': body, 'path': p};
        }
      }

      return {'error': '无法获取 Docker 列表（所有候选接口都失败）', 'data': debugInfo};
    } catch (e) {
      return {'error': '抓取 Docker 列表失败: $e'};
    }
  }

  Future<Map<String, dynamic>> dockerAction(String containerNameOrId, String action) async {
    // Best-effort native action. If this fails, caller should fallback to Portainer.
    // action: start | stop | restart
    final ok = await _ensureLogin();
    if (!ok) return {'error': 'Unraid 登录失败'};

    final endpoint = '${AppConfig.baseDomain}/plugins/dynamix.docker.manager/include/DockerUpdate.php';

    // Different Unraid versions use different parameter names.
    // We'll try a few common shapes and accept 200/204 as "sent".
    final attempts = <Map<String, dynamic>>[
      {
        'csrf_token': _csrfToken,
        'action': action,
        'container': containerNameOrId,
      },
      {
        'csrf_token': _csrfToken,
        'action': action,
        'name': containerNameOrId,
      },
      {
        'csrf_token': _csrfToken,
        'cmd': action,
        'container': containerNameOrId,
      },
      {
        'csrf_token': _csrfToken,
        'cmd': action,
        'name': containerNameOrId,
      },
      {
        'csrf_token': _csrfToken,
        'action': 'docker-$action',
        'container': containerNameOrId,
      },
    ];

    try {
      int idx = 0;
      for (final data in attempts) {
        idx++;
        final res = await _dio.post(
          endpoint,
          data: data,
          options: Options(
            headers: {
              'Cookie': _cookie,
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            validateStatus: (_) => true,
          ),
        );

        final code = res.statusCode ?? 0;
        // Some responses are HTML; some are JSON.
        final body = res.data;

        if (code == 200 || code == 204) {
          return {
            'status': code,
            'attempt': idx,
            'sent': true,
            'data': body,
          };
        }
      }

      return {'error': 'Docker 原生操作未命中可用参数组合', 'status': 0};
    } catch (e) {
      return {'error': 'Docker 操作失败: $e'};
    }
  }
}



