import re

with open('lib/providers/server_provider.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# I removed `gpuUsage` and `gpuTemp` from ServerProvider but `main.dart` is still using them in DashboardView.
# I need to put them back into ServerProvider with default values.

missing_vars = """
  String gpuUsage = 'N/A';
  String gpuTemp = 'N/A';
"""

code = code.replace("String uptime = '未知';", "String uptime = '未知';" + missing_vars)

# Also `memUsage` in main.dart: `serverProvider.memUsage / 100.0`
# In Glances, `memUsage` was a double or int. 
# But in my new native code, I made `String memUsage = '0.0%';` !!
# Oh my god. `serverProvider.memUsage / 100.0` will fail if memUsage is a String.
# I need to change `memUsage` to a `double`, OR change main.dart.
# Let's change `ServerProvider` memUsage back to `double`?
# Wait, let's see how main.dart uses it.

