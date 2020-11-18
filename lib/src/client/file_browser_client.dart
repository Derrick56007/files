import 'dart:html';

import 'package:path/path.dart' as path;

import 'package:websockets/client.dart';

final mainView = querySelector('#main-view');

final pathMap = <String, String>{};

void main() async {
  final address = '0.0.0.0';
  final port = 8080;

  final client = ClientWebSocket(address, port);
  await client.start();

  client
    ..on('error', (data) {
      print('error: $data');
    })
    ..on('list_directory_response', (data) => _onListDirectoryResponse(client, data));

  print('connected');
}

Future<void> _onListDirectoryResponse(ClientWebSocket client, data) async {
  final parentPath = data['parent_path'];

  final esc = parentPath.replaceAll('/', '_').replaceAll('\\', '_').replaceAll('.', '_');

  final parentElChildren = document.querySelector('#path_${esc}_children');

  parentElChildren.children.clear();

  // mainView.children.clear();

  // for (final item in data['rows']) {
  //   final el = _createBrowserRow(client, parentPath, item);

  //   parentElChildren.children.add(el);

  //   final i = _createMainItem(client, parentPath, item);
  //   mainView.children.add(i);
  // }
}

// Element _createMainItem(ClientWebSocket client, parentPath, item) {
//   final name = item['name'];
//   final isDir = item['isDir'];

//   final p = path.join(parentPath, name);

//   final esc = p
//       .replaceAll('/', '_') //
//       .replaceAll('\\', '_')
//       .replaceAll('.', '_');

//   final el = Element.html('''
//     <div class="item">
//       <div class="item-button">
//         <div class="main-item-icon"></div>
//         <div>$name</div>
//         <div class="item-buttons">
//           <div>button</div>
//         </div>
//       </div>
//       <div class="row-divider"></div>
//     </div>
//   ''');

//   return el;
// }

Element highlightedRow;

Element _createBrowserRow(ClientWebSocket client, parentPath, item) {
  final name = item['name'];
  final isDir = item['isDir'];

  final p = path.join(parentPath, name);

  final esc = p
      .replaceAll('/', '_') //
      .replaceAll('\\', '_')
      .replaceAll('.', '_');

  final el = Element.html('''
    <div class="browser-row">
      <div id="folder-button" class="browser-row-inner">
        <div id="item-icon" class="item-icon"></div>
        <div>$name</div>
      </div>

      <div id="path_${esc}_children"></div>
    </div>
  ''');

  el.style.marginLeft = '10px';

  final folderBtn = el.querySelector('#folder-button');
  final itemIcon = el.querySelector('#item-icon');

  folderBtn.style.cursor = 'pointer';

  var opened = false;

  final folderChildren = el.querySelector('#path_${esc}_children');

  void _setFolderIcon() {
    final text = opened ? '▾' : '▸';

    itemIcon.text = text;

    if (opened) {
      client.send('list_directory', {'path': p});
    } else {
      folderChildren.children.clear();
    }
  }

  if (isDir) {
    _setFolderIcon();

    el.classes.add('browser-row-dir');
  } else {
    el.classes.add('browser-row-file');
  }

  folderBtn.onClick.listen((_) {
    if (isDir) {
      opened = !opened;

      _setFolderIcon();
    }

    if (highlightedRow == el) {
      el.classes.remove('selected-row');
      highlightedRow = null;
    } else if (highlightedRow != null) {
      highlightedRow.classes.remove('selected-row');
      highlightedRow = el;
      highlightedRow.classes.add('selected-row');
    } else if (highlightedRow == null) {
      highlightedRow = el;
      highlightedRow.classes.add('selected-row');
    }
  });

  return el;
}
