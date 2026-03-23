import re
with open('lib/api/unraid_web_client.dart', 'r', encoding='utf-8') as f:
    code = f.read()

vms_fetch = """    try {
      String debugInfo = "";
      
      // Try GET /VMs
      final res1 = await _dio.get('${AppConfig.baseDomain}/VMs', options: Options(headers: {'Cookie': _cookie}));
      debugInfo += "[/VMs] Status: ${res1.statusCode} Length: ${res1.data.toString().length}\\n";
      
      // Try POST /webGui/scripts/vmmanager
      final res2 = await _dio.post('${AppConfig.baseDomain}/webGui/scripts/vmmanager', options: Options(headers: {'Cookie': _cookie}));
      debugInfo += "[/vmmanager] Status: ${res2.statusCode} Length: ${res2.data.toString().length}\\n";

      // Try GET /webGui/scripts/vmmanager
      final res3 = await _dio.get('${AppConfig.baseDomain}/webGui/scripts/vmmanager', options: Options(headers: {'Cookie': _cookie}));
      debugInfo += "[/vmmanager_GET] Status: ${res3.statusCode} Length: ${res3.data.toString().length}\\n";

      return {'data': debugInfo};
    } catch (e) {
      return {'error': '多重探测失败: $e'};
    }"""

# Replace the current try-catch block for getVms
code = re.sub(r"    try \{.*?return \{'error': '无法获取虚拟机列表.*?\};", vms_fetch, code, flags=re.DOTALL)

with open('lib/api/unraid_web_client.dart', 'w', encoding='utf-8') as f:
    f.write(code)

with open('lib/screens/vm_view.dart', 'r', encoding='utf-8') as f:
    vcode = f.read()
vcode = re.sub(r"【原生地牢 V.*?】", "【全向雷达 V2.1.3】", vcode)
with open('lib/screens/vm_view.dart', 'w', encoding='utf-8') as f:
    f.write(vcode)

