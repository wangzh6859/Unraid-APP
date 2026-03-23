import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# I want to add a helper function to determine Docker icons based on container name
icon_helper = """IconData _getDockerIcon(String name) {
    name = name.toLowerCase();
    if (name.contains('nginx') || name.contains('proxy') || name.contains('swag')) return Icons.public;
    if (name.contains('sql') || name.contains('db') || name.contains('redis') || name.contains('mongo') || name.contains('mariadb')) return Icons.storage;
    if (name.contains('emby') || name.contains('jellyfin') || name.contains('plex')) return Icons.movie_creation;
    if (name.contains('qbittorrent') || name.contains('transmission') || name.contains('aria2') || name.contains('download')) return Icons.cloud_download;
    if (name.contains('alist') || name.contains('nextcloud') || name.contains('cloud')) return Icons.cloud;
    if (name.contains('homeassistant') || name.contains('ha')) return Icons.home;
    if (name.contains('openclaw') || name.contains('bot') || name.contains('ai')) return Icons.smart_toy;
    if (name.contains('portainer')) return Icons.dashboard;
    return Icons.view_in_ar_rounded;
  }"""

# Insert it before _DockerViewState
code = code.replace("class _DockerViewState extends State<DockerView> {", icon_helper + "\n\nclass _DockerViewState extends State<DockerView> {")

# Then replace the icon inside the leading container
code = code.replace("Icons.view_in_ar_rounded", "_getDockerIcon(name)")

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

