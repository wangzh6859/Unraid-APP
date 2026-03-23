import 'package:flutter/material.dart';
import '../utils/app_config.dart';
import '../main.dart'; // import MainScreen

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _urlCtrl = TextEditingController(text: 'https://5nas.asia:16666');
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isSaving = false;

  void _login() async {
    if (_urlCtrl.text.isEmpty || _userCtrl.text.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请填写地址和账号')));
       return;
    }
    setState(() => _isSaving = true);
    await AppConfig.save(_urlCtrl.text, _userCtrl.text, _passCtrl.text);
    if (mounted) {
       Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavigationPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_done_rounded, size: 80, color: Color(0xFFFF5722)),
              const SizedBox(height: 24),
              const Text('欢迎使用 Unraid 仪表盘', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('请输入您的全局服务器信息，将自动派生 Glances 与 Emby 节点', style: TextStyle(color: Colors.grey, fontSize: 13), textAlign: TextAlign.center),
              const SizedBox(height: 48),
              
              TextField(
                controller: _urlCtrl,
                decoration: InputDecoration(
                  labelText: '主服务器地址',
                  hintText: '例: https://5nas.asia:16666',
                  filled: true,
                  fillColor: isDark ? Colors.white10 : Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _userCtrl,
                decoration: InputDecoration(
                  labelText: '用户名',
                  hintText: '输入您的全局账号',
                  filled: true,
                  fillColor: isDark ? Colors.white10 : Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: '密码',
                  hintText: '输入您的密码',
                  filled: true,
                  fillColor: isDark ? Colors.white10 : Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.key),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5722),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSaving 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('验证并登录', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
