with open('lib/main.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Instead of regex which is dangerous, I will just manually edit the exact lines.
# We know the duplicate button is right before `_buildSettingsGroup(context, '外观与通用', [`
# We just need to find the FIRST occurrence of the save button and remove it.

# Looking at main.dart from the earlier log
code = "".join(lines)

# Find the first save button (the one inside the Unraid API group)
import re

first_button_pattern = r"const SizedBox\(height: 20\),\s*SizedBox\(\s*width: double\.infinity,\s*height: 48,\s*child: ElevatedButton\.icon\(.*?\),\s*\),\s*\),"
code = re.sub(first_button_pattern, "", code, count=1, flags=re.DOTALL)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)
