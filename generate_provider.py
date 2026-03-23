import os

with open('lib/providers/server_provider.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# find line 15
print("Line 13-18:")
for i in range(12, 18):
    if i < len(lines): print(f"{i+1}: {lines[i]}")

