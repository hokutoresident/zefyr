import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:validators/validators.dart';
import 'package:zefyr/zefyr.dart';

import 'editor.dart';

mixin RawEditorStateSelectionDelegateMixin on EditorState
    implements TextSelectionDelegate {
  @override
  TextEditingValue get textEditingValue {
    return widget.controller.plainTextEditingValue;
  }

  @override
  set textEditingValue(TextEditingValue value) {
    widget.controller
        .updateSelection(value.selection, source: ChangeSource.local);
  }

  @override
  void copySelection(SelectionChangedCause cause) {
    Clipboard.setData(ClipboardData(text: widget.controller.selectingText));
    hideToolbar();
  }

  @override
  void cutSelection(SelectionChangedCause cause) {
    final text = widget.controller.selectingText;
    widget.controller.replaceText(
      widget.controller.selection.start,
      widget.controller.selection.end - widget.controller.selection.start,
      '',
      selection: TextSelection.collapsed(offset: widget.controller.selection.start),
    );
    Clipboard.setData(ClipboardData(text: text));
    hideToolbar();
  }

  @override
  Future<void> pasteText(SelectionChangedCause cause) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null) {
      hideToolbar();
      return;
    }
    final length = widget.controller.selection.end - widget.controller.selection.start;
    widget.controller.replaceText(
      widget.controller.selection.start,
      length,
      data.text,
      selection: TextSelection.collapsed(
          offset: widget.controller.selection.start + data.text.length),
    );

    if (isURL(data.text)) {
      // URLの場合はURLと認識させるために最後尾にスペースを追加する
      // NOTE: 一度に `data.text + ' '`のようにreplaceTextしても意味ないので２度更新かけてる
      widget.controller.replaceText(
        widget.controller.selection.baseOffset,
        0,
        ' ',
        selection: widget.controller.selection.copyWith(
          baseOffset: widget.controller.selection.baseOffset + 1,
          extentOffset: widget.controller.selection.baseOffset + 1,
        ),
      );
    }
    hideToolbar();
  }

  @override
  void selectAll(SelectionChangedCause cause) {
    final newSelection = widget.controller.selection.copyWith(
      baseOffset: 0,
      extentOffset: textEditingValue.text.length,
    );
    widget.controller.updateSelection(newSelection);
    hideToolbar();
  }

  @override
  void userUpdateTextEditingValue(TextEditingValue value, SelectionChangedCause cause) async {
    // NOTE: もはやここは呼ばれないがないと怒られるので
  }

  @override
  void bringIntoView(TextPosition position) {
    // TODO: implement bringIntoView
  }

  @override
  void hideToolbar([bool hideValue = true]) {
    if (selectionOverlay?.toolbarIsVisible == true) {
      selectionOverlay?.hideToolbar();
    }
  }

  @override
  bool get cutEnabled => widget.toolbarOptions.cut && !widget.readOnly;

  @override
  bool get copyEnabled => widget.toolbarOptions.copy;

  @override
  bool get pasteEnabled => widget.toolbarOptions.paste && !widget.readOnly;

  @override
  bool get selectAllEnabled => widget.toolbarOptions.selectAll;
}
