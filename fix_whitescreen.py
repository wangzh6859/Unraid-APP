import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Ah ha! The `runApp(...)` uses `MainNavigationPage()` instead of `UnraidApp()`!
# Since `UnraidApp` is the one with `MaterialApp` and routing logic (`home: !_isReady ? ...`), 
# bypassing it and running `MainNavigationPage` directly skips `MaterialApp`! 
# Flutter CANNOT render a Scaffold (inside MainNavigationPage) without a MaterialApp as its ancestor!
# That causes a massive unhandled exception at startup -> WHITE SCREEN OF DEATH.

code = code.replace("child: const MainNavigationPage(),", "child: const UnraidApp(),")

# But wait, earlier I broke UnraidApp because `class UnraidApp` had a big commented out block from my bad regex.
# Let's clean up `class UnraidApp` and ensure it actually builds the `MaterialApp`!
# The commented out block `/* void _showEmbyAccountDialog()...` is actually INSIDE _UnraidAppState because my regex put it there!
# Let's fix _UnraidAppState completely.

stateful_unraid_app = """class UnraidApp extends StatefulWidget {
  const UnraidApp({super.key});
  @override
  State<UnraidApp> createState() => _UnraidAppState();
}

class _UnraidAppState extends State<UnraidApp> {
  bool _isReady = false;
  bool _hasLogin = false;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    await AppConfig.load();
    setState(() {
      _hasLogin = AppConfig.baseDomain.isNotEmpty && AppConfig.username.isNotEmpty;
      _isReady = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) {
        return MaterialApp(
          title: 'Unraid Dashboard',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: ThemeData(
            brightness: Brightness.light,
            colorSchemeSeed: const Color(0xFFFF5722),
            scaffoldBackgroundColor: const Color(0xFFF2F2F6),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorSchemeSeed: const Color(0xFFFF5722),
            scaffoldBackgroundColor: const Color(0xFF111112),
            cardColor: const Color(0xFF1C1C1E),
            useMaterial3: true,
          ),
          home: !_isReady 
              ? const Scaffold(body: Center(child: CircularProgressIndicator())) 
              : (_hasLogin ? const MainNavigationPage() : const LoginScreen()),
        );
      },
    );
  }
}"""

# I need to wipe out the current `class UnraidApp ...` to the start of `class MainNavigationPage`
code = re.sub(r"class UnraidApp extends StatefulWidget \{.*?class MainNavigationPage", stateful_unraid_app + "\n\nclass MainNavigationPage", code, flags=re.DOTALL)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

