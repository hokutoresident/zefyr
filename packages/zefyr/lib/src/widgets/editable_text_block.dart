import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notus/notus.dart';
import 'package:zefyr/util.dart';

import '../rendering/editable_text_block.dart';
import 'cursor.dart';
import 'editable_text_line.dart';
import 'editor.dart';
import 'text_line.dart';
import 'theme.dart';

class EditableTextBlock extends StatelessWidget {
  final BlockNode node;
  final VerticalSpacing spacing;
  final CursorController cursorController;
  final TextSelection selection;
  final Color selectionColor;
  final bool enableInteractiveSelection;
  final bool hasFocus;
  final EdgeInsets? contentPadding;
  final ZefyrEmbedBuilder embedBuilder;
  final TextRange Function(Node node) inputtingTextRange;
  final LookupResult lookupResult;
  final Map<int, int> indentLevelCounts;
  final String searchQuery;

  EditableTextBlock({
    Key? key,
    required this.node,
    required this.spacing,
    required this.cursorController,
    required this.selection,
    required this.selectionColor,
    required this.enableInteractiveSelection,
    required this.hasFocus,
    required this.embedBuilder,
    this.contentPadding,
<<<<<<< HEAD
    @required this.embedBuilder,
    @required this.inputtingTextRange,
    @required this.lookupResult,
    @required this.indentLevelCounts,
    @required this.searchQuery,
  })  : assert(hasFocus != null),
        assert(embedBuilder != null),
        super(key: key);
=======
  }) : super(key: key);
>>>>>>> 3842ca0150178ce0428c059e516f8a05ebc1d2c6

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));

    final theme = ZefyrTheme.of(context)!;
    return _EditableBlock(
      node: node,
      padding: spacing,
      contentPadding: contentPadding,
      decoration: _getDecorationForBlock(node, theme) ?? BoxDecoration(),
      children: _buildChildren(context, indentLevelCounts),
    );
  }

<<<<<<< HEAD
  List<Widget> _buildChildren(BuildContext context, Map<int, int> indentLevelCounts) {
    final theme = ZefyrTheme.of(context);
=======
  List<Widget> _buildChildren(BuildContext context) {
    final theme = ZefyrTheme.of(context)!;
>>>>>>> 3842ca0150178ce0428c059e516f8a05ebc1d2c6
    final count = node.children.length;
    final children = <Widget>[];
    var index = 0;
    for (final line in node.children) {
      index++;
<<<<<<< HEAD
      children.add(EditableTextLine(
        node: line,
        textDirection: textDirection,
        spacing: _getSpacingForLine(line, index, count, theme),
        leading: _buildLeading(context, line, index, count, indentLevelCounts),
        bottom: _buildBottom(context, line),
        indentWidth: _styleIndentWidth() + _userIndentWidth(context, line),
        devicePixelRatio: MediaQuery.of(context).devicePixelRatio,
        body: TextLine(
          node: line,
          textDirection: textDirection,
          embedBuilder: embedBuilder,
          inputtingTextRange: inputtingTextRange(line),
          lookupResult: lookupResult,
          searchQuery: searchQuery,
=======
      final nodeTextDirection = getDirectionOfNode(line as LineNode);
      children.add(Directionality(
        textDirection: nodeTextDirection,
        child: EditableTextLine(
          node: line,
          spacing: _getSpacingForLine(line, index, count, theme),
          leading: _buildLeading(context, line, index, count),
          indentWidth: _getIndentWidth(),
          devicePixelRatio: MediaQuery.of(context).devicePixelRatio,
          body: TextLine(
            node: line,
            embedBuilder: embedBuilder,
          ),
          cursorController: cursorController,
          selection: selection,
          selectionColor: selectionColor,
          enableInteractiveSelection: enableInteractiveSelection,
          hasFocus: hasFocus,
>>>>>>> 3842ca0150178ce0428c059e516f8a05ebc1d2c6
        ),
      ));
    }
    return children.toList(growable: false);
  }

<<<<<<< HEAD
  Widget _buildLeading(
      BuildContext context, LineNode node, int index, int count, Map<int, int> indentLevelCounts) {
    final theme = ZefyrTheme.of(context);
=======
  Widget? _buildLeading(
      BuildContext context, LineNode node, int index, int count) {
    final theme = ZefyrTheme.of(context)!;
>>>>>>> 3842ca0150178ce0428c059e516f8a05ebc1d2c6
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
<<<<<<< HEAD
    } else if (block == NotusAttribute.largeHeading) {
      return Row(
        children: [
          Container(
            height: 120, // NOTE: 最大で3行まで装飾がつくようにしている
            width: 8,
            color: Color(0xFF0099DD),
          ),
        ],
=======
    } else if (block == NotusAttribute.block.code) {
      return _NumberPoint(
        index: index,
        count: count,
        style: theme.code.style
            .copyWith(color: theme.code.style.color?.withOpacity(0.4)),
        width: 32.0,
        padding: 16.0,
        withDot: false,
>>>>>>> 3842ca0150178ce0428c059e516f8a05ebc1d2c6
      );
    } else {
      return null;
    }
  }

  Widget _buildBottom(BuildContext context, LineNode node) {
    final theme = ZefyrTheme.of(context);
    final block = node.style.get(NotusAttribute.block);
    if (block == NotusAttribute.middleHeading) {
      return Divider(
        height: theme.paragraph.style.fontSize * theme.paragraph.style.height,
        thickness: 1,
        color: Color(0xFF0099DD),
      );
    }
    return null;
  }

  double _userIndentWidth(BuildContext context, LineNode node) {
    final theme = ZefyrTheme.of(context);
    final block = node.style.get(NotusAttribute.block);
    if (block == NotusAttribute.block.bulletList || block == NotusAttribute.block.numberList) {
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
      VerticalSpacing? lineSpacing;
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
      top = lineSpacing?.top;
      bottom = lineSpacing?.bottom;
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
  final VerticalSpacing padding;
  final Decoration decoration;
  final EdgeInsets? contentPadding;

  _EditableBlock({
    Key? key,
    required this.node,
    required this.decoration,
    required List<Widget> children,
    this.contentPadding,
    this.padding = const VerticalSpacing(),
  }) : super(key: key, children: children);

  EdgeInsets get _padding =>
      EdgeInsets.only(top: padding.top, bottom: padding.bottom);

  EdgeInsets get _contentPadding => contentPadding ?? EdgeInsets.zero;

  @override
  RenderEditableTextBlock createRenderObject(BuildContext context) {
    return RenderEditableTextBlock(
      node: node,
      textDirection: Directionality.of(context),
      padding: _padding,
      decoration: decoration,
      contentPadding: _contentPadding,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderEditableTextBlock renderObject) {
    renderObject.node = node;
    renderObject.textDirection = Directionality.of(context);
    renderObject.padding = _padding;
    renderObject.decoration = decoration;
    renderObject.contentPadding = _contentPadding;
  }
}

class _NumberPoint extends StatelessWidget {
  final int index;
<<<<<<< HEAD
  final int indent;
  final TextStyle style;
  final double width;
  final bool withDot;
  final double padding;
  final Map<int, int> indentLevelCounts;

  const _NumberPoint({
    Key key,
    @required this.index,
    @required this.indent,
    @required this.style,
    @required this.width,
    @required this.indentLevelCounts,
=======
  final int count;
  final double width;
  final bool withDot;
  final double padding;
  final TextStyle style;

  const _NumberPoint({
    Key? key,
    required this.index,
    required this.count,
    required this.width,
    required this.style,
>>>>>>> 3842ca0150178ce0428c059e516f8a05ebc1d2c6
    this.withDot = true,
    this.padding = 0.0,
  }) : super(key: key);

<<<<<<< HEAD
  // 以下のようにインデントするごとに数字をリセットしてる
  // 1.
  // 2.
  // 3.
  //   1.
  //   2.
  //     1.
  //     2.
=======
>>>>>>> 3842ca0150178ce0428c059e516f8a05ebc1d2c6
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
          style: GoogleFonts.notoSans(
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
<<<<<<< HEAD
      width: width,
      // 視覚補正
      padding: EdgeInsets.only(top: 1, right: 4),
      child: Text(
        _createNumberText(withDot, indent, count),
        textAlign: TextAlign.right,
        style: GoogleFonts.notoSans(
          color: style.color,
          fontSize: style.fontSize,
        ),
      ),
=======
      alignment: AlignmentDirectional.topEnd,
      width: width,
      padding: EdgeInsetsDirectional.only(end: padding),
      child: Text(withDot ? '$index.' : '$index', style: style),
>>>>>>> 3842ca0150178ce0428c059e516f8a05ebc1d2c6
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
      const nums = ['①', '②', '③', '④', '⑤', '⑥', '⑦', '⑧', '⑨', '⑩', '⑪', '⑫', '⑬', '⑭', '⑮', '⑯', '⑰', '⑱', '⑲', '⑳', '㉑', '㉒', '㉓', '㉔', '㉕', '㉖', '㉗', '㉘', '㉙', '㉚', '㉛', '㉜', '㉝', '㉞', '㉟', '㊱', '㊲', '㊳', '㊴', '㊵', '㊶', '㊷', '㊸', '㊹', '㊺', '㊻',' ㊼', '㊽', '㊾', '㊿'];
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
  final double width;
<<<<<<< HEAD
  final int indent;

  const _BulletPoint({
    Key key,
    @required this.style,
    @required this.width,
    @required this.indent,
=======
  final TextStyle style;

  const _BulletPoint({
    Key? key,
    required this.width,
    required this.style,
>>>>>>> 3842ca0150178ce0428c059e516f8a05ebc1d2c6
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 10, right: 10),
      alignment: AlignmentDirectional.topEnd,
      width: width,
<<<<<<< HEAD
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
      )
=======
      padding: EdgeInsetsDirectional.only(end: 13.0),
      child: Text('•', style: style),
>>>>>>> 3842ca0150178ce0428c059e516f8a05ebc1d2c6
    );
  }
}
