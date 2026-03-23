with open('lib/providers/server_provider.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# I completely messed up the replacement. 
# It replaced `bool isLoading = false;` property declaration with `bool \n // Fetch VMs... \n isLoading = false;`

bad_block = """  bool 
    // Fetch VMs from Native WebGUI
    final vmResult = await _unraidNative.getVms();
    if (vmResult != null && vmResult.containsKey('raw')) {
       rawVmResponse = 'Successfully connected to Unraid WebGUI. Raw data received.';
       // We will need to parse the raw html/json later.
    } else if (vmResult != null && vmResult.containsKey('error')) {
       rawVmResponse = vmResult['error'];
    }

    isLoading = false;"""

code = code.replace(bad_block, "  bool isLoading = false;")

# Now insert the VM fetch logic where it belongs: inside `_fetchStatsSilent()`

fetch_vms_code = """
    // Fetch VMs from Native WebGUI
    final vmResult = await _unraidNative.getVms();
    if (vmResult != null && vmResult.containsKey('raw')) {
       rawVmResponse = 'Successfully connected to Unraid WebGUI. Raw data received.';
    } else if (vmResult != null && vmResult.containsKey('error')) {
       rawVmResponse = vmResult['error'];
    }
"""

# find `isLoading = false;\n    notifyListeners();`
code = code.replace("    isLoading = false;\n    notifyListeners();", fetch_vms_code + "    isLoading = false;\n    notifyListeners();")

with open('lib/providers/server_provider.dart', 'w', encoding='utf-8') as f:
    f.write(code)

