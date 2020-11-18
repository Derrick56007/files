import 'dart:io';

import 'package:derricks_file_browser/server.dart';

void main() async {
  const address = '0.0.0.0';
  const defaultPort = 8080;

  final port = Platform.environment.containsKey('PORT') ? int.parse(Platform.environment['PORT']) : defaultPort;

  final server = FileBrowserServer(address, port);
  await server.init();
}
