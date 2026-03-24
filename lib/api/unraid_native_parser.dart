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
      // NOTE: Avoid Dart raw strings here because sequences like \" are not escapes in raw strings.
      final modelMatch = RegExp('var\\s+model\\s*=\\s*[\"\\\']([^\"\\\']+)[\"\\\']').firstMatch(html);
      if (modelMatch != null) cpuModel = modelMatch.group(1)!;

      // Unraid 6.12+ might use ini/json payloads in the html or require update.htm polling.
      // We will leave these as placeholders if not found.
      if (cpuModel == '未知 CPU') {
        // Fallback look for some known hardware strings
        if (html.contains('Intel(R)')) cpuModel = 'Intel Processor';
        else if (html.contains('AMD')) cpuModel = 'AMD Processor';
      }
    } catch (e) {
      // ignore
    }

    return {
      'cpuModel': cpuModel,
      'cpuUsage': cpuUsage,
      'memUsage': memUsage,
      'uptime': uptime,
    };
  }

  /// Parse VM list from Unraid WebGUI dynamic endpoint response.
  ///
  /// In Unraid 7.x, the /VMs page loads the list via:
  ///   GET /plugins/dynamix.vm.manager/include/VMMachines.php
  /// which returns: "<tr ...>...</tr>...\0<script>...</script>"
  ///
  /// Output schema (list item):
  /// { name: String, status: String, running: bool }
  static List<Map<String, dynamic>> parseVms(String payload) {
    final results = <Map<String, dynamic>>[];

    String decode(String s) {
      return s
          .replaceAll('&amp;', '&')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .replaceAll('&quot;', '"')
          .replaceAll('&#39;', "'")
          .trim();
    }

    void addVm(String name, {String status = 'unknown', bool? running}) {
      final n = decode(name);
      if (n.isEmpty) return;
      if (results.any((e) => (e['name'] ?? '') == n)) return;
      final isRunning = running ?? status.toLowerCase().contains('running') || status.toLowerCase().contains('started');
      results.add({'name': n, 'status': status, 'running': isRunning});
    }

    try {
      // Split off the HTML part (before the NUL separator), if present.
      final html = payload.split('\u0000').first;

      // Primary pattern: <td class="vm-name"> ... <a>VMNAME</a>
      final reName = RegExp(
        '<td[^>]*class=["\\\'][^"\\\']*vm-name[^"\\\']*["\\\'][^>]*>[\\s\\S]*?<a[^>]*>([^<]+)</a>',
        caseSensitive: false,
      );
      final matches = reName.allMatches(html).toList();
      for (final m in matches) {
        final name = m.group(1) ?? '';
        // Try to infer running/stopped from nearby markup.
        final start = (m.start - 250) < 0 ? 0 : (m.start - 250);
        final end = (m.end + 250) > html.length ? html.length : (m.end + 250);
        final window = html.substring(start, end).toLowerCase();

        bool? running;
        String status = 'unknown';
        if (window.contains('fa-play-circle') || window.contains('running') || window.contains('started')) {
          running = true;
          status = 'running';
        }
        if (window.contains('fa-stop-circle') || window.contains('stopped') || window.contains('shutdown') || window.contains('shut down')) {
          running = false;
          status = 'stopped';
        }

        addVm(name, status: status, running: running);
      }

      // Fallback: any anchor inside a row that looks like VM config link
      if (results.isEmpty) {
        final reAnyA = RegExp('<tr[^>]*>[\\s\\S]*?<a[^>]*>([^<]{1,80})</a>[\\s\\S]*?</tr>', caseSensitive: false);
        for (final m in reAnyA.allMatches(html)) {
          addVm(m.group(1) ?? '');
        }
      }
    } catch (_) {
      // ignore
    }

    return results;
  }
}

