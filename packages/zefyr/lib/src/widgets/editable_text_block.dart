import 'dart:async';

import 'package:flutter/material.dart';
import 'package:notus/notus.dart';

import '../rendering/editable_text_block.dart';
import 'cursor.dart';
import 'editable_text_line.dart';
import 'editor.dart';
import 'text_line.dart';
import 'theme.dart';

class EditableTextBlock extends StatelessWidget {
  final BlockNode node;
  final TextDirection textDirection;
  final VerticalSpacing spacing;
  final CursorController cursorController;
  final TextSelection selection;
  final Color selectionColor;
  final bool enableInteractiveSelection;
  final bool hasFocus;
  final EdgeInsets? contentPadding;
  final ZefyrEmbedBuilder embedBuilder;
  final TextRange? Function(Node node)? inputtingTextRange;
  final LookupResult? lookupResult;
  final Map<int, int> indentLevelCounts;
  final String searchQuery;
  final Match? searchFocus;

  final StreamSink<Object> uiExceptionStreamSink;

  EditableTextBlock({
    Key? key,
    required this.node,
    required this.textDirection,
    required this.spacing,
    required this.cursorController,
    required this.selection,
    required this.selectionColor,
    required this.enableInteractiveSelection,
    required this.hasFocus,
    required this.embedBuilder,
    this.inputtingTextRange,
    this.lookupResult,
    required this.indentLevelCounts,
    required this.searchQuery,
    this.contentPadding,
    this.searchFocus,
    required this.uiExceptionStreamSink,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));

    final theme = ZefyrTheme.of(context);
    return _EditableBlock(
      node: node,
      textDirection: textDirection,
      padding: spacing,
      contentPadding: contentPadding,
      decoration: _getDecorationForBlock(node, theme) ?? BoxDecoration(),
      children: _buildChildren(context, indentLevelCounts),
    );
  }

  List<Widget> _buildChildren(
      BuildContext context, Map<int, int> indentLevelCounts) {
    final theme = ZefyrTheme.of(context);
    final count = node.children.length;
    final children = <Widget>[];
    var index = 0;
    for (final line in node.children) {
      index++;
      children.add(EditableTextLine(
        node: line as LineNode,
        textDirection: textDirection,
        spacing: _getSpacingForLine(line, index, count, theme),
        leading: _buildLeading(context, line, index, count, indentLevelCounts),
        bottom: _buildBottom(context, line),
        indentWidth: _styleIndentWidth() + _userIndentWidth(context, line),
        devicePixelRatio: MediaQuery.of(context).devicePixelRatio,
        uiExceptionStreamSink: uiExceptionStreamSink,
        body: TextLine(
          node: line,
          textDirection: textDirection,
          embedBuilder: embedBuilder,
          inputtingTextRange: inputtingTextRange!(line),
          lookupResult: lookupResult,
          searchQuery: searchQuery,
          searchFocus: searchFocus,
        ),
        cursorController: cursorController,
        selection: selection,
        selectionColor: selectionColor,
        enableInteractiveSelection: enableInteractiveSelection,
        hasFocus: hasFocus,
      ));
    }
    return children.toList(growable: false);
  }

  Widget? _buildLeading(BuildContext context, LineNode node, int index,
      int count, Map<int, int> indentLevelCounts) {
    final theme = ZefyrTheme.of(context);
    final block = node.style.get(NotusAttribute.block);
    final indent = node.style.get(NotusAttribute.indent)?.value ?? 0;

    if (block == NotusAttribute.block.numberList) {
      return _NumberPoint(
        index: index,
        indent: indent,
        style: theme.paragraph.style,
        width: theme.indentWidth,
        padding: 8.0,
        indentLevelCounts: indentLevelCounts,
      );
    } else if (block == NotusAttribute.block.bulletList) {
      return _BulletPoint(
        style: theme.paragraph.style.copyWith(fontWeight: FontWeight.bold),
        width: theme.indentWidth,
        indent: indent,
      );
    } else if (block == NotusAttribute.largeHeading) {
      return Row(
        children: [
          Container(
            height: 120, // NOTE: 最大で3行まで装飾がつくようにしている
            width: 8,
            color: Color(0xFF0099DD),
          ),
        ],
      );
    } else {
      return null;
    }
  }

  Widget? _buildBottom(BuildContext context, LineNode node) {
    final theme = ZefyrTheme.of(context);
    final block = node.style.get(NotusAttribute.block);
    if (block == NotusAttribute.middleHeading) {
      return Divider(
        height: (theme.paragraph.style.fontSize ?? 0.0) *
            (theme.paragraph.style.height ?? 0.0),
        thickness: 1,
        color: Color(0xFF0099DD),
      );
    }
    return null;
  }

  double _userIndentWidth(BuildContext context, LineNode node) {
    final theme = ZefyrTheme.of(context);
    final block = node.style.get(NotusAttribute.block);
    if (block == NotusAttribute.block.bulletList ||
        block == NotusAttribute.block.numberList) {
      final indentValue = node.style.get(NotusAttribute.indent)?.value ?? 0.0;
      return theme.indentWidth * indentValue;
    } else {
      return 0.0;
    }
  }

  double _styleIndentWidth() {
    final block = node.style.get(NotusAttribute.block);
    if (block == NotusAttribute.block.quote) {
      return 16.0;
    } else if (block == NotusAttribute.block.code) {
      return 0;
    } else if (block == NotusAttribute.block.bulletList) {
      return 28.0;
    } else if (block == NotusAttribute.block.numberList) {
      return 28.0;
    } else if (block == NotusAttribute.middleHeading) {
      return 0;
    } else {
      return 16.0;
    }
  }

  VerticalSpacing _getSpacingForLine(
      LineNode node, int index, int count, ZefyrThemeData theme) {
    final heading = node.style.get(NotusAttribute.heading);

    double? top;
    double? bottom;

    if (heading == NotusAttribute.heading.level1) {
      top = theme.heading1.spacing.top;
      bottom = theme.heading1.spacing.bottom;
    } else if (heading == NotusAttribute.heading.level2) {
      top = theme.heading2.spacing.top;
      bottom = theme.heading2.spacing.bottom;
    } else if (heading == NotusAttribute.heading.level3) {
      top = theme.heading3.spacing.top;
      bottom = theme.heading3.spacing.bottom;
    } else if (heading == NotusAttribute.heading.caption) {
      top = theme.caption.spacing.top;
      bottom = theme.caption.spacing.bottom;
    } else {
      final block = this.node.style.get(NotusAttribute.block);
      var lineSpacing;
      if (block == NotusAttribute.block.quote) {
        lineSpacing = theme.quote.lineSpacing;
      } else if (block == NotusAttribute.block.numberList ||
          block == NotusAttribute.block.bulletList) {
        lineSpacing = theme.lists.lineSpacing;
      } else if (block == NotusAttribute.block.code) {
        lineSpacing = theme.lists.lineSpacing;
      } else if (block == NotusAttribute.largeHeading) {
        lineSpacing = theme.largeHeading.lineSpacing;
      } else if (block == NotusAttribute.middleHeading) {
        lineSpacing = theme.middleHeading.lineSpacing;
      }
      top = lineSpacing.top;
      bottom = lineSpacing.bottom;
    }

    // If this line is the top one in this block we ignore its top spacing
    // because the block itself already has it. Similarly with the last line
    // and its bottom spacing.
    if (index == 1) {
      top = 0.0;
    }

    if (index == count) {
      bottom = 0.0;
    }

    return VerticalSpacing(top: top ?? 0, bottom: bottom ?? 0);
  }

  BoxDecoration? _getDecorationForBlock(BlockNode node, ZefyrThemeData theme) {
    final style = node.style.get(NotusAttribute.block);
    if (style == NotusAttribute.block.quote) {
      return theme.quote.decoration;
    } else if (style == NotusAttribute.block.code) {
      return theme.code.decoration;
    } else if (style == NotusAttribute.largeHeading) {
      return theme.largeHeading.decoration;
    }
    return null;
  }
}

class _EditableBlock extends MultiChildRenderObjectWidget {
  final BlockNode node;
  final TextDirection textDirection;
  final VerticalSpacing padding;
  final Decoration decoration;
  final EdgeInsets? contentPadding;

  _EditableBlock({
    Key? key,
    required this.node,
    required this.textDirection,
    this.padding = const VerticalSpacing(),
    this.contentPadding,
    required this.decoration,
    required List<Widget> children,
  }) : super(key: key, children: children);

  EdgeInsets get _padding =>
      EdgeInsets.only(top: padding.top, bottom: padding.bottom);

  EdgeInsets get _contentPadding => contentPadding ?? EdgeInsets.zero;

  @override
  RenderEditableTextBlock createRenderObject(BuildContext context) {
    return RenderEditableTextBlock(
      node: node,
      textDirection: textDirection,
      padding: _padding,
      decoration: decoration,
      contentPadding: _contentPadding,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderEditableTextBlock renderObject) {
    renderObject.node = node;
    renderObject.textDirection = textDirection;
    renderObject.padding = _padding;
    renderObject.decoration = decoration;
    renderObject.contentPadding = _contentPadding;
  }
}

class _NumberPoint extends StatelessWidget {
  final int index;
  final int indent;
  final TextStyle style;
  final double width;
  final bool withDot;
  final double padding;
  final Map<int, int> indentLevelCounts;

  const _NumberPoint({
    Key? key,
    required this.index,
    required this.indent,
    required this.style,
    required this.width,
    required this.indentLevelCounts,
    this.withDot = true,
    this.padding = 0.0,
  }) : super(key: key);

  // 以下のようにインデントするごとに数字をリセットしてる
  // 1.
  // 2.
  // 3.
  //   1.
  //   2.
  //     1.
  //     2.
  @override
  Widget build(BuildContext context) {
    var level = 0;

    if (indent == 0 && !indentLevelCounts.containsKey(1)) {
      indentLevelCounts.clear();
      return Container(
        width: width,
        padding: EdgeInsets.only(top: 2, right: 4),
        child: Text(
          withDot ? '$index.' : '$index',
          textAlign: TextAlign.right,
          style: baseStyle.copyWith(
            color: style.color,
            fontSize: style.fontSize,
          ),
        ),
      );
    }

    if (indent != 0) {
      level = indent;
    } else {
      indentLevelCounts[0] = 1;
    }
    if (indentLevelCounts.containsKey(level + 1)) {
      indentLevelCounts.remove(level + 1);
    }
    final count = (indentLevelCounts[level] ?? 0) + 1;
    indentLevelCounts[level] = count;

    return Container(
      width: width,
      // 視覚補正
      padding: EdgeInsets.only(top: 1, right: 4),
      child: Text(
        _createNumberText(withDot, indent, count),
        textAlign: TextAlign.right,
        style: baseStyle.copyWith(
          color: style.color,
          fontSize: style.fontSize,
        ),
      ),
    );
  }

  String _createNumberText(bool widthDot, int indent, int count) {
    if ([0, 3].contains(indent)) {
      return withDot ? '$count.' : '$count';
    }
    if ([1, 4].contains(indent)) {
      return '$count )';
    }
    if ([2, 5].contains(indent)) {
      const nums = [
        '①',
        '②',
        '③',
        '④',
        '⑤',
        '⑥',
        '⑦',
        '⑧',
        '⑨',
        '⑩',
        '⑪',
        '⑫',
        '⑬',
        '⑭',
        '⑮',
        '⑯',
        '⑰',
        '⑱',
        '⑲',
        '⑳',
        '㉑',
        '㉒',
        '㉓',
        '㉔',
        '㉕',
        '㉖',
        '㉗',
        '㉘',
        '㉙',
        '㉚',
        '㉛',
        '㉜',
        '㉝',
        '㉞',
        '㉟',
        '㊱',
        '㊲',
        '㊳',
        '㊴',
        '㊵',
        '㊶',
        '㊷',
        '㊸',
        '㊹',
        '㊺',
        '㊻',
        ' ㊼',
        '㊽',
        '㊾',
        '㊿'
      ];
      if (count <= nums.length) {
        return '${nums[count - 1]}';
      } else {
        return '$count ';
      }
    }
    return '';
  }
}

class _BulletPoint extends StatelessWidget {
  final TextStyle style;
  final double width;
  final int indent;

  const _BulletPoint({
    Key? key,
    required this.style,
    required this.width,
    required this.indent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.only(top: 10, right: 10),
        alignment: AlignmentDirectional.topEnd,
        width: width,
        child: Builder(
          builder: (context) {
            // ●
            if ([0, 3].contains(indent)) {
              return Container(
                height: 6,
                width: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                ),
              );
            }

            // -
            if ([1, 4].contains(indent)) {
              return Container(
                // 視覚補正
                margin: EdgeInsets.only(top: 2),
                height: 2,
                width: 8,
                color: Colors.black,
              );
            }

            // ○
            if ([2, 5].contains(indent)) {
              return Container(
                height: 6,
                width: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.black,
                    width: 1,
                  ),
                ),
              );
            }

            // ●
            return Container(
              height: 6,
              width: 6,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black,
              ),
            );
          },
        ));
  }
}
