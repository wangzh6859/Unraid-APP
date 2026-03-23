with open('lib/providers/server_provider.dart', 'r', encoding='utf-8') as f:
    code = f.read()

import re
# Find all occurrences of the fetch block
pattern = r"\s*// Fetch VMs from Native WebGUI\s*final vmResult = await _unraidNative\.getVms\(\);\s*if \(vmResult != null && vmResult\.containsKey\('raw'\)\) \{\s*rawVmResponse = 'Successfully connected to Unraid WebGUI\. Raw data received\.';\s*\} else if \(vmResult != null && vmResult\.containsKey\('error'\)\) \{\s*rawVmResponse = vmResult\['error'\];\s*\}"

matches = list(re.finditer(pattern, code))
if len(matches) > 1:
    # Remove the second match
    m = matches[1]
    code = code[:m.start()] + code[m.end():]

with open('lib/providers/server_provider.dart', 'w', encoding='utf-8') as f:
    f.write(code)
