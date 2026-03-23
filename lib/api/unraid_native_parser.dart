class UnraidNativeParser {
  static Map<String, dynamic> parseDashboard(String html) {
    // Unraid puts a lot of info in JS variables like `var memory = ...`
    // Let's do some basic regex that won't throw exceptions.
    String cpuModel = '未知 CPU';
    String cpuUsage = '0.0%';
    String memUsage = '0.0%';
    String uptime = '未知';

    try {
      // Look for var model = "Intel(R) Core(TM) i5...";
      final modelMatch = RegExp(r'var\s+model\s*=\s*["\']([^"\']+)["\']').firstMatch(html);
      if (modelMatch != null) cpuModel = modelMatch.group(1)!;

      // Unraid 6.12+ might use ini/json payloads in the html or require update.htm polling.
      // We will leave these as placeholders if not found.
      if (cpuModel == '未知 CPU') {
         // Fallback look for some known hardware strings
         if (html.contains('Intel(R)')) cpuModel = 'Intel Processor';
         else if (html.contains('AMD')) cpuModel = 'AMD Processor';
      }
    } catch (e) {
      print('Parser error: $e');
    }

    return {
      'cpuModel': cpuModel,
      'cpuUsage': cpuUsage,
      'memUsage': memUsage,
      'uptime': uptime,
    };
  }

  static List<dynamic> parseVms(String data) {
    // Return empty list until we can safely parse the exact XML/JSON/HTML of the VMs page
    return [];
  }
}
