with open('lib/providers/server_provider.dart', 'r', encoding='utf-8') as f:
    code = f.read()

import re
# Search for block
block = """    // Fetch VMs from Native WebGUI
    final vmResult = await _unraidNative.getVms();
    if (vmResult != null && vmResult.containsKey('raw')) {
       rawVmResponse = 'Successfully connected to Unraid WebGUI. Raw data received.';
    } else if (vmResult != null && vmResult.containsKey('error')) {
       rawVmResponse = vmResult['error'];
    }"""

# Count occurrences
count = code.count(block)
if count > 1:
    # Replace the FIRST occurrence with nothing
    code = code.replace(block, "", 1)

with open('lib/providers/server_provider.dart', 'w', encoding='utf-8') as f:
    f.write(code)
