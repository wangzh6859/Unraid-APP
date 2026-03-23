import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Replace any occurrence of _showEmbyAccountDialog if it was injected into the wrong place.
# It seems my previous script injected into `Widget build(BuildContext context)` of WHAT exactly? 
# It replaced the FIRST `@override Widget build...`! That would be inside UnraidApp or DashboardView!
# Oh no, it broke something else!

code = code.replace("  void _showEmbyAccountDialog() {", "/*\n  void _showEmbyAccountDialog() {")
code = code.replace("              await AppConfig.saveEmbyAccount(urlCtrl.text, userCtrl.text, passCtrl.text);\n              Navigator.pop(ctx);\n              context.read<EmbyProvider>().fetchMedia();\n            },\n            child: const Text('保存并重连'),\n          ),\n        ],\n      ),\n    );\n  }\n\n  @override\n  Widget build(BuildContext context) {", "            },\n            child: const Text('保存并重连'),\n          ),\n        ],\n      ),\n    );\n  }\n*/\n\n  @override\n  Widget build(BuildContext context) {")

# Find MediaClientView
# If it's a StatelessWidget, change it to StatefulWidget
stateless_pattern = r"class MediaClientView extends StatelessWidget \{.*?\n\}\n"
stateful = """class MediaClientView extends StatefulWidget {
  const MediaClientView({super.key});
  @override
  State<MediaClientView> createState() => _MediaClientViewState();
}

class _MediaClientViewState extends State<MediaClientView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmbyProvider>().fetchMedia();
    });
  }

  void _showEmbyAccountDialog() {
    final urlCtrl = TextEditingController(text: AppConfig.embyUrl);
    final userCtrl = TextEditingController(text: AppConfig.activeEmbyUser);
    final passCtrl = TextEditingController(text: AppConfig.activeEmbyPass);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Emby 账号配置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'Emby 地址 (含端口)')),
            const SizedBox(height: 8),
            TextField(controller: userCtrl, decoration: const InputDecoration(labelText: '用户名')),
            const SizedBox(height: 8),
            TextField(controller: passCtrl, obscureText: true, decoration: const InputDecoration(labelText: '密码')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () async {
              await AppConfig.saveEmbyAccount(urlCtrl.text, userCtrl.text, passCtrl.text);
              Navigator.pop(ctx);
              context.read<EmbyProvider>().fetchMedia();
            },
            child: const Text('保存并重连'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final embyProvider = context.watch<EmbyProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            floating: true,
            title: const Text('影音中心', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
            actions: [
              IconButton(icon: const Icon(Icons.manage_accounts), onPressed: _showEmbyAccountDialog),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => embyProvider.fetchMedia(),
              )
            ],
            backgroundColor: Colors.transparent,
          ),
          if (embyProvider.isLoading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (embyProvider.errorMsg.isNotEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 60, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(embyProvider.errorMsg, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            )
          else if (embyProvider.latestItems.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text('没有最近添加的内容，或者未配置Emby', style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.68,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = embyProvider.latestItems[index];
                    final imageUrl = embyProvider.getImageUrl(item['Id']);
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: isDark ? Colors.white10 : Colors.grey.shade100,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (imageUrl.isNotEmpty)
                            Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.movie_creation, size: 40, color: Colors.grey)),
                            )
                          else
                            const Center(child: Icon(Icons.movie_creation, size: 40, color: Colors.grey)),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [Colors.black87, Colors.transparent],
                                ),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                item['Name'] ?? '未知内容',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: embyProvider.latestItems.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
"""

# If it was already converted to stateful earlier, let's just replace the whole thing.
# The class in main.dart might be just `class MediaClientView ...`
# Let's find anything from `class MediaClientView` until the next `class `
if "class MediaClientView" in code:
    code = re.sub(r"class MediaClientView.*?^class ", stateful + "\n\nclass ", code, flags=re.DOTALL|re.MULTILINE)
else:
    print("MediaClientView not found at all?")

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

