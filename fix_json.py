import re

with open('lib/api/unraid_client.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Fix the getServerStats method
new_method = """
  // 获取 CPU 等统计信息
  Future<Map<String, dynamic>?> getServerStats() async {
    try {
      await init();
      if (baseUrl == null || baseUrl!.isEmpty) return null;

      final response = await _dio.get('/api/system');
      
      // 容错处理: 有时服务器没返回 application/json，Dio 会把它当 String 处理
      if (response.data is String) {
        try {
          import 'dart:convert';
          return jsonDecode(response.data) as Map<String, dynamic>;
        } catch (_) {
          return {'error': '收到非 JSON 数据: ${response.data.toString().substring(0, 30)}...'};
        }
      }
      
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      
      return {'error': '未知的数据格式'};
      
    } on DioException catch (e) {
      print('HTTP Request failed: ${e.message}');
      return {'error': e.message ?? e.toString()};
    } catch (e) {
      print('Unknown Error: $e');
      return {'error': e.toString()};
    }
  }
"""

# We need to make sure 'dart:convert' is imported at the top
if "import 'dart:convert';" not in code:
    code = "import 'dart:convert';\n" + code

# Replace the method. The regex must carefully match the exact block.
pattern = r"// 获取 CPU 等统计信息\s*Future<Map<String, dynamic>\?> getServerStats\(\) async \{.*?\n  \}"
code = re.sub(pattern, new_method.strip(), code, flags=re.DOTALL)

with open('lib/api/unraid_client.dart', 'w', encoding='utf-8') as f:
    f.write(code)
