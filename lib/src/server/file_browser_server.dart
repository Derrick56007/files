import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:websockets/server.dart';

class FileBrowserServer extends FileServer {
  static const basePath = 'data/';

  final downloadable = <String, String>{'derp': 'inside/favicon2.ico'};

  FileBrowserServer(String address, int port,
      {String filesDirectory = FileServer.defaultFilesDirectory,
      String defaultPagePath = FileServer.defaultDefaultPagePath})
      : super(address, port, filesDirectory: filesDirectory, defaultPagePath: defaultPagePath);

  @override
  Future<bool> onRequestPre(HttpRequest req) async {
    req.response.headers.set('cache-control', 'no-cache');

    // final name = path.basename(req.uri.path);

    // if (downloadable.containsKey(name)) {
    //   final file = File(path.join(basePath, downloadable[name]));

    //   print(file.absolute.path);

    //   if ((await file.exists())) {
    //     final bytes = await file.readAsBytes();

    //     req.response.headers //
    //       ..set('Content-Type', 'application/octet-stream')
    //       ..set('Content-Length', bytes.length)
    //       ..set('Content-Disposition', 'attachment; filename="derp.ico"');

    //     req.response.add(bytes);
    //     await req.response.close();

    //     return true;
    //   }
    // }

    return false;
  }

  @override
  void handleSocketStart(HttpRequest req, ServerWebSocket socket) {
    socket //
      ..on('list_directory', (data) => onListDirectory(socket, data));

    onListDirectory(socket, const {'path': ''});
  }

  Future<void> onListDirectory(ServerWebSocket socket, data) async {
    final requestedDir = '${data["path"]}';
    final dir = Directory(path.join(basePath, requestedDir));

    if (!(await dir.exists())) {
      throw ('no such directory $requestedDir');
    }

    final rows = [];

    await for (FileSystemEntity e in dir.list(recursive: false, followLinks: false)) {
      final name = path.basename(e.path);

      final stat = await e.stat();

      rows.add({
        'name': name,
        'isDir': await FileSystemEntity.isDirectory(e.path),
        'size': stat.size,
        'modified': stat.modified.toIso8601String(),
      });
    }

    socket.send('list_directory_response', {
      'parent_path': requestedDir,
      'rows': rows,
    });
  }

  @override
  Future<void> onRequestPost(HttpRequest req) async {
    await super.onRequestPost(req);
  }
}
