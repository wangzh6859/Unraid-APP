with open('lib/providers/server_provider.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Just rename the second one to vmResult2
parts = code.split('final vmResult = await _unraidNative.getVms();')
if len(parts) == 3:
    # There are exactly 2 occurrences
    # Let's rebuild the code but rename the second one
    # Actually, if there are two occurrences, the second one probably looks like this:
    # final vmResult = await _unraidNative.getVms();
    # if (vmResult != null ...
    
    # Simple fix, let's just do a string replace of the second half of the file
    first_half = code[:len(code)//2]
    second_half = code[len(code)//2:]
    
    second_half = second_half.replace('final vmResult =', 'final vmResult2 =')
    second_half = second_half.replace('(vmResult !=', '(vmResult2 !=')
    second_half = second_half.replace('vmResult.containsKey', 'vmResult2.containsKey')
    second_half = second_half.replace("vmResult['error']", "vmResult2['error']")
    
    code = first_half + second_half

with open('lib/providers/server_provider.dart', 'w', encoding='utf-8') as f:
    f.write(code)
