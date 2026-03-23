with open('lib/providers/server_provider.dart', 'r') as f:
    code = f.read()
print(code.count("final vmResult = await _unraidNative.getVms();"))
