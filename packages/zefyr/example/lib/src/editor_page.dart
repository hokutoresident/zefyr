import 'dart:convert';
import 'dart:io';

import 'package:example/src/loading.dart';
import 'package:flutter/material.dart';
import 'package:quill_delta/quill_delta.dart';
import 'package:zefyr/zefyr.dart';

class EditorPage extends StatefulWidget {
  @override
  EditorPageState createState() => EditorPageState();
}

class EditorPageState extends State<EditorPage> {
  /// Allows to control the editor and the document.
  ZefyrController? _controller;

  /// Zefyr editor like any other input field requires a focus node.
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _loadDocument().then((document) {
      setState(() {
        _controller = ZefyrController(document);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller; 
    if (controller == null) return Loading();

    return Scaffold(
      appBar: AppBar(
        title: Text('Editor page'),
        actions: <Widget>[
          Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.save),
              onPressed: () => _saveDocument(context, controller),
            ),
          )
        ],
      ),
      body: ZefyrField(
        padding: EdgeInsets.all(16),
        controller: _controller!,
        focusNode: _focusNode,
      ),
    );
  }

  /// Loads the document asynchronously from a file if it exists, otherwise
  /// returns default document.
  Future<NotusDocument> _loadDocument() async {
    final file = File(Directory.systemTemp.path + '/quick_start.json');
    if (await file.exists()) {
      final contents = await file
          .readAsString()
          .then((data) => Future.delayed(Duration(seconds: 1), () => data));
      return NotusDocument.fromJson(jsonDecode(contents));
    }
    final delta = Delta()..insert('Zefyr Quick Start\n');
    return NotusDocument()..compose(delta, ChangeSource.local);
  }

  void _saveDocument(BuildContext context, ZefyrController controller) {
    // Notus documents can be easily serialized to JSON by passing to
    // `jsonEncode` directly:
    final contents = jsonEncode(controller.document);
    // For this example we save our document to a temporary file.
    final file = File(Directory.systemTemp.path + '/quick_start.json');
    // And show a snack bar on success.
    file.writeAsString(contents).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved.')));
    });
  }
}
