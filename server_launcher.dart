import 'dart:io';

class ServerLauncher {
  Process? _serverProcess;

  /// Start the Flask server
  Future<void> startServer() async {
    if (_serverProcess != null) return;

    _serverProcess = await Process.start(
      'python',
      ['backend/backend_server.py'],
      mode: ProcessStartMode.detachedWithStdio,
    );

    _serverProcess!.stdout.transform(SystemEncoding().decoder).listen((data) {
      print('[SERVER STDOUT] $data');
    });

    _serverProcess!.stderr.transform(SystemEncoding().decoder).listen((data) {
      print('[SERVER STDERR] $data');
    });

    print('Flask server started.');
  }

  /// Stop the Flask server
  Future<void> stopServer() async {
    if (_serverProcess != null) {
      _serverProcess!.kill();
      _serverProcess = null;
      print('Flask server stopped.');
    }
  }
}
