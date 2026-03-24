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
      final modelMatch = RegExp(r"var\s+model\s*=\s*[\"']([^\"']+)[\"']").firstMatch(html);
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

  /// Best-effort parsing of Unraid WebGUI /VMs HTML.
  ///
  /// Output schema (list item):
  /// { name: String, status: String, running: bool }
  ///
  /// This parser is intentionally heuristic because Unraid's WebGUI markup changes across versions.
  static List<Map<String, dynamic>> parseVms(String html) {
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
      // Pattern A: JS payload like name:"xxx" state:"RUNNING" / status:"running"
      final reJs = RegExp(
        r"name\s*[:=]\s*[\"']([^\"']+)[\"'][^\n]{0,200}?(?:state|status)\s*[:=]\s*[\"']([^\"']+)[\"']",
        caseSensitive: false,
      );
      for (final m in reJs.allMatches(html)) {
        addVm(m.group(1) ?? '', status: (m.group(2) ?? 'unknown'));
      }

      // Pattern B: table row with data-name or data-vm
      final reDataAttr = RegExp(r"data-(?:vm|name)=[\"']([^\"']+)[\"']", caseSensitive: false);
      for (final m in reDataAttr.allMatches(html)) {
        addVm(m.group(1) ?? '');
      }

      // Pattern C: common HTML: <td class="...name...">VMNAME</td>
      final reTdName = RegExp(r"<td[^>]*class=[\"'][^\"']*(?:name|vmname)[^\"']*[\"'][^>]*>([^<]{1,80})</td>", caseSensitive: false);
      for (final m in reTdName.allMatches(html)) {
        addVm(m.group(1) ?? '');
      }

      // Pattern D: links: /VMs/<name> or onclick with vm name
      final reLink = RegExp(r"/VMs\?[^\"']*name=([^&\"']+)", caseSensitive: false);
      for (final m in reLink.allMatches(html)) {
        addVm(Uri.decodeComponent(m.group(1) ?? ''));
      }

      // Try to infer running status if markup includes "running" near the VM name.
      // (Very heuristic, but better than nothing.)
      for (final vm in results) {
        final name = (vm['name'] ?? '').toString();
        if (name.isEmpty) continue;
        final idx = html.toLowerCase().indexOf(name.toLowerCase());
        if (idx >= 0) {
          final start = (idx - 200) < 0 ? 0 : (idx - 200);
          final end = (idx + 200) > html.length ? html.length : (idx + 200);
          final window = html.substring(start, end).toLowerCase();
          if (window.contains('running') || window.contains('started') || window.contains('up')) {
            vm['running'] = true;
            if ((vm['status'] ?? 'unknown') == 'unknown') vm['status'] = 'running';
          }
          if (window.contains('stopped') || window.contains('shutdown') || window.contains('shut down')) {
            vm['running'] = false;
            if ((vm['status'] ?? 'unknown') == 'unknown') vm['status'] = 'stopped';
          }
        }
      }
    } catch (_) {
      // ignore
    }

    return results;
  }
}
