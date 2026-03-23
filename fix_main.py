import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# DashboardView to use cpuModel
code = code.replace("Text('Intel Core i5-13500 · 14 Cores', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.normal)),",
                    "Text(serverProvider.cpuModel, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.normal)),")

# Move the save button to the very bottom so it saves EVERYTHING (API + SSH)
save_button = """
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveSettings,
                      icon: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
                      label: const Text('保存所有配置并测试连接', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5722),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
"""

# Remove old save button from Unraid API group
code = re.sub(r"const SizedBox\(height: 20\),\s*SizedBox\(\s*width: double\.infinity,.*?\}\),\s*\),\s*\),", "", code, flags=re.DOTALL)

# Add the save button below the Appearance group, or just as a floating action button or at the bottom of the list.
# Let's add it right after the Appearance group
code = code.replace("          _buildSettingsGroup(context, '外观与通用', [", "          " + save_button + "\n          const SizedBox(height: 24),\n          _buildSettingsGroup(context, '外观与通用', [")

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)
