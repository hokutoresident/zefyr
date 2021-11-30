import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notus/notus.dart';

import 'editable_text_line.dart';
import 'editor.dart';
import 'embed_proxy.dart';
import 'rich_text_proxy.dart';
import 'theme.dart';

/// Line of text in Zefyr editor.
///
/// This widget allows to render non-editable line of rich text, but can be
/// wrapped with [EditableTextLine] which adds editing features.
class TextLine extends StatelessWidget {
  /// Line of text represented by this widget.
  final LineNode node;
  final TextDirection textDirection;
  final ZefyrEmbedBuilder embedBuilder;
  final TextRange inputtingTextRange;
  final LookupResult lookupResult;
  final String searchQuery;
  final Match searchFocus;

  const TextLine({
    Key key,
    @required this.node,
    this.textDirection,
    @required this.embedBuilder,
    this.inputtingTextRange,
    this.lookupResult,
    this.searchQuery,
    this.searchFocus,
  })  : assert(node != null),
        assert(embedBuilder != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));

    if (node.hasEmbed) {
      final embed = node.children.single as EmbedNode;
      return EmbedProxy(child: embedBuilder(context, embed));
    }
    final text = buildText(context, node);
    final strutStyle =
        StrutStyle.fromTextStyle(text.style, forceStrutHeight: true);
    return RichTextProxy(
      textStyle: text.style,
      textDirection: textDirection,
      strutStyle: strutStyle,
      locale: Localizations.localeOf(context),
      child: RichText(
        text: buildText(context, node),
        textDirection: textDirection,
        strutStyle: strutStyle,
        textScaleFactor: MediaQuery.textScaleFactorOf(context),
      ),
    );
  }

  TextRange _textNodeInputtingRange(LookupResult textNodeLookup, TextNode child){
    return  (textNodeLookup != null && textNodeLookup.node == child) ? inputtingTextRange : null;
  }

  TextSpan buildText(BuildContext context, LineNode node) {
    final theme = ZefyrTheme.of(context);
    final textNodeLookup = lookupResult != null && lookupResult.offset <= node.length ? node.lookup(lookupResult.offset) : null;
    final children = node.children
        .map((node) => _segmentToTextSpan(node, theme, _textNodeInputtingRange(textNodeLookup, node)))
        .toList(growable: false);
    return TextSpan(
      style: _getParagraphTextStyle(node.style, theme),
      children: children,
    );
  }

  List<TextSpan> _highlightTextSpans(String source, String query, TextStyle style, Node node) {
    if (query == null || query.isEmpty || !source.toLowerCase().contains(query.toLowerCase())) {
      return [ TextSpan(text: source) ];
    }
    final matches = query.toLowerCase().allMatches(source.toLowerCase());

    var lastMatchEnd = 0;

    final children = <TextSpan>[];
    for (var i = 0; i < matches.length; i++) {
      final match = matches.elementAt(i);

      if (match.start != lastMatchEnd) {
        children.add(TextSpan(
          text: source.substring(lastMatchEnd, match.start),
        ));
      }

      final isInThisMatch = match.start + node.documentOffset == searchFocus?.start &&
          match.end + node.documentOffset == searchFocus?.end;
      final isInThisTextLine = node.containsOffset(searchFocus?.start ?? -1);
      final isFocusing = isInThisMatch && isInThisTextLine;
      children.add(TextSpan(
        text: source.substring(match.start, match.end),
        style: style.copyWith(
            backgroundColor: isFocusing ? Color(0xff0099DD).withOpacity(0.60) : Color(0xff0099DD).withOpacity(0.20)),
      ));

      if (i == matches.length - 1 && match.end != source.length) {
        children.add(TextSpan(
          text: source.substring(match.end, source.length),
        ));
      }

      lastMatchEnd = match.end;
    }
    return children;
  }

  TextSpan _segmentToTextSpan(Node node, ZefyrThemeData theme, TextRange textRange) {
    final TextNode segment = node;
    final attrs = segment.style;

    try {
      if (searchQuery.isNotEmpty && segment.value.contains(searchQuery)) {
        final style = _getInlineTextStyle(attrs, theme).copyWith();
        return TextSpan(
          children: [
            TextSpan(
              children: _highlightTextSpans(segment.value, searchQuery, style, node),
            ),
          ],
          style: _getInlineTextStyle(attrs, theme),
        );
      }

      if (textRange != null) {
        final style = _getInlineTextStyle(attrs, theme);
        return TextSpan(
          children: [
            TextSpan(text: segment.value.substring(0, textRange.start)),
            TextSpan(
                text: segment.value.substring(textRange.start, textRange.end),
                style: style.copyWith(backgroundColor: const Color(0x220000FF))),
            TextSpan(
                text: segment.value
                    .substring(textRange.end, segment.value.length)),
          ],
          style: _getInlineTextStyle(attrs, theme),
        );
      }
    } catch (_) {
      return TextSpan(
        text: segment.value,
        style: _getInlineTextStyle(attrs, theme),
      );
    }

    return TextSpan(
      text: segment.value,
      style: _getInlineTextStyle(attrs, theme),
    );
  }

  TextStyle _getParagraphTextStyle(NotusStyle style, ZefyrThemeData theme) {
    var textStyle = TextStyle();
    final heading = node.style.get(NotusAttribute.heading);
    if (heading == NotusAttribute.heading.level1) {
      textStyle = textStyle.merge(theme.heading1.style);
    } else if (heading == NotusAttribute.heading.level2) {
      textStyle = textStyle.merge(theme.heading2.style);
    } else if (heading == NotusAttribute.heading.level3) {
      textStyle = textStyle.merge(theme.heading3.style);
    } else if (heading == NotusAttribute.heading.caption) {
      textStyle = textStyle.merge(theme.caption.style);
    } else {
      textStyle = textStyle.merge(theme.paragraph.style);
    }

    final block = style.get(NotusAttribute.block);
    if (block == NotusAttribute.block.quote) {
      textStyle = textStyle.merge(theme.quote.style);
    } else if (block == NotusAttribute.block.code) {
      textStyle = textStyle.merge(theme.code.style);
    } else if (block == NotusAttribute.largeHeading) {
      textStyle = textStyle.merge(theme.largeHeading.style);
    } else if (block == NotusAttribute.middleHeading) {
      textStyle = textStyle.merge(theme.middleHeading.style);
    } else if (block != null) {
      // lists
      textStyle = textStyle.merge(theme.lists.style);
    }

    return textStyle.merge(TextStyle(
      fontFamilyFallback: [GoogleFonts.workSans().fontFamily],
    ));
  }

  TextStyle _getInlineTextStyle(NotusStyle style, ZefyrThemeData theme) {
    var result = TextStyle();
    if (style.containsSame(NotusAttribute.bold)) {
      result = _mergeTextStyleWithDecoration(result, theme.bold);
    }
    if (style.containsSame(NotusAttribute.italic)) {
      result = _mergeTextStyleWithDecoration(result, theme.italic);
    }
    if (style.contains(NotusAttribute.link)) {
      result = _mergeTextStyleWithDecoration(result, theme.link);
    }
    if (style.contains(NotusAttribute.underline)) {
      result = _mergeTextStyleWithDecoration(result, theme.underline);
    }
    if (style.contains(NotusAttribute.strikethrough)) {
      result = _mergeTextStyleWithDecoration(result, theme.strikethrough);
    }
    if (style.contains(NotusAttribute.textColor)) {
      result = _mergeTextStyleWithDecoration(result, theme.textColor);
    }
    if (style.contains(NotusAttribute.marker)) {
      result = _mergeTextStyleWithDecoration(result, theme.marker);
    }

    return result;
  }

  TextStyle _mergeTextStyleWithDecoration(TextStyle a, TextStyle b) {
    var decorations = <TextDecoration>[];
    if (a.decoration != null) {
      decorations.add(a.decoration);
    }
    if (b.decoration != null) {
      decorations.add(b.decoration);
    }
    return a.merge(b).apply(decoration: TextDecoration.combine(decorations));
  }
}
