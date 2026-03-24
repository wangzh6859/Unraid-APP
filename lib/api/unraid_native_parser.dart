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
  /// {
  ///   name: String,
  ///   uuid: String?,
  ///   status: String,
  ///   running: bool,
  ///   cpu: String?,
  ///   mem: String?,
  ///   ip: String?,
  ///   autostart: bool?,
  /// }
  static List<Map<String, dynamic>> parseVms(String payload) {
    final results = <Map<String, dynamic>>[];

    String decode(String s) {
      return s
          .replaceAll('&amp;', '&')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .replaceAll('&quot;', '"')
          .replaceAll('&nbsp;', ' ')
          .replaceAll('&#160;', ' ')
          .replaceAll('\u00A0', ' ')
          .replaceAll('&#39;', "'")
          .trim();
    }

    String stripTags(String s) {
      // Remove tags and condense whitespace.
      final noTags = s.replaceAll(RegExp('<[^>]+>'), ' ');
      return decode(noTags).replaceAll(RegExp(r'\s+'), ' ').trim();
    }

    Map<String, dynamic> ensureVm(String name) {
      final n = decode(name);
      final existing = results.where((e) => (e['name'] ?? '') == n).toList();
      if (existing.isNotEmpty) return existing.first;
      final vm = <String, dynamic>{'name': n, 'status': 'unknown', 'running': false};
      results.add(vm);
      return vm;
    }

    try {
      // Split off the HTML part (before the NUL separator), if present.
      final html = payload.split('\u0000').first;

      // VMMachines.php returns:
      //   <tr parent-id='X' class='sortable'> ... </tr>
      //   <tr child-id='X' id='name-X' style='display:none'> ... nested tables ... </tr>
      // We should ONLY parse the parent rows; child rows contain nested <tr>/<td> which break naive parsing.
      final reParentTr = RegExp(
        "<tr[^>]*\\bparent-id\\s*=\\s*['\"][^'\"]+['\"][^>]*>[\\s\\S]*?</tr>",
        caseSensitive: false,
      );
      for (final trM in reParentTr.allMatches(html)) {
        final tr = trM.group(0) ?? '';

        // Must contain vm-name cell.
        if (!tr.toLowerCase().contains('vm-name')) continue;

        // Name.
        final nameM = RegExp(
          "<td[^>]*class=['\"][^'\"]*vm-name[^'\"]*['\"][^>]*>[\\s\\S]*?<a[^>]*>([^<]+)</a>",
          caseSensitive: false,
        ).firstMatch(tr);
        final name = nameM?.group(1) ?? '';
        if (decode(name).isEmpty) continue;

        final vm = ensureVm(name);

        // UUID often appears on elements as uuid="...".
        final uuidM = RegExp("uuid=['\"]([^'\"]+)['\"]", caseSensitive: false).firstMatch(tr);
        if (uuidM != null) vm['uuid'] = uuidM.group(1);

        // Status / running inference: icons used by Unraid.
        final trLower = tr.toLowerCase();
        if (trLower.contains('fa-play-circle') || trLower.contains('running') || trLower.contains('started')) {
          vm['running'] = true;
          vm['status'] = 'running';
        }
        if (trLower.contains('fa-stop-circle') || trLower.contains('stopped') || trLower.contains('shutdown') || trLower.contains('shut down')) {
          vm['running'] = false;
          vm['status'] = 'stopped';
        }

        // Collect all <td> cells text to map columns (best effort).
        final tds = RegExp('<td[^>]*>([\\s\\S]*?)</td>', caseSensitive: false)
            .allMatches(tr)
            .map((m) => stripTags(m.group(1) ?? ''))
            .where((s) => s.isNotEmpty)
            .toList();

        // Heuristic mapping by table header order in your /VMs page:
        // 名称 | 描述 | CPU | 内存 | 虚拟硬盘/光驱 | 图形 | IP 地址 | 自动启动
        // Name cell is first; CPU is around index 2; mem around index 3; ip around index 6.
        if (tds.length >= 4) {
          if (tds.length > 2) vm['cpu'] = tds[2];
          if (tds.length > 3) vm['mem'] = tds[3];
        }
        if (tds.length >= 7) {
          vm['ip'] = tds[6];
        }

        // Autostart: search for class="autostart" input checked.
        final autoM = RegExp("<input[^>]*class=['\"][^'\"]*autostart[^'\"]*['\"][^>]*>", caseSensitive: false).firstMatch(tr);
        if (autoM != null) {
          final input = autoM.group(0) ?? '';
          vm['autostart'] = RegExp('checked', caseSensitive: false).hasMatch(input);
        }
      }

      // If still empty, fallback: parse any row that contains vm-name (loose).
      if (results.isEmpty) {
        final reLoose = RegExp(
          "<tr[^>]*>[\\s\\S]*?<td[^>]*class=['\"][^'\"]*vm-name[^'\"]*['\"][^>]*>[\\s\\S]*?<a[^>]*>([^<]{1,80})</a>[\\s\\S]*?</tr>",
          caseSensitive: false,
        );
        for (final m in reLoose.allMatches(html)) {
          final n = decode(m.group(1) ?? '');
          if (n.isNotEmpty) results.add({'name': n, 'status': 'unknown', 'running': false});
        }
      }
    } catch (_) {
      // ignore
    }

    return results;
  }

  /// Best-effort parsing of Unraid Docker list HTML/JSON.
  ///
  /// Output schema (list item):
  /// { id: String?, name: String, status: String, running: bool, image: String? }
  static List<Map<String, dynamic>> parseDockerContainers(String payload) {
    final results = <Map<String, dynamic>>[];

    String decode(String s) {
      return s
          .replaceAll('&amp;', '&')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .replaceAll('&quot;', '"')
          .replaceAll('&nbsp;', ' ')
          .replaceAll('&#160;', ' ')
          .replaceAll('\u00A0', ' ')
          .replaceAll('&#39;', "'")
          .trim();
    }

    String stripTags(String s) {
      final noTags = s.replaceAll(RegExp('<[^>]+>'), ' ');
      return decode(noTags).replaceAll(RegExp(r'\s+'), ' ').trim();
    }

    void addOne({String? id, required String name, String status = 'unknown', bool? running, bool? autostart, String? image, String? template, String? hash, String? iconPath}) {
      final n = decode(name);
      if (n.isEmpty) return;
      if (results.any((e) => (e['name'] ?? '') == n)) return;
      final isRunning = running ?? status.toLowerCase().contains('up') || status.toLowerCase().contains('running') || status.contains('已启动');
      results.add({
        'id': id,
        'name': n,
        'status': status,
        'running': isRunning,
        'autostart': autostart,
        'image': image,
        'template': template,
        'hash': hash,
        'iconPath': iconPath,
      });
    }

    try {
      final html = payload.split('\u0000').first;

      // Unraid Docker list rows look like:
      // <tr class='sortable'>
      //   <td class='ct-name'> ... <span class='appname'>NAME</span> ... <span class='state'>已启动</span> ...
      //   ... <input class='autostart' container='NAME' checked>
      // </tr>
      final reRow = RegExp("<tr[^>]*class=['\"][^'\"]*sortable[^'\"]*['\"][^>]*>[\\s\\S]*?</tr>", caseSensitive: false);
      for (final m in reRow.allMatches(html)) {
        final tr = m.group(0) ?? '';
        if (!tr.toLowerCase().contains("ct-name")) continue;

        // Container id: first <span id='...'> inside the name cell.
        String? id;
        final idM = RegExp("<span[^>]*\\bid=['\"]([^'\"]+)['\"]", caseSensitive: false).firstMatch(tr);
        if (idM != null) id = decode(idM.group(1) ?? '');

        // Icon path: <img src='/state/plugins/...png?...'>
        String? iconPath;
        final iconM = RegExp("<img[^>]*\\bsrc=['\"]([^'\"]+)['\"]", caseSensitive: false).firstMatch(tr);
        if (iconM != null) {
          final p = decode(iconM.group(1) ?? '');
          if (p.startsWith('/')) iconPath = p;
        }

        // Name: authoritative source is the autostart input: container='NAME'
        String name = '';
        final containerAttrM = RegExp("<input[^>]*class=['\"][^'\"]*autostart[^'\"]*['\"][^>]*\\bcontainer=['\"]([^'\"]+)['\"]", caseSensitive: false).firstMatch(tr);
        if (containerAttrM != null) name = decode(containerAttrM.group(1) ?? '');

        // Fallback 1: <span class='appname'> ... </span> (strip tags inside)
        if (name.isEmpty) {
          final appSpanM = RegExp("<span[^>]*class=['\"][^'\"]*appname[^'\"]*['\"][^>]*>([\\s\\S]*?)</span>", caseSensitive: false).firstMatch(tr);
          if (appSpanM != null) name = stripTags(appSpanM.group(1) ?? '');
        }

        // Fallback 2: addDockerContainerContext('NAME', ...)
        if (name.isEmpty) {
          final nameM2 = RegExp("addDockerContainerContext\\('([^']+)'", caseSensitive: false).firstMatch(tr);
          if (nameM2 != null) name = decode(nameM2.group(1) ?? '');
        }

        // Last guard: if we still somehow grabbed an image-like name (contains '/'), ignore and continue.
        if (name.isEmpty || name.contains('/')) continue;

        // Status text: <span class='state'>已启动</span>
        String status = 'unknown';
        final stM = RegExp("<span[^>]*class=['\"][^'\"]*state[^'\"]*['\"][^>]*>([\\s\\S]*?)</span>", caseSensitive: false).firstMatch(tr);
        if (stM != null) status = stripTags(stM.group(1) ?? 'unknown');

        // Running: icon class started/stopped
        bool? running;
        final low = tr.toLowerCase();
        if (low.contains('started') || status.contains('已启动')) running = true;
        if (low.contains('stopped') || status.contains('已停止')) running = false;

        // Autostart checkbox
        bool? autostart;
        final asM = RegExp("<input[^>]*class=['\"][^'\"]*autostart[^'\"]*['\"][^>]*>", caseSensitive: false).firstMatch(tr);
        if (asM != null) {
          final input = asM.group(0) ?? '';
          autostart = RegExp('checked', caseSensitive: false).hasMatch(input);
        }

        // Extract addDockerContainerContext('NAME','hash','TEMPLATE',...)
        String? template;
        String? hash;
        final ctxM = RegExp("addDockerContainerContext\\('([^']*)','([^']*)','([^']*)'", caseSensitive: false).firstMatch(tr);
        if (ctxM != null) {
          hash = decode(ctxM.group(2) ?? '');
          template = decode(ctxM.group(3) ?? '');
        }

        // Image: inside advanced "来自:" link
        String? image;
        final imgM = RegExp("来自:\\s*<a[^>]*>([^<]+)</a>", caseSensitive: false).firstMatch(tr);
        if (imgM != null) image = decode(imgM.group(1) ?? '');

        addOne(id: id, name: name, status: status, running: running, autostart: autostart, image: image, template: template, hash: hash, iconPath: iconPath);
      }

      // Fallback: previous heuristic (very loose)
      if (results.isEmpty) {
        final reAnyA = RegExp('<a[^>]*>([^<]{1,120})</a>', caseSensitive: false);
        for (final mm in reAnyA.allMatches(html)) {
          final n = decode(mm.group(1) ?? '');
          if (n.isNotEmpty) addOne(name: n);
        }
      }
    } catch (_) {
      // ignore
    }

    return results;
  }
}


