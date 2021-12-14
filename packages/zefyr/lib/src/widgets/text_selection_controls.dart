import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notus/notus.dart';
import 'package:validators/validators.dart';
import 'package:zefyr/src/widgets/controller.dart';

// TODO: ZefyrCupertinoTextSelectionControlsとZefyrMaterialTextSelectionControlsで完全に重複しているが、他のスタイルの維持したままコピペ機能を追加するにあたってここは完全に消えるはずなのでいったんこのままにしてます
// TODO: 選択したnodeごとtoJson()して文字列に直したものをクリップボードへコピーして、ペースト後のコールバックで復元してペーストする
class ZefyrCupertinoTextSelectionControls extends CupertinoTextSelectionControls {
  ZefyrCupertinoTextSelectionControls(this.controller);
  final ZefyrController controller;

  @override
  void handleCut(TextSelectionDelegate delegate, ClipboardStatusNotifier clipboardStatus) {
    final start = delegate.textEditingValue.selection.start;
    final node = controller.document.lookupLine(start).node;
    if (_isImage(node)) {
      final embed = (node as LineNode).children.single as EmbedNode;
      final url = embed.value.data['source'];
      Clipboard.setData(ClipboardData(text: '$embedImageUrlPrefix$url'));
      _deleteImage(controller, delegate);
      delegate.hideToolbar();
      return;
    }
    // super.handleCut(delegate, clipboardStatus);
  }

  @override
  void handleCopy(TextSelectionDelegate delegate, ClipboardStatusNotifier clipboardStatus) {
    final start = delegate.textEditingValue.selection.start;
    final node = controller.document.lookupLine(start).node;
    if (_isImage(node)) {
      final embed = (node as LineNode).children.single as EmbedNode;
      final url = embed.value.data['source'];
      Clipboard.setData(ClipboardData(text: '$embedImageUrlPrefix$url'));
      delegate.hideToolbar();
      return;
    }
    // super.handleCopy(delegate, clipboardStatus);
  }
}

class ZefyrMaterialTextSelectionControls extends MaterialTextSelectionControls {
  ZefyrMaterialTextSelectionControls(this.controller);
  final ZefyrController controller;

  @override
  void handleCut(TextSelectionDelegate delegate, ClipboardStatusNotifier clipboardStatus) {
    final start = delegate.textEditingValue.selection.start;
    final node = controller.document.lookupLine(start).node;
    if (_isImage(node)) {
      final embed = (node as LineNode).children.single as EmbedNode;
      final url = embed.value.data['source'];
      Clipboard.setData(ClipboardData(text: '$embedImageUrlPrefix$url'));
      _deleteImage(controller, delegate);
      delegate.hideToolbar();
      return;
    }
    super.handleCut(delegate, clipboardStatus);
  }

  @override
  void handleCopy(TextSelectionDelegate delegate, ClipboardStatusNotifier clipboardStatus) {
    final start = delegate.textEditingValue.selection.start;
    final node = controller.document.lookupLine(start).node;
    if (_isImage(node)) {
      final embed = (node as LineNode).children.single as EmbedNode;
      final url = embed.value.data['source'];
      Clipboard.setData(ClipboardData(text: '$embedImageUrlPrefix$url'));
      delegate.hideToolbar();
      return;
    }
    super.handleCopy(delegate, clipboardStatus);
  }
}

const embedImageUrlPrefix = 'EMBED_IMAGE_URL:';

bool _isImage(Node node) {
  if (!(node is LineNode)) return false;
  final line = node as LineNode;
  if (!line.hasEmbed) return false;
  final embed = line.children.single as EmbedNode;
  final url = embed.value.data['source'];
  return isURL(url);
}

void _deleteImage(ZefyrController controller, TextSelectionDelegate delegate) {
  controller.replaceText(
    delegate.textEditingValue.selection.start,
    delegate.textEditingValue.selection.textInside(delegate.textEditingValue.text).length,
    '',
    selection: controller.selection.copyWith(
      baseOffset: controller.selection.baseOffset,
      extentOffset: controller.selection.baseOffset,
    ),
  );
  delegate.hideToolbar();
}
