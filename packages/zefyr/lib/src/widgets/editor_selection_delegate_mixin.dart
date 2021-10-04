import 'dart:io';

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
  void userUpdateTextEditingValue(
      TextEditingValue value, SelectionChangedCause cause) async {
        if(cause == SelectionChangedCause.toolBar){
          final selection = widget.controller.selection;
          final compare = value.selection.start - selection.start; // よくわからんがこれでcut or pasteの検証できる

          // cut
          if(compare == 0){
            // TODO: widgets/text_selection.dart widget.renderObject.preferredLineHeight(textPosition)で文字消え直後のselectionの参照破壊を修正
            // カットした瞬間末尾のセレクションの参照が破壊されてしまうため、セレクション変更後delayをかけてからreplaceTextを行う
            widget.controller.updateSelection(TextSelection.collapsed(offset: selection.start));
            Future.delayed(Duration(milliseconds: 100), (){
              widget.controller.replaceText(
                selection.start,
                selection.end - selection.start,
                '',
                selection: TextSelection.collapsed(offset: selection.start),
              );
            });
          }

          // paste
          if(compare > 0){
            final data = await Clipboard.getData(Clipboard.kTextPlain);
            if (data != null) {
              if (data.text.startsWith(CustomCupertinoTextSelectionControls.embedImageUrlPrefix)) {
                final index = widget.controller.selection.baseOffset;
                final length = widget.controller.selection.extentOffset - index;
                widget.controller.replaceText(
                    index,
                    length,
                    BlockEmbed.image(data.text.substring(CustomCupertinoTextSelectionControls.embedImageUrlPrefix.length)),
                );

                return;
              }
              final length = selection.end - selection.start;
              widget.controller.replaceText(
                selection.start,
                length,
                data.text,
                selection: TextSelection.collapsed(
                    offset: selection.start + data.text.length),
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
            }
          }

          // select all
          if (value.selection.start == 0 && value.selection.end == textEditingValue.text.length){
            final newSelection = selection.copyWith(
              baseOffset: 0,
              extentOffset: textEditingValue.text.length,
            );
            widget.controller.updateSelection(newSelection);
          }
      }
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
