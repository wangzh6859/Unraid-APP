import 'package:dartssh2/dartssh2.dart';

class SSHService {
  SSHClient? _client;

  Future<void> connect(String host, int port, String username, String password) async {
    try {
      final socket = await SSHSocket.connect(host, port, timeout: const Duration(seconds: 5));
      _client = SSHClient(
        socket,
        username: username,
        onPasswordRequest: () => password,
      );
      // Wait for authentication
      await _client!.authenticated;
    } catch (e) {
      throw Exception("SSH Connection failed: $e");
    }
  }

  Future<String> executeCommand(String command) async {
    if (_client == null || _client!.isClosed) {
      return "Error: Not connected";
    }
    try {
      final result = await _client!.run(command);
      return String.fromCharCodes(result).trim();
    } catch (e) {
      return "Error executing command: $e";
    }
  }

  void disconnect() {
    _client?.close();
    _client = null;
  }
}
