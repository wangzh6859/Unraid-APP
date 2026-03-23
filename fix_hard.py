import re

with open('lib/providers/server_provider.dart', 'r') as f:
    code = f.read()

# I want to find the LAST occurrence of `final vmResult =` and rename it.
idx = code.rfind('final vmResult = await _unraidNative.getVms();')
if idx != -1:
    end_idx = code.find('rawVmResponse = vmResult[\'error\'];', idx) + len('rawVmResponse = vmResult[\'error\'];') + 10
    
    bad_block = code[idx:end_idx]
    good_block = bad_block.replace('vmResult', 'vmResult2')
    
    code = code[:idx] + good_block + code[end_idx:]
    
with open('lib/providers/server_provider.dart', 'w') as f:
    f.write(code)

