import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notus/notus.dart';
import 'package:validators/validators.dart';
import 'package:zefyr/src/widgets/controller.dart';

class ZefyrCupertinoTextSelectionControls extends CupertinoTextSelectionControls {
  ZefyrCupertinoTextSelectionControls(this.controller);
  final ZefyrController controller;

  @override
  void handleCut(TextSelectionDelegate delegate) => _handleCut(delegate, controller, super);

  @override
  void handleCopy(TextSelectionDelegate delegate, ClipboardStatusNotifier clipboardStatus) =>
      _handleCopy(delegate, controller, clipboardStatus, super);
}

class ZefyrMaterialTextSelectionControls extends MaterialTextSelectionControls {
  ZefyrMaterialTextSelectionControls(this.controller);
  final ZefyrController controller;

  @override
  void handleCut(TextSelectionDelegate delegate) => _handleCut(delegate, controller, super);

  @override
  void handleCopy(TextSelectionDelegate delegate, ClipboardStatusNotifier clipboardStatus) =>
      _handleCopy(delegate, controller, clipboardStatus, super);
}

void _handleCut(TextSelectionDelegate delegate, ZefyrController controller, TextSelectionControls _super) {
  final start = delegate.textEditingValue.selection.start;
  final node = controller.document.lookupLine(start).node;
  if (_isImage(node)) {
    final embed = (node as LineNode).children.single as EmbedNode;
    final url = embed.value.data['source'];
    Clipboard.setData(ClipboardData(text: '$embedImageUrlPrefix$url'));
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
    return;
  }
  _super.handleCut(delegate);
}

void _handleCopy(TextSelectionDelegate delegate, ZefyrController controller, ClipboardStatusNotifier clipboardStatus, TextSelectionControls _super) {
  final start = delegate.textEditingValue.selection.start;
  final node = controller.document.lookupLine(start).node;
  if (_isImage(node)) {
    final embed = (node as LineNode).children.single as EmbedNode;
    final url = embed.value.data['source'];
    Clipboard.setData(ClipboardData(text: '$embedImageUrlPrefix$url'));
    delegate.hideToolbar();
    return;
  }
  _super.handleCopy(delegate, clipboardStatus);
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
