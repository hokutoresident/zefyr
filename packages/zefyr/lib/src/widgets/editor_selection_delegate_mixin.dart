import 'dart:math';

import 'package:flutter/cupertino.dart';
<<<<<<< HEAD
import 'package:flutter/services.dart';
import 'package:validators/validators.dart';
import 'package:zefyr/src/widgets/text_selection_controls.dart';
import 'package:zefyr/zefyr.dart';
=======
import 'package:flutter/rendering.dart';
import 'package:zefyr/util.dart';
>>>>>>> 3842ca0150178ce0428c059e516f8a05ebc1d2c6

import 'editor.dart';

mixin RawEditorStateSelectionDelegateMixin on EditorState
    implements TextSelectionDelegate {
  @override
  TextEditingValue get textEditingValue {
    return widget.controller.plainTextEditingValue;
  }

  @override
  set textEditingValue(TextEditingValue value) {
    final cursorPosition = value.selection.extentOffset;
    final oldText = widget.controller.document.toPlainText();
    final newText = value.text;
    final diff = fastDiff(oldText, newText, cursorPosition);
    widget.controller.replaceText(
        diff.start, diff.deleted.length, diff.inserted,
        selection: value.selection);
  }

  @override
  void userUpdateTextEditingValue(
      TextEditingValue value, SelectionChangedCause cause) {
    textEditingValue = value;
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
              if (data.text.startsWith(embedImageUrlPrefix)) {
                final index = widget.controller.selection.baseOffset;
                final length = widget.controller.selection.extentOffset - index;
                widget.controller.replaceText(
                    index,
                    length,
                    BlockEmbed.image(data.text.substring(embedImageUrlPrefix.length)),
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
    final localRect = renderEditor.getLocalRectForCaret(position);
    final targetOffset = _getOffsetToRevealCaret(localRect, position);

    scrollController.jumpTo(targetOffset.offset);
    renderEditor.showOnScreen(rect: targetOffset.rect);
  }

  // Finds the closest scroll offset to the current scroll offset that fully
  // reveals the given caret rect. If the given rect's main axis extent is too
  // large to be fully revealed in `renderEditable`, it will be centered along
  // the main axis.
  //
  // If this is a multiline EditableText (which means the Editable can only
  // scroll vertically), the given rect's height will first be extended to match
  // `renderEditable.preferredLineHeight`, before the target scroll offset is
  // calculated.
  RevealedOffset _getOffsetToRevealCaret(Rect rect, TextPosition position) {
    if (!scrollController.position.allowImplicitScrolling) {
      return RevealedOffset(offset: scrollController.offset, rect: rect);
    }

    final editableSize = renderEditor.size;
    final double additionalOffset;
    final Offset unitOffset;

    // The caret is vertically centered within the line. Expand the caret's
    // height so that it spans the line because we're going to ensure that the
    // entire expanded caret is scrolled into view.
    final expandedRect = Rect.fromCenter(
      center: rect.center,
      width: rect.width,
      height: max(rect.height, renderEditor.preferredLineHeight(position)),
    );

    additionalOffset = expandedRect.height >= editableSize.height
        ? editableSize.height / 2 - expandedRect.center.dy
        : 0.0
            .clamp(expandedRect.bottom - editableSize.height, expandedRect.top);
    unitOffset = const Offset(0, 1);

    // No overscrolling when encountering tall fonts/scripts that extend past
    // the ascent.
    final targetOffset = (additionalOffset + scrollController.offset).clamp(
      scrollController.position.minScrollExtent,
      scrollController.position.maxScrollExtent,
    );

    final offsetDelta = scrollController.offset - targetOffset;
    return RevealedOffset(
        rect: rect.shift(unitOffset * offsetDelta), offset: targetOffset);
  }

  @override
<<<<<<< HEAD
  void hideToolbar([bool hideValue = true]) {
=======
  void hideToolbar([bool hideHandles = true]) {
>>>>>>> 3842ca0150178ce0428c059e516f8a05ebc1d2c6
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
