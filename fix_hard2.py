import re

with open('lib/providers/server_provider.dart', 'r') as f:
    code = f.read()

idx = code.rfind('final vmResult = await _unraidNative.getVms();')
if idx != -1:
    end_idx = code.find('}', idx) + 1 # wait, the block has multiple braces.
    
    # Just do a blind replace from idx to idx+400
    block = code[idx:idx+400]
    block2 = block.replace('vmResult', 'vmResult2')
    code = code[:idx] + block2 + code[idx+400:]
    
with open('lib/providers/server_provider.dart', 'w') as f:
    f.write(code)

