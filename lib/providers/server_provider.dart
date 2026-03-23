import 'dart:async';
import 'package:flutter/material.dart';
import '../api/glances_client.dart';
import '../api/portainer_client.dart';
import '../api/unraid_web_client.dart';

class ServerProvider extends ChangeNotifier {
  ServerProvider() {
    startAutoRefresh();
  }
  final GlancesClient _api = GlancesClient();
  final PortainerClient _portainer = PortainerClient();
  final UnraidWebClient _unraidNative = UnraidWebClient();
  
  bool isLoading = false;
  bool get isConnected => errorMsg.isEmpty && cpuModel != '未知 CPU';
  String errorMsg = '';
  
  // Dashboard stats
  String cpuModel = '未知 CPU';
  String uptime = '0天 0小时';
  int cpuUsage = 0;
  int memUsage = 0;
  String cpuTemp = 'N/A';
  String gpuTemp = 'N/A';
  String gpuUsage = 'N/A';
  
  // Docker stats
  List<dynamic> dockerContainers = [];
  List<dynamic> vms = [];
  String rawVmResponse = '';
  String rawDockerResponse = '';

  Timer? _refreshTimer;

  void startAutoRefresh() {
    fetchStats();
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _fetchStatsSilent();
    });
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
  }

  Future<void> fetchStats() async {
    isLoading = true;
    errorMsg = '';
    notifyListeners();
    await _fetchStatsSilent();
  }

  Future<void> _fetchStatsSilent() async {
    final result = await _api.getServerStats();
    
    if (result != null) {
      if (result.containsKey('error')) {
         errorMsg = result['error'];
      } else {
         final data = result['data'];
         if (data != null) {
           _parseData(data);
         }
      }
    } else {
       errorMsg = '无法连接到 Glances 服务器';
    }
    
    // Fetch Docker containers from Portainer
    final dockerResult = await _portainer.getContainers();
    if (dockerResult != null) {
      if (dockerResult.containsKey('error')) {
         rawDockerResponse = dockerResult['error'];
         // Fallback to Glances data if portainer fails
      } else {
         final cData = dockerResult['data'];
         if (cData != null && cData is List) {
           dockerContainers = cData;
           rawDockerResponse = 'Connected to Portainer: ${cData.length} containers found.';
         }
      }
    }
    
    
    // Fetch VMs from Native WebGUI
    final vmResult = await _unraidNative.getVms();
    if (vmResult != null && vmResult.containsKey('raw')) {
       rawVmResponse = 'Successfully connected to Unraid WebGUI. Raw data received.';
       // We will need to parse the raw html/json later.
    } else if (vmResult != null && vmResult.containsKey('error')) {
       rawVmResponse = vmResult['error'];
    }


    // Fetch VMs from Native WebGUI
    final vmResult = await _unraidNative.getVms();
    if (vmResult != null && vmResult.containsKey('raw')) {
       rawVmResponse = 'Successfully connected to Unraid WebGUI. Raw data received.';
    } else if (vmResult != null && vmResult.containsKey('error')) {
       rawVmResponse = vmResult['error'];
    }
    isLoading = false;
    notifyListeners();
  }
  
  Future<bool> controlContainer(String containerId, String action) async {
     bool success = await _portainer.containerAction(containerId, action);
     if (success) {
       await fetchStats(); // Refresh immediately after action
     }
     return success;
  }

  void _parseData(Map<String, dynamic> data) {
    if (data['quicklook'] != null && data['quicklook']['cpu_name'] != null) {
       cpuModel = data['quicklook']['cpu_name'];
    } else if (data['system'] != null) {
       cpuModel = data['system']['hostname'] ?? 'Unraid Server';
    }
    
    if (data['uptime'] != null) {
      List<String> parts = data['uptime'].toString().split(':');
      if (parts.length >= 2) {
         uptime = '${parts[0]}小时 ${parts[1]}分钟';
         if (data['uptime'].toString().contains('day')) {
            uptime = data['uptime'].toString().split(',')[0] + ' ' + parts[0] + '小时';
         }
      } else {
         uptime = data['uptime'].toString();
      }
    }
    
    if (data['cpu'] != null && data['cpu']['total'] != null) {
      cpuUsage = (data['cpu']['total'] as num).toInt();
    }
    
    if (data['mem'] != null && data['mem']['percent'] != null) {
      memUsage = (data['mem']['percent'] as num).toInt();
    }
    
    if (data['sensors'] != null) {
       bool foundTemp = false;
       for (var sensor in data['sensors']) {
         String label = sensor['label']?.toString().toLowerCase() ?? '';
         if (label.contains('cpu') || label.contains('core') || label.contains('package') || label.contains('k10temp') || label.contains('temp1')) {
            cpuTemp = '${sensor['value']}°C';
            foundTemp = true;
            break;
         }
       }
       // Fallback for some boards where CPU temp is just the first sensor if unnamed
       if (!foundTemp && data['sensors'].isNotEmpty) {
           cpuTemp = '${data['sensors'][0]['value']}°C';
       }
    }
    
    if (data['gpu'] != null && data['gpu'] is List && data['gpu'].isNotEmpty) {
      var gpu = data['gpu'][0];
      if (gpu['temperature'] != null) {
         gpuTemp = '${gpu['temperature']}°C';
      }
      if (gpu['proc'] != null) {
         gpuUsage = '${gpu['proc']}%';
      } else if (gpu['mem'] != null) {
         gpuUsage = '${gpu['mem']}%';
      }
    }

            // Parse Docker Containers
    if (data['containers'] != null) {
       rawDockerResponse = 'Found containers array';
       if (data['containers'] is List) {
         dockerContainers = data['containers'];
         dockerContainers.sort((a, b) {
           String statusA = a['status']?.toString().toLowerCase() ?? '';
           String statusB = b['status']?.toString().toLowerCase() ?? '';
           // Usually running, healthy, up, etc.
           bool isRunningA = statusA.contains('running') || statusA.contains('healthy') || statusA.contains('up');
           bool isRunningB = statusB.contains('running') || statusB.contains('healthy') || statusB.contains('up');
           if (isRunningA && !isRunningB) return -1;
           if (isRunningB && !isRunningA) return 1;
           return 0;
         });
       }
    } else if (data['docker'] != null) {
       rawDockerResponse = 'Found docker object';
       if (data['docker']['containers'] != null) {
         dockerContainers = data['docker']['containers'];
         dockerContainers.sort((a, b) {
           String statusA = a['Status'] ?? a['status'] ?? '';
           String statusB = b['Status'] ?? b['status'] ?? '';
           if (statusA.toLowerCase() == 'running' && statusB.toLowerCase() != 'running') return -1;
           if (statusB.toLowerCase() == 'running' && statusA.toLowerCase() != 'running') return 1;
           return 0;
         });
       } else if (data['docker'] is List) {
         dockerContainers = data['docker'];
       }
    } else {
       dockerContainers = [];
       rawDockerResponse = '未在响应中找到 containers 节点。您可能需要开启 Glances 容器插件。';
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
