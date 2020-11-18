import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as path;
import 'package:websockets/server.dart';

import 'words.dart' as words;

class FileBrowserServer extends FileServer {
  static const basePath = 'data/';

  final shortenedUrlToPath = <String, String>{};

  final random = Random();

  FileBrowserServer(String address, int port,
      {String filesDirectory = FileServer.defaultFilesDirectory,
      String defaultPagePath = FileServer.defaultDefaultPagePath})
      : super(address, port, filesDirectory: filesDirectory, defaultPagePath: defaultPagePath);

  @override
  Future<bool> onRequestPre(HttpRequest req) async {
    // print(req);

    req.response.headers.set('cache-control', 'no-cache');

    final name = path.basename(req.uri.path);

    final p = shortenedUrlToPath[name];

    if (p != null) {
      final file = File(p);
      print(p);
      print(file.absolute.path);

      if ((await file.exists())) {
        final bytes = await file.readAsBytes();

        req.response.headers //
          ..set('Content-Type', 'application/octet-stream')
          ..set('Content-Length', bytes.length)
          ..set('Content-Disposition', 'attachment; filename="${path.basename(p)}"');

        req.response.add(bytes);
        await req.response.close();

        return true;
      }
    }

    return false;
  }

  @override
  void handleSocketStart(HttpRequest req, ServerWebSocket socket) {
    socket //
      ..on('list_directory', (data) => onListDirectory(socket, data))
      ..on('generate_download', (data) => onGenerateDownload(socket, data));

    onListDirectory(socket, const {'path': ''});
  }

  Future<void> onGenerateDownload(ServerWebSocket socket, data) async {
    print('request generate download $data');

    final p = path.join(basePath, '${data["path"]}');

    if (shortenedUrlToPath.containsValue(p)) {
      // TODO copy existing link
      return;
    }

    final isDir = await FileSystemEntity.isDirectory(p);

    if (isDir) {
    } else {
      final f = File(p);
      if ((await f.exists())) {
        var shortendUrl;

        do {
          var adj1 = words.adjectives[random.nextInt(words.adjectives.length)];
          var adj2 = words.adjectives[random.nextInt(words.adjectives.length)];

          var animal = words.animals[random.nextInt(words.animals.length)];

          shortendUrl = '$adj1$adj2$animal';
        } while (shortenedUrlToPath.keys.contains(shortendUrl));

        shortenedUrlToPath[shortendUrl] = p;

        print('created download link: $shortendUrl');
      }
    }
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
