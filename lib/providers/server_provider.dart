import 'dart:async';
import 'package:flutter/material.dart';
import '../api/portainer_client.dart';
import '../api/unraid_web_client.dart';
import '../api/unraid_native_parser.dart';

class ServerProvider extends ChangeNotifier {
  ServerProvider() {
    startAutoRefresh();
  }
  
  final PortainerClient _portainer = PortainerClient();
  final UnraidWebClient _unraidNative = UnraidWebClient();
  
  bool isLoading = false;
  bool get isConnected => errorMsg.isEmpty && cpuModel != '未知 CPU';
  String errorMsg = '';
  
  // Dashboard stats
  String cpuModel = '未知 CPU';
  String cpuUsage = '0.0%';
  String memUsage = '0.0%';
  String totalMem = '0 GB';
  String cpuTemp = 'N/A';
  String uptime = '未知';
  String gpuUsage = 'N/A';
  String gpuTemp = 'N/A';
  
  // Lists
  List<dynamic> dockerContainers = [];
  String rawDockerResponse = '';
  String rawDockerHtmlPreview = '';
  List<dynamic> vms = [];
  String rawVmResponse = '正在执行抓取...';
  String rawVmHtmlPreview = '';

  Timer? _timer;

  void startAutoRefresh() {
    _timer?.cancel();
    _fetchStatsSilent(); // immediate first fetch
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      _fetchStatsSilent();
    });
  }

  Future<void> fetchStats() async {
    isLoading = true;
    notifyListeners();
    await _fetchStatsSilent();
  }

  Future<void> _fetchStatsSilent() async {
    // 1. Fetch native Unraid dashboard
    final dashResult = await _unraidNative.getDashboardStats();
    if (dashResult != null && dashResult.containsKey('error')) {
      errorMsg = dashResult['error'];
    } else if (dashResult != null && dashResult.containsKey('data')) {
      errorMsg = ''; rawVmResponse = 'Token: ${_unraidNative.getCsrfToken()}\n\n';
      _parseNativeDashboard(dashResult['data']);
    }

    // 2. Fetch VMs from native (/VMs)
    final vmResult = await _unraidNative.getVms();
    if (vmResult != null && vmResult.containsKey('error')) {
      rawVmResponse = vmResult['error'];
      vms = [];
    } else if (vmResult != null && vmResult.containsKey('data')) {
      rawVmResponse = vmResult['data'].toString();
      if (vmResult.containsKey('raw')) {
        final rawPayload = vmResult['raw']?.toString() ?? '';
        // Keep a preview for user-assisted debugging.
        rawVmHtmlPreview = rawPayload.length > 8000 ? rawPayload.substring(0, 8000) : rawPayload;

        final parsed = UnraidNativeParser.parseVms(rawPayload);
        vms = parsed;
        if (parsed.isEmpty) {
          rawVmResponse += "\n\n[解析提示] 未能从 /VMs HTML 解析出 VM 列表（可能是版本差异）。\n你可以在本页点击【复制/VMs源码(前8KB)】发给我，我来增强解析器。\n";
        }
      }
    }

    // 3. Docker list: prefer Unraid native, fallback to Portainer
    bool dockerOk = false;
    final nativeDocker = await _unraidNative.getDockerContainers();
    if (nativeDocker != null && nativeDocker.containsKey('error')) {
      rawDockerResponse = nativeDocker['error'];
    } else if (nativeDocker != null && nativeDocker.containsKey('data')) {
      rawDockerResponse = nativeDocker['data'].toString();
      if (nativeDocker.containsKey('raw')) {
        final rawPayload = nativeDocker['raw']?.toString() ?? '';
        rawDockerHtmlPreview = rawPayload.length > 8000 ? rawPayload.substring(0, 8000) : rawPayload;
        final parsed = UnraidNativeParser.parseDockerContainers(rawPayload);
        if (parsed.isNotEmpty) {
          dockerContainers = parsed;
          dockerOk = true;
          rawDockerResponse += "\n[解析] Native Docker 容器数量: ${parsed.length}";
        } else {
          rawDockerResponse += "\n[解析提示] 未能从 Native Docker 响应解析出容器列表，将回退 Portainer。";
        }
      }
    }

    if (!dockerOk) {
      final dockerResult = await _portainer.getContainers();
      if (dockerResult != null && dockerResult.containsKey('data')) {
        final cData = dockerResult['data'];
        if (cData is List) {
          dockerContainers = cData;
          rawDockerResponse = 'Fallback: Connected to Portainer';
        }
      }
    }

    isLoading = false;
    notifyListeners();
  }

  void _parseNativeDashboard(String html) {
    // Basic regex to find some stats. Unraid GUI is tricky.
    // Memory is usually in a var like `var memory = ...` or in html.
    // For now, let's just show it's connected.
    cpuModel = 'Unraid Native (Connected)';
    cpuUsage = 'API 切换中';
    memUsage = 'API 切换中';
    uptime = '原生连接成功';
  }

  Future<bool> controlContainer(String containerId, String action) async {
     bool success = await _portainer.containerAction(containerId, action);
     if (success) {
       await fetchStats(); 
     }
     return success;
  }

  Future<bool> controlDocker(dynamic container, String action) async {
    // Prefer Unraid native by name if available; fallback to Portainer by Id.
    String name = '';
    String portainerId = '';

    try {
      if (container is Map) {
        if (container['name'] != null) name = container['name'].toString();
        if (container['Names'] != null && container['Names'] is List && container['Names'].isNotEmpty) {
          name = container['Names'][0].toString().replaceAll('/', '');
        }
        portainerId = (container['Id'] ?? container['id'] ?? '').toString();
      }
    } catch (_) {}

    // Try native action first.
    if (name.isNotEmpty) {
      final nativeId = (container is Map ? (container['id'] ?? container['Id'] ?? '') : '').toString();
      final native = await _unraidNative.dockerAction(name: name, id: nativeId, action: action);
      if (!native.containsKey('error')) {
        rawDockerResponse = 'Native Docker action sent: $action ($name)\nHTTP ${native['status']} (attempt ${native['attempt'] ?? '?'})';
        notifyListeners();
        await fetchStats();
        return true;
      } else {
        rawDockerResponse = 'Native Docker action failed: ${native['error']}\nHTTP ${native['status'] ?? ''} (attempt ${native['attempt'] ?? ''})\nWill fallback to Portainer if possible.';
        notifyListeners();
      }
    }

    // Fallback to Portainer if we have container id.
    if (portainerId.isNotEmpty) {
      final ok = await _portainer.containerAction(portainerId, action);
      if (ok) {
        rawDockerResponse = 'Fallback Portainer action ok: $action ($portainerId)';
        notifyListeners();
        await fetchStats();
      }
      return ok;
    }

    rawDockerResponse = '无法操作：缺少容器标识（name/Id）';
    notifyListeners();
    return false;
  }

  Future<bool> controlVm(String uuid, String action) async {
    // action: start | stop | restart | force-stop
    String apiAction;
    switch (action) {
      case 'start':
        apiAction = 'domain-start';
        break;
      case 'stop':
        apiAction = 'domain-stop';
        break;
      case 'restart':
        apiAction = 'domain-restart';
        break;
      case 'force-stop':
        apiAction = 'domain-force-stop';
        break;
      default:
        apiAction = action;
    }

    final res = await _unraidNative.vmAction(uuid, apiAction);
    if (res.containsKey('error')) {
      rawVmResponse = res['error'];
      notifyListeners();
      return false;
    }

    // Short-poll VM list to reflect state change quickly (1s interval).
    // This avoids waiting for the global 5s timer.
    final before = vms.where((e) => (e['uuid'] ?? '') == uuid).toList();
    final beforeRunning = before.isNotEmpty ? (before.first['running'] == true) : null;

    for (int i = 1; i <= 10; i++) {
      rawVmResponse = '已发送操作: $action (uuid=$uuid)\n正在刷新状态... $i/10';
      notifyListeners();

      await Future.delayed(const Duration(seconds: 1));

      final vmResult = await _unraidNative.getVms();
      if (vmResult != null && vmResult.containsKey('data')) {
        rawVmResponse = vmResult['data'].toString();
        if (vmResult.containsKey('raw')) {
          final rawPayload = vmResult['raw']?.toString() ?? '';
          rawVmHtmlPreview = rawPayload.length > 8000 ? rawPayload.substring(0, 8000) : rawPayload;
          final parsed = UnraidNativeParser.parseVms(rawPayload);
          vms = parsed;

          final after = vms.where((e) => (e['uuid'] ?? '') == uuid).toList();
          final afterRunning = after.isNotEmpty ? (after.first['running'] == true) : null;

          // If we can observe a change, stop polling early.
          if (beforeRunning != null && afterRunning != null && beforeRunning != afterRunning) {
            break;
          }

          // For restart, we may not see running flip; just continue until list updates.
        }
      }
    }

    notifyListeners();
    return true;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
