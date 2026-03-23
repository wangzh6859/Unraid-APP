import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Add import
if "import 'screens/media_detail_screen.dart';" not in code:
    code = code.replace("import 'screens/login_screen.dart';", "import 'screens/login_screen.dart';\nimport 'screens/media_detail_screen.dart';")

# Find MediaClientViewState and update its build method
media_client_view = """class _MediaClientViewState extends State<MediaClientView> {
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
          
          // Categories Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: embyProvider.categories.map((cat) {
                    final isSelected = embyProvider.currentCategory == cat['value'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ChoiceChip(
                        label: Text(cat['name']!, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            embyProvider.fetchMedia(category: cat['value']);
                          }
                        },
                        selectedColor: const Color(0xFFFF5722),
                        labelStyle: TextStyle(color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
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
                child: Text('该分类下没有内容，或未配置Emby', style: TextStyle(color: Colors.grey)),
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
                    return GestureDetector(
                      onTap: () {
                         Navigator.push(context, MaterialPageRoute(builder: (_) => MediaDetailScreen(item: item)));
                      },
                      child: Container(
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
}"""

# Replace the current _MediaClientViewState implementation
code = re.sub(r"class _MediaClientViewState extends State<MediaClientView> \{.*?\n\}\n\}", media_client_view + "\n", code, flags=re.DOTALL)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

