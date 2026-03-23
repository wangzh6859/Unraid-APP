with open('lib/providers/server_provider.dart', 'r', encoding='utf-8') as f:
    code = f.read()

count = code.count("final vmResult = ")
print(f"Occurrences of final vmResult: {count}")
