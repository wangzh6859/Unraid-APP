import 'package:dio/dio.dart';
import 'package:html/parser.dart' show parse;
import '../utils/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UnraidWebClient {
  final Dio _dio = Dio();
  String _csrfToken = '';
  String _cookie = '';

  UnraidWebClient() {
    _dio.options.validateStatus = (status) => true;
    _dio.options.followRedirects = false; // Important for login capture
  }

  Future<bool> login() async {
    await AppConfig.load();
    if (AppConfig.baseDomain.isEmpty) return false;

    try {
      // 1. Send POST to /login
      final response = await _dio.post(
        '${AppConfig.baseDomain}/login',
        data: FormData.fromMap({
          'username': AppConfig.username, // usually 'root'
          'password': AppConfig.password,
        }),
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        ),
      );

      // Check for set-cookie
      final cookies = response.headers['set-cookie'];
      if (cookies != null && cookies.isNotEmpty) {
        _cookie = cookies.first.split(';').first; // e.g. PHPSESSID=xxxx
      }

      // 2. Fetch /Dashboard to get CSRF token
      final dashResp = await _dio.get(
        '${AppConfig.baseDomain}/Dashboard',
        options: Options(
          headers: {'Cookie': _cookie},
        ),
      );

      if (dashResp.statusCode == 200) {
        final html = dashResp.data.toString();
        // Look for var csrf_token = "..."
        final RegExp regex = RegExp(r'var\s+csrf_token\s*=\s*"([^"]+)"');
        final match = regex.firstMatch(html);
        if (match != null && match.groupCount >= 1) {
          _csrfToken = match.group(1)!;
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Unraid WebGUI login error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getVms() async {
    if (_csrfToken.isEmpty || _cookie.isEmpty) {
      bool ok = await login();
      if (!ok) return {'error': 'Unraid 原生登录失败'};
    }

    try {
      // Usually VMs list can be fetched from /update.htm?api=vms or we have to parse /VMs
      // Actually, unraid returns state in a JSON-like format or html fragment if we request the right script.
      // For now, let's just scrape the /VMs page or /plugins/dynamix.vm.manager/include/VMMachines.php
      // Unraid 6/7 relies heavily on `update.htm` polling.
      final response = await _dio.post(
        '${AppConfig.baseDomain}/update.htm',
        data: FormData.fromMap({'csrf_token': _csrfToken, 'api': 'vms'}),
        options: Options(headers: {'Cookie': _cookie}),
      );

      if (response.statusCode == 200) {
         // Unfortunately update.htm might not return standard json depending on version.
         // Let's fallback to scraping /VMs html if needed.
         return {'raw': response.data.toString()};
      }
      return {'error': '无法获取虚拟机状态'};
    } catch (e) {
      return {'error': '网络异常: $e'};
    }
  }
}
