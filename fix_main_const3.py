import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Let's just remove ALL `const Column(` and `const Row(` that have cpuModel inside.
# Actually, the problem is the Column inside the Row of SliverAppBar.large title!

title_pattern = r"title: const Row\(\s*children: \[\s*Icon\(Icons.dns_rounded.*?\]"
# I replaced `const Row(` before, but maybe the array still has `const` or the `Column` inside it does.

new_title = """title: Row(
            children: [
              const Icon(Icons.dns_rounded, color: Color(0xFFFF5722), size: 28),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('主服务器', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2, fontSize: 22)),
                  Text(serverProvider.cpuModel, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.normal)),
                ],
              ),
            ],
          )"""

# Regex might fail if I don't match it exactly. Let's find "title: Row(" or "title: const Row("
# Let's just do text replacement.
code = re.sub(r"title: (const )?Row\([\s\S]*?Text\(serverProvider\.cpuModel[\s\S]*?\],[\s\S]*?\),[\s\S]*?\],[\s\S]*?\),", new_title + ",", code)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

with open('lib/providers/server_provider.dart', 'r', encoding='utf-8') as f:
    prov_code = f.read()

# Dart's raw string syntax `r"..."` STILL parses `$2` in string interpolation if we are not careful? 
# No, `r"..."` should not parse it. BUT wait... the error was `A '$' has special meaning inside a string`. 
# It means dart DOES NOT recognize the `r` prefix if it's placed wrongly or my python script didn't write it!
# Let's just use string concatenation to completely avoid the $ symbol in Dart source code!

prov_code = prov_code.replace(r"r\"top -bn1 | grep 'Cpu(s)' | awk '{print $2 + $4}'\"", "\"top -bn1 | grep 'Cpu(s)' | awk '{print \\x24\"\"2 + \\x24\"\"4}'\"")
prov_code = prov_code.replace(r"r\"free | grep Mem | awk '{print $3/$2 * 100.0}'\"", "\"free | grep Mem | awk '{print \\x24\"\"3/\\x24\"\"2 * 100.0}'\"")

# If my previous python replacement failed, let's also catch the normal string version.
prov_code = prov_code.replace("\"top -bn1 | grep 'Cpu(s)' | awk '{print $2 + $4}'\"", "\"top -bn1 | grep 'Cpu(s)' | awk '{print \\x24\"\"2 + \\x24\"\"4}'\"")
prov_code = prov_code.replace("\"free | grep Mem | awk '{print $3/$2 * 100.0}'\"", "\"free | grep Mem | awk '{print \\x24\"\"3/\\x24\"\"2 * 100.0}'\"")

with open('lib/providers/server_provider.dart', 'w', encoding='utf-8') as f:
    f.write(prov_code)

