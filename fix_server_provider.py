import re
with open('lib/providers/server_provider.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Fix Timer logic: Just make it start on init of the Provider, no need to call it from View
if "ServerProvider() {" not in code:
    code = code.replace("class ServerProvider extends ChangeNotifier {", "class ServerProvider extends ChangeNotifier {\n  ServerProvider() {\n    startAutoRefresh();\n  }")

# Fix CPU temp. Glances `sensors` might be empty or labeled differently.
# If sensors is empty, we leave it 'N/A'
temp_fix = """    if (data['sensors'] != null) {
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
    }"""
code = re.sub(r"    if \(data\['sensors'\] != null\) \{.*?\n    \}", temp_fix, code, flags=re.DOTALL)

with open('lib/providers/server_provider.dart', 'w', encoding='utf-8') as f:
    f.write(code)
