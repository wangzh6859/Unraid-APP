import re

with open('lib/providers/server_provider.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# I injected fetch_vms_code twice. Once in the previous python script where I tried to replace `isLoading = false;\n    notifyListeners();`
# The error says: 
# lib/providers/server_provider.dart:98:11: Error: 'vmResult' is already declared in this scope.
# lib/providers/server_provider.dart:88:11: Context: Previous declaration of 'vmResult'.

# Let's clean up server_provider.dart by simply finding and removing one of them.
# The block is:
#    // Fetch VMs from Native WebGUI
#    final vmResult = await _unraidNative.getVms();
#    if (vmResult != null && vmResult.containsKey('raw')) {
#       rawVmResponse = 'Successfully connected to Unraid WebGUI. Raw data received.';
#    } else if (vmResult != null && vmResult.containsKey('error')) {
#       rawVmResponse = vmResult['error'];
#    }

parts = code.split('// Fetch VMs from Native WebGUI')
if len(parts) > 2:
    # It appears multiple times!
    # parts[0] is everything before the first
    # parts[1] is the first block
    # parts[2] is the second block
    
    # We will just reconstruct the file by keeping only the first one
    code = parts[0] + '// Fetch VMs from Native WebGUI' + parts[1]
    
    # Check if there is trailing code in parts[2] that we need
    # The duplicate probably ends with `isLoading = false;\n    notifyListeners();`
    # Let's do a smarter replace.

with open('lib/providers/server_provider.dart', 'w', encoding='utf-8') as f:
    f.write(code)

