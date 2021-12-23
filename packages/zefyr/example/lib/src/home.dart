import 'dart:convert';

import 'package:example/src/read_only_view.dart';
import 'package:file/local.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zefyr/zefyr.dart';

import 'forms_decorated_field.dart';
import 'layout.dart';
import 'layout_expanded.dart';
import 'layout_scrollable.dart';
import 'settings.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  ZefyrController _controller;
  final FocusNode _focusNode = FocusNode();

  Settings _settings;
  var _isContainsUnsupportedFormat = false;

  void _handleSettingsLoaded(Settings value) {
    setState(() {
      _settings = value;
      _loadFromAssets();
    });
  }

  @override
  void initState() {
    super.initState();
    Settings.load().then(_handleSettingsLoaded);
  }

  Future<void> _loadFromAssets() async {
    try {
      final result = await rootBundle.loadString('assets/welcome.note');
      final doc = NotusDocument.fromJson(jsonDecode(result));
      setState(() {
        _controller = ZefyrController(doc);
        _isContainsUnsupportedFormat = false;
      });
    } catch (exception) {
      if (exception is UnsupportedFormatException) {
        // 対応してない規格エラー
        setState(() {
          _isContainsUnsupportedFormat = true;
        });
      }
      final doc = NotusDocument()..insert(0, 'Empty asset');
      setState(() {
        _controller = ZefyrController(doc);
      });
    }
  }

  Future<void> _save() async {
    final fs = LocalFileSystem();
    final file = fs.directory(_settings.assetsPath).childFile('welcome.note');
    final data = jsonEncode(_controller.document);
    await file.writeAsString(data);
  }

  @override
  Widget build(BuildContext context) {
    if (_settings == null || _controller == null) {
      return Scaffold(body: Center(child: Text('Loading...')));
    }

    return SettingsProvider(
      settings: _settings,
      child: PageLayout(
        appBar: AppBar(
          backgroundColor: Colors.grey.shade800,
          elevation: 0,
          centerTitle: false,
          title: Text(
            'Zefyr',
            style: GoogleFonts.fondamento(color: Colors.white),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.settings, size: 16),
              onPressed: _showSettings,
            ),
            if (_settings.assetsPath.isNotEmpty)
              IconButton(
                icon: Icon(Icons.save, size: 16),
                onPressed: _save,
              )
          ],
        ),
        menuBar: Material(
          color: Colors.grey.shade800,
          child: _buildMenuBar(context),
        ),
        body: _buildWelcomeEditor(context),
      ),
    );
  }

  void _showSettings() async {
    final result = await showSettingsDialog(context, _settings);
    if (mounted && result != null) {
      setState(() {
        _settings = result;
      });
    }
  }

  Widget _buildMenuBar(BuildContext context) {
    final headerStyle = TextStyle(
        fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.bold);
    final itemStyle = TextStyle(color: Colors.white);
    return ListView(
      children: [
        ListTile(
          title: Text('BASIC EXAMPLES', style: headerStyle),
          // dense: true,
          visualDensity: VisualDensity.compact,
        ),
        ListTile(
          title: Text('¶   Read only view', style: itemStyle),
          dense: true,
          visualDensity: VisualDensity.compact,
          onTap: _readOnlyView,
        ),
        ListTile(
          title: Text('LAYOUT EXAMPLES', style: headerStyle),
          // dense: true,
          visualDensity: VisualDensity.compact,
        ),
        ListTile(
          title: Text('¶   Expandable', style: itemStyle),
          dense: true,
          visualDensity: VisualDensity.compact,
          onTap: _expanded,
        ),
        ListTile(
          title: Text('¶   Custom scrollable', style: itemStyle),
          dense: true,
          visualDensity: VisualDensity.compact,
          onTap: _scrollable,
        ),
        ListTile(
          title: Text('FORMS AND FIELDS EXAMPLES', style: headerStyle),
          // dense: true,
          visualDensity: VisualDensity.compact,
        ),
        ListTile(
          title: Text('¶   Decorated field', style: itemStyle),
          dense: true,
          visualDensity: VisualDensity.compact,
          onTap: _decoratedField,
        ),
      ],
    );
  }

  Widget _buildWelcomeEditor(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(context),
        ZefyrToolbar(children: [
          ZIconButton(
            highlightElevation: 0,
            hoverElevation: 0,
            size: 32,
            icon: Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: Theme.of(context).iconTheme.color,
            ),
            fillColor: Theme.of(context).canvasColor,
            onPressed: () {
              FocusScope.of(context).unfocus();
            },
          ),
          ZIconButton(
            highlightElevation: 0,
            hoverElevation: 0,
            size: 32,
            icon: Icon(
              Icons.image,
              size: 18,
              color: Theme.of(context).iconTheme.color,
            ),
            fillColor: Theme.of(context).canvasColor,
            onPressed: () {
              final index = _controller.selection.baseOffset;
              final length = _controller.selection.extentOffset - index;
              _controller.replaceText(
                  index,
                  length,
                  BlockEmbed.image(
                      source: 'https://firebasestorage.googleapis.com/v0/b/hokutoapp-jp.appspot.com/o/admin%2Fsample-notes%2Fintroduce%2F2.png?alt=media&token=5c054a6a-fb45-43ff-9a83-87f2dec7a568', ref: ''));
            },
          ),
          ZIconButton(
            highlightElevation: 0,
            hoverElevation: 0,
            size: 32,
            icon: Icon(
              Icons.format_indent_increase_outlined,
              size: 18,
              color: Theme.of(context).iconTheme.color,
            ),
            fillColor: Theme.of(context).canvasColor,
            onPressed: () {
              _controller.increaseIndentAtSelection();
            },
          ),
          ZIconButton(
            highlightElevation: 0,
            hoverElevation: 0,
            size: 32,
            icon: Icon(
              Icons.format_indent_decrease_outlined,
              size: 18,
              color: Theme.of(context).iconTheme.color,
            ),
            fillColor: Theme.of(context).canvasColor,
            onPressed: () {
              _controller.decreaseIndentAtSelection();
            },
          ),
          ...ZefyrToolbar.basic(
            controller: _controller,
          ).children
        ]),
        Divider(height: 1, thickness: 1, color: Colors.grey.shade200),

        _isContainsUnsupportedFormat
            ? Expanded(
              child: Center(
                  child: Text('This document has unsupported format.'),
                ),
            )
            : Expanded(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: ZefyrEditor(
                    controller: _controller,
                    focusNode: _focusNode,
                    autofocus: true,
                    embedBuilder: (context, node) {
                      if (node.value.type == 'hr') {
                        final theme = ZefyrTheme.of(context);
                        assert(
                        theme.paragraph != null, 'Paragraph theme must be set');
                        return Divider(
                          height: theme.paragraph.style.fontSize *
                              theme.paragraph.style.height,
                          thickness: 2,
                          color: Colors.grey.shade200,
                        );
                      }
                      if (node.value.type == 'image') {
                        final image = EmbedImage.fromEmbedObj(node.value);
                        return Image.network(
                          image.source,
                          fit: BoxFit.fitWidth,
                          loadingBuilder: (context, widget, event) => event == null
                              ? widget
                              : SizedBox(
                            width: 200,
                            height: 200,
                          ),
                        );
                      }
                      if (node.value.type == 'pdf') {
                        final pdf = EmbedPdf.fromEmbedObj(node.value);
                        final url = pdf.source;
                        final fileName = pdf.name;
                        final size = pdf.size;
                        final ref = pdf.ref;
                        return Text(
                          'pdf url: $url, ref: $ref, fileName: $fileName, size: $size',
                        );
                      }
                      if (node.value.type == 'table') {
                        final table = EmbedTable.fromEmbedObj(node.value);
                        final contents = table.contents;
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey, width: 1),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Text(contents[0]['0']['text']),
                                  Container(color: Colors.grey, width: 1, height: 15),
                                  Text(contents[0]['1']['text']),
                                ],
                              ),
                              Container(color: Colors.grey, height: 1),
                              Row(
                                children: [
                                  Text(contents[1]['0']['text']),
                                  Container(color: Colors.grey, width: 1, height: 15),
                                  Text(contents[1]['1']['text']),
                                ],
                              ),
                            ],
                          ),
                        );
                      }
                      throw UnimplementedError(
                          'Embeddable type "${node.value.type}" is not supported by default embed '
                              'builder of ZefyrEditor. You must pass your own builder function to '
                              'embedBuilder property of ZefyrEditor or ZefyrField widgets.');
                    },
                    // readOnly: true,
                    // padding: EdgeInsets.only(left: 16, right: 16),
                    onLaunchUrl: _launchUrl,
                  ),
                ),
        ),
      ],
    );
  }

  void _launchUrl(String url) async {
    final result = await canLaunch(url);
    if (result) {
      await launch(url);
    }
  }

  void _expanded() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => SettingsProvider(
          settings: _settings,
          child: ExpandedLayout(),
        ),
      ),
    );
  }

  void _readOnlyView() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => SettingsProvider(
          settings: _settings,
          child: ReadOnlyView(),
        ),
      ),
    );
  }

  void _scrollable() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => SettingsProvider(
          settings: _settings,
          child: ScrollableLayout(),
        ),
      ),
    );
  }

  void _decoratedField() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => SettingsProvider(
          settings: _settings,
          child: DecoratedFieldDemo(),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: _controller.searchQuery,
                decoration: const InputDecoration(
                  hintText: '検索',
                ),
                onFieldSubmitted: (_) {
                  _controller.selectNextSearchHit();
                },
                onChanged: (query) {
                  _controller.search(query);
                  setState(() {});
                },
              ),
            ),
            Text(
              (_controller.searchFocusIndex == 0 && _controller.searchQuery.isEmpty ? 0 : _controller.searchFocusIndex + 1).toString() + ' / ' + _controller.findSearchMatch().length.toString(),
            ),
            IconButton(
              icon: Icon(Icons.arrow_downward),
              onPressed: () {
                _controller.selectNextSearchHit();
                setState(() {});
              },
            ),
            IconButton(
              icon: Icon(Icons.arrow_upward),
              onPressed: () {
                _controller.selectPreviousSearchHit();
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }
}
