import re
with open('lib/api/unraid_web_client.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Increase timeout to 10 seconds
code = code.replace("const Duration(seconds: 5);", "const Duration(seconds: 10);")

# Change login() error handling to throw instead of returning false silently, so we know if login failed.
login_code_old = """    } catch (e) {
      return false;
    }"""
login_code_new = """    } catch (e) {
      throw Exception("登录请求异常: $e");
    }"""
code = code.replace(login_code_old, login_code_new)

# Fix FormData.fromMap -> urlencoded for update.htm requests
old_sys_req = """      final response = await _dio.post(
        '${AppConfig.baseDomain}/update.htm',
        data: FormData.fromMap({'csrf_token': _csrfToken, 'api': 'sys'}),
        options: Options(headers: {'Cookie': _cookie}),
      );"""

new_sys_req = """      final response = await _dio.post(
        '${AppConfig.baseDomain}/update.htm',
        data: {'csrf_token': _csrfToken, 'api': 'sys'},
        options: Options(
          headers: {'Cookie': _cookie},
          contentType: Headers.formUrlEncodedContentType,
        ),
      );"""
code = code.replace(old_sys_req, new_sys_req)

old_vms_req = """      final response = await _dio.post(
        '${AppConfig.baseDomain}/update.htm',
        data: FormData.fromMap({'csrf_token': _csrfToken, 'api': 'vms'}),
        options: Options(headers: {'Cookie': _cookie}),
      );"""

new_vms_req = """      final response = await _dio.post(
        '${AppConfig.baseDomain}/update.htm',
        data: {'csrf_token': _csrfToken, 'api': 'vms'},
        options: Options(
          headers: {'Cookie': _cookie},
          contentType: Headers.formUrlEncodedContentType,
        ),
      );"""
code = code.replace(old_vms_req, new_vms_req)

with open('lib/api/unraid_web_client.dart', 'w', encoding='utf-8') as f:
    f.write(code)

with open('lib/providers/server_provider.dart', 'r', encoding='utf-8') as f:
    pcode = f.read()
# Let's show csrf_token on screen too so user sees it successfully logged in
pcode = pcode.replace("errorMsg = ''; // clear error", "errorMsg = ''; rawVmResponse = 'Token: ${_unraidNative.getCsrfToken()}\\n\\n';")

with open('lib/providers/server_provider.dart', 'w', encoding='utf-8') as f:
    f.write(pcode)
