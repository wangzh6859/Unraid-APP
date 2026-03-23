with open('lib/providers/server_provider.dart', 'r', encoding='utf-8') as f:
    code = f.read()

import re
# We just rename the second one to vmResult2
# Wait, it's easier to just split by `final vmResult =`
parts = code.split('final vmResult = await _unraidNative.getVms();')
if len(parts) > 2:
    # Means there are at least two occurrences.
    # We will simply keep the first occurrence of the entire block and delete the second.
    # Let's do it manually.
    pass

# Or just read lines and remove lines 98 to 105
lines = code.split('\n')
new_lines = []
skip = False
count_vm = 0
for l in lines:
    if 'final vmResult = await _unraidNative.getVms();' in l:
        count_vm += 1
        if count_vm > 1:
            skip = True
            
    if skip:
        if 'rawVmResponse = vmResult[\'error\'];' in l:
            skip = False
            continue # skip the closing brace next line maybe?
            
        if '}' in l and 'else' not in l: # Very risky line-based skipping
            pass

    # A better way is to just find the exact duplicate string and replace it with nothing.
    
