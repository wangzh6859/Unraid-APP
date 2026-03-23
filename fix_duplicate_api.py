import re

with open('lib/providers/server_provider.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# We have `final GlancesClient _api = GlancesClient();` twice. 
# Let's replace the first one and any subsequent ones, so only one remains.
code = code.replace("final GlancesClient _api = GlancesClient();", "", 1) # remove the first one

with open('lib/providers/server_provider.dart', 'w', encoding='utf-8') as f:
    f.write(code)

