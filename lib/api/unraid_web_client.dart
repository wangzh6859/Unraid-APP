import 'dart:convert';
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

  Future<Map<String, dynamic>?> getDockerStats() async {
    // Best-effort: some Unraid versions expose a stats endpoint.
    final ok = await _ensureLogin();
    if (!ok) return {'error': 'Unraid 登录失败'};

    try {
      final candidates = [
        '/plugins/dynamix.docker.manager/include/DockerStats.php',
        '/plugins/dynamix.docker.manager/include/DockerStatus.php',
      ];

      for (final p in candidates) {
        final res = await _dio.get(
          '${AppConfig.baseDomain}$p',
          options: Options(headers: {'Cookie': _cookie}),
        );
        final body = res.data?.toString() ?? '';
        if (res.statusCode == 200 && body.isNotEmpty) {
          // If JSON, parse it.
          final t = body.trimLeft();
          if (t.startsWith('{') || t.startsWith('[')) {
            final parsed = jsonDecode(body);
            return {'path': p, 'data': parsed};
          }
          return {'path': p, 'raw': body};
        }
      }

      return {'error': '未找到可用的 DockerStats 端点'};
    } catch (e) {
      return {'error': 'DockerStats 获取失败: $e'};
    }
  }

  Future<Map<String, dynamic>> dockerAction({required String name, String? id, String? hash, String? template, required String action}) async {
    // Native docker control via StartCommand.php is the most reliable, because it's what WebGUI uses
    // to run docker commands in the background.
    // We'll attempt this first, then fallback to DockerUpdate.php probing.
    final ok = await _ensureLogin();
    if (!ok) return {'error': 'Unraid 登录失败'};

    String dockerCmd;
    switch (action) {
      case 'start':
        dockerCmd = 'docker start ${name}';
        break;
      case 'stop':
        dockerCmd = 'docker stop ${name}';
        break;
      case 'restart':
        dockerCmd = 'docker restart ${name}';
        break;
      default:
        dockerCmd = 'docker ${action} ${name}';
    }

    try {
      // Try StartCommand first.
      final res = await _dio.post(
        '${AppConfig.baseDomain}/webGui/include/StartCommand.php',
        data: {
          'csrf_token': _csrfToken,
          'cmd': dockerCmd,
          'start': 1,
        },
        options: Options(
          headers: {
            'Cookie': _cookie,
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          validateStatus: (_) => true,
        ),
      );

      // WebGUI returns pid as plain text.
      final bodyStr = res.data?.toString().trim() ?? '';
      final pid = int.tryParse(bodyStr) ?? 0;
      if ((res.statusCode == 200) && pid > 0) {
        return {'status': 200, 'sent': true, 'method': 'StartCommand', 'pid': pid, 'cmd': dockerCmd};
      }
    } catch (_) {
      // ignore and fallback
    }

    // Fallback: probe DockerUpdate.php (kept for compatibility).
    final endpoint = '${AppConfig.baseDomain}/plugins/dynamix.docker.manager/include/DockerUpdate.php';

    bool looksOk(dynamic body) {
      final s = body?.toString().toLowerCase() ?? '';
      if (s.contains('_error_') || s.contains('fatal') || s.contains('notice') || s.contains('warning')) return false;
      if (s.contains('error') && !s.contains('no error')) return false;
      return true;
    }

    final actionAliases = <String>[action, 'container-$action', 'docker-$action', '${action}Container'];

    List<Map<String, dynamic>> buildAttempts() {
      final out = <Map<String, dynamic>>[];
      for (final a in actionAliases) {
        out.add({'csrf_token': _csrfToken, 'action': a, 'container': name});
        out.add({'csrf_token': _csrfToken, 'action': a, 'name': name});
        out.add({'csrf_token': _csrfToken, 'cmd': a, 'container': name});
        out.add({'csrf_token': _csrfToken, 'cmd': a, 'name': name});

        if (id != null && id.isNotEmpty) {
          out.add({'csrf_token': _csrfToken, 'action': a, 'id': id, 'container': name});
          out.add({'csrf_token': _csrfToken, 'action': a, 'ct': id, 'container': name});
        }
        if (hash != null && hash.isNotEmpty) {
          out.add({'csrf_token': _csrfToken, 'action': a, 'hash': hash, 'container': name});
          out.add({'csrf_token': _csrfToken, 'action': a, 'ct': hash, 'container': name});
        }
        if (template != null && template.isNotEmpty) {
          out.add({'csrf_token': _csrfToken, 'action': a, 'xml': template, 'container': name});
          out.add({'csrf_token': _csrfToken, 'action': a, 'template': template, 'container': name});
        }
      }
      return out;
    }

    try {
      final attempts = buildAttempts();
      final debug = <String>[];

      for (int i = 0; i < attempts.length; i++) {
        final data = attempts[i];
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
        final body = res.data;
        final snippet = (body?.toString() ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();
        debug.add('#${i + 1} HTTP $code data=${snippet.substring(0, snippet.length > 120 ? 120 : snippet.length)}');

        if ((code == 200 || code == 204) && looksOk(body)) {
          return {
            'status': code,
            'attempt': i + 1,
            'sent': true,
            'method': 'DockerUpdate',
            'used': data,
            'data': body,
          };
        }
      }

      return {
        'error': 'Docker 原生操作未命中可用参数组合或返回包含错误信息',
        'status': 0,
        'debug': debug.take(12).join('\n'),
      };
    } catch (e) {
      return {'error': 'Docker 操作失败: $e'};
    }
  }
}




