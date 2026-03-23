with open('lib/main.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Remove any extra trailing braces at the very end
while lines and lines[-1].strip() in ('}', '', 'class OutlineBindingBorder extends OutlineInputBorder {', '  const OutlineBindingBorder({super.borderSide, super.borderRadius});'):
    lines.pop()

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.writelines(lines)
