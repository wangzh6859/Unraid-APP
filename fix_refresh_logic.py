import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Add auto-refresh start in DashboardView initState
# Check if DashboardView is a StatefulWidget. 
if "class DashboardView extends StatelessWidget" in code:
    print("Converting DashboardView to StatefulWidget to enable auto-refresh")
    old_dashboard = """class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {"""
    new_dashboard = """class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServerProvider>().startAutoRefresh();
    });
  }

  @override
  void dispose() {
    // We don't want to stop it if we just navigate away briefly, but good practice.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {"""
    code = code.replace(old_dashboard, new_dashboard)

# As for Docker empty... 
# The issue might be that Glances isn't returning docker in `/api/3/all`.
# Or it's returning it under a different key, or Docker plugin is disabled in Glances.
# Let's add a raw JSON output debug dump for Docker containers so the user can see what's actually coming from the API!
# Also, let's fix the empty check to be more lenient.

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

with open('lib/providers/server_provider.dart', 'r', encoding='utf-8') as f:
    server_code = f.read()

# Add a `rawDockerResponse` string to show on the UI if empty
if "String rawDockerResponse" not in server_code:
    server_code = server_code.replace("List<dynamic> dockerContainers = [];", "List<dynamic> dockerContainers = [];\n  String rawDockerResponse = '';")
    
    # Inside _parseData
    parse_docker = """    // Parse Docker Containers
    if (data['docker'] != null) {
       rawDockerResponse = data['docker'].toString();
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
       rawDockerResponse = '未在 Glances API 响应中找到 docker 节点。请确保您已在宿主机开启 Docker，且 Glances 已安装 Docker 监控依赖 (如 pip install docker)。';
    }"""
    
    server_code = re.sub(r"// Parse Docker Containers.*?\} else \{.*?\}", parse_docker, server_code, flags=re.DOTALL)
    
    with open('lib/providers/server_provider.dart', 'w', encoding='utf-8') as f:
        f.write(server_code)

