// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
<<<<<<< HEAD
import 'package:google_fonts/google_fonts.dart';
import 'package:meta/meta.dart';
=======
>>>>>>> 43b3755ab6885cefbc829d9c75a26c7f68263d0a

/// Applies a Zefyr editor theme to descendant widgets.
///
/// Describes colors and typographic styles for an editor.
///
/// Descendant widgets obtain the current theme's [ZefyrThemeData] object using
/// [ZefyrTheme.of].
///
/// See also:
///
///   * [ZefyrThemeData], which describes actual configuration of a theme.
class ZefyrTheme extends InheritedWidget {
  final ZefyrThemeData data;

  /// Applies the given theme [data] to [child].
  ///
  /// The [data] and [child] arguments must not be null.
  ZefyrTheme({
    Key? key,
    required this.data,
    required Widget child,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(ZefyrTheme oldWidget) {
    return data != oldWidget.data;
  }

  /// The data from the closest [ZefyrTheme] instance that encloses the given
  /// context.
  ///
  /// Returns `null` if there is no [ZefyrTheme] in the given build context
  /// and [nullOk] is set to `true`. If [nullOk] is set to `false` (default)
  /// then this method asserts.
  static ZefyrThemeData? of(BuildContext context, {bool nullOk = false}) {
    final widget = context.dependOnInheritedWidgetOfExactType<ZefyrTheme>();
    if (widget == null && nullOk) return null;
    assert(widget != null,
        '$ZefyrTheme.of() called with a context that does not contain a ZefyrEditor.');
    return widget!.data;
  }
}

/// Vertical spacing around a block of text.
class VerticalSpacing {
  final double top;
  final double bottom;

  const VerticalSpacing({this.top = 0.0, this.bottom = 0.0});

  const VerticalSpacing.zero()
      : top = 0.0,
        bottom = 0.0;
}

class ZefyrThemeData {
  /// Style of bold text.
  final TextStyle bold;

  /// Style of italic text.
  final TextStyle italic;

  /// Style of underline text.
  final TextStyle underline;

  /// Style of strikethrough text.
  final TextStyle strikethrough;

<<<<<<< HEAD
  /// Style of textColor text.
  final TextStyle textColor;

  /// Style of marker text.
  final TextStyle marker;
=======
  /// Theme of inline code.
  final InlineCodeThemeData inlineCode;
>>>>>>> 43b3755ab6885cefbc829d9c75a26c7f68263d0a

  /// Style of links in text.
  final TextStyle link;

  /// Default style theme for regular paragraphs of text.
  final TextBlockTheme paragraph; // spacing: top: 6, bottom: 10
  /// Style theme for level 1 headings.
  final TextBlockTheme heading1;

  /// Style theme for level 2 headings.
  final TextBlockTheme heading2;

  /// Style theme for level 3 headings.
  final TextBlockTheme heading3;

  /// Style theme for caption headings.
  final TextBlockTheme caption;

  /// Style theme for bullet and number lists.
  final TextBlockTheme lists;

  /// Style theme for quote blocks.
  final TextBlockTheme quote;

  /// Style theme for code blocks.
  final TextBlockTheme code;

  final TextBlockTheme largeHeading;

  final TextBlockTheme middleHeading;

  final double indentWidth;

  ZefyrThemeData({
<<<<<<< HEAD
    this.bold,
    this.italic,
    this.underline,
    this.strikethrough,
    this.textColor,
    this.marker,
    this.link,
    this.paragraph,
    this.heading1,
    this.heading2,
    this.heading3,
    this.caption,
    this.lists,
    this.quote,
    this.code,
    this.largeHeading,
    this.middleHeading,
    this.indentWidth,
=======
    required this.bold,
    required this.italic,
    required this.underline,
    required this.strikethrough,
    required this.inlineCode,
    required this.link,
    required this.paragraph,
    required this.heading1,
    required this.heading2,
    required this.heading3,
    required this.lists,
    required this.quote,
    required this.code,
>>>>>>> 43b3755ab6885cefbc829d9c75a26c7f68263d0a
  });

  factory ZefyrThemeData.fallback(BuildContext context) {
    final themeData = Theme.of(context);
    final defaultStyle = DefaultTextStyle.of(context);

    return ZefyrThemeData(
<<<<<<< HEAD
      bold: GoogleFonts.notoSans(fontWeight: FontWeight.bold),
      italic: GoogleFonts.notoSans(fontStyle: FontStyle.italic),
      underline: GoogleFonts.notoSans(decoration: TextDecoration.underline),
      strikethrough: GoogleFonts.notoSans(decoration: TextDecoration.lineThrough),
      textColor: GoogleFonts.notoSans(color: Color(0xffFF5555)),
      marker: GoogleFonts.notoSans(
        decoration: TextDecoration.underline,
        decorationColor: Color(0xff0099DD).withOpacity(0.15),
        decorationThickness: 10,
      ),
      link: GoogleFonts.notoSans(
=======
      bold: TextStyle(fontWeight: FontWeight.bold),
      italic: TextStyle(fontStyle: FontStyle.italic),
      underline: TextStyle(decoration: TextDecoration.underline),
      strikethrough: TextStyle(decoration: TextDecoration.lineThrough),
      inlineCode: InlineCodeThemeData(TextStyle(
        color: Colors.blue.shade900.withOpacity(0.9),
        fontFamily: fontFamily,
      )),
      link: TextStyle(
>>>>>>> 43b3755ab6885cefbc829d9c75a26c7f68263d0a
        color: themeData.accentColor,
        decoration: TextDecoration.underline,
      ),
      paragraph: TextBlockTheme(
        style: GoogleFonts.notoSans(
          fontSize: 16.0,
          color: Colors.black,
          height: 1.5,
          fontWeight: FontWeight.w400,
        ),
        spacing: VerticalSpacing(top: 8.0, bottom: 0),
        // lineSpacing is not relevant for paragraphs since they consist of one line
      ),
      heading1: TextBlockTheme(
        style: defaultStyle.style.copyWith(
<<<<<<< HEAD
          fontSize: 24.0,
          color: Colors.black,
=======
          fontSize: 34.0,
          color: defaultStyle.style.color?.withOpacity(0.70),
>>>>>>> 43b3755ab6885cefbc829d9c75a26c7f68263d0a
          height: 1.15,
          fontWeight: FontWeight.w700,
        ),
        spacing: VerticalSpacing(top: 40.0, bottom: 0.0),
      ),
      heading2: TextBlockTheme(
<<<<<<< HEAD
        style: GoogleFonts.notoSans(
          fontSize: 20.0,
          color: Colors.black,
=======
        style: TextStyle(
          fontSize: 24.0,
          color: defaultStyle.style.color?.withOpacity(0.70),
>>>>>>> 43b3755ab6885cefbc829d9c75a26c7f68263d0a
          height: 1.15,
          fontWeight: FontWeight.w700,
        ),
        spacing: VerticalSpacing(top: 32.0, bottom: 0.0),
      ),
      heading3: TextBlockTheme(
<<<<<<< HEAD
        style: GoogleFonts.notoSans(
          fontSize: 18.0,
          color: Colors.black,
=======
        style: TextStyle(
          fontSize: 20.0,
          color: defaultStyle.style.color?.withOpacity(0.70),
>>>>>>> 43b3755ab6885cefbc829d9c75a26c7f68263d0a
          height: 1.25,
          fontWeight: FontWeight.w700,
        ),
        spacing: VerticalSpacing(top: 24.0, bottom: 0.0),
      ),
      caption: TextBlockTheme(
        style: GoogleFonts.notoSans(
          fontSize: 12.0,
          color: Color(0xFF999999),
          height: 1.25,
        ),
        spacing: VerticalSpacing(top: 4.0, bottom: 0.0),
      ),
      lists: TextBlockTheme(
        style: GoogleFonts.notoSans(
          fontSize: 16.0,
          color: Colors.black,
          height: 1.5,
          fontWeight: FontWeight.w400,
        ),
        spacing: VerticalSpacing(top: 8.0, bottom: 0),
        lineSpacing: VerticalSpacing(bottom: 8),
      ),
      quote: TextBlockTheme(
<<<<<<< HEAD
        style: GoogleFonts.notoSans(
          fontWeight: FontWeight.w400,
          fontSize: 16.0,
          color: Color(0xff999999),
        ),
        spacing: VerticalSpacing(top: 16.0, bottom: 0.0),
        lineSpacing: VerticalSpacing(top: 6, bottom: 2),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              width: 4,
              color: Color(0xffCCCCCC),
            ),
=======
        style: TextStyle(color: baseStyle.color?.withOpacity(0.6)),
        spacing: baseSpacing,
        lineSpacing: VerticalSpacing(top: 6, bottom: 2),
        decoration: BoxDecoration(
          border: BorderDirectional(
            start: BorderSide(width: 4, color: Colors.grey.shade300),
>>>>>>> 43b3755ab6885cefbc829d9c75a26c7f68263d0a
          ),
        ),
      ),
      code: TextBlockTheme(
        style: GoogleFonts.notoSans(
          color: Colors.black,
          fontWeight: FontWeight.w400,
          fontSize: 16.0,
          height: 1.15,
        ),
        spacing: VerticalSpacing(top: 16, bottom: 0),
        decoration: BoxDecoration(
          color: Color(0xffF1F1F1).withOpacity(0.8),
          border: Border.all(
            color: Color(0xffF1F1F1),
            width: 1,
          ),
        ),
      ),
      largeHeading: TextBlockTheme(
        style: GoogleFonts.notoSans(
          color: Colors.black,
          fontWeight: FontWeight.w700,
          fontSize: 20.0,
          height: 2,
        ),
        spacing: VerticalSpacing(top: 32, bottom: 4),
        lineSpacing: VerticalSpacing(top: 0, bottom: 0),
        decoration: BoxDecoration(
          color: Color(0xff0099dd).withAlpha(20),
        ),
      ),
      middleHeading: TextBlockTheme(
        style: GoogleFonts.notoSans(
          color: Colors.black,
          fontWeight: FontWeight.w700,
          fontSize: 18.0,
          height: 1.5,
        ),
        spacing: VerticalSpacing(top: 20, bottom: 12),
        lineSpacing: VerticalSpacing(top: 0, bottom: 15),
      ),
      indentWidth: 28,
    );
  }

  ZefyrThemeData copyWith({
<<<<<<< HEAD
    TextStyle bold,
    TextStyle italic,
    TextStyle underline,
    TextStyle strikethrough,
    TextStyle textColor,
    TextStyle marker,
    TextStyle link,
    TextBlockTheme paragraph,
    TextBlockTheme heading1,
    TextBlockTheme heading2,
    TextBlockTheme heading3,
    TextBlockTheme lists,
    TextBlockTheme quote,
    TextBlockTheme code,
    double indentWidth,
=======
    TextStyle? bold,
    TextStyle? italic,
    TextStyle? underline,
    TextStyle? strikethrough,
    TextStyle? link,
    InlineCodeThemeData? inlineCode,
    TextBlockTheme? paragraph,
    TextBlockTheme? heading1,
    TextBlockTheme? heading2,
    TextBlockTheme? heading3,
    TextBlockTheme? lists,
    TextBlockTheme? quote,
    TextBlockTheme? code,
>>>>>>> 43b3755ab6885cefbc829d9c75a26c7f68263d0a
  }) {
    return ZefyrThemeData(
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      underline: underline ?? this.underline,
      strikethrough: strikethrough ?? this.strikethrough,
<<<<<<< HEAD
      textColor: textColor ?? this.textColor,
      marker: marker ?? this.marker,
=======
      inlineCode: inlineCode ?? this.inlineCode,
>>>>>>> 43b3755ab6885cefbc829d9c75a26c7f68263d0a
      link: link ?? this.link,
      paragraph: paragraph ?? this.paragraph,
      heading1: heading1 ?? this.heading1,
      heading2: heading2 ?? this.heading2,
      heading3: heading3 ?? this.heading3,
      lists: lists ?? this.lists,
      quote: quote ?? this.quote,
      code: code ?? this.code,
      indentWidth: indentWidth ?? this.indentWidth,
    );
  }

  ZefyrThemeData merge(ZefyrThemeData other) {
    return copyWith(
      bold: other.bold,
      italic: other.italic,
      underline: other.underline,
      strikethrough: other.strikethrough,
<<<<<<< HEAD
      textColor: other.textColor,
      marker: other.marker,
=======
      inlineCode: other.inlineCode,
>>>>>>> 43b3755ab6885cefbc829d9c75a26c7f68263d0a
      link: other.link,
      paragraph: other.paragraph,
      heading1: other.heading1,
      heading2: other.heading2,
      heading3: other.heading3,
      lists: other.lists,
      quote: other.quote,
      code: other.code,
      indentWidth: other.indentWidth,
    );
  }
}

/// Style theme applied to a block of rich text, including single-line
/// paragraphs.
class TextBlockTheme {
  /// Base text style for a text block.
  final TextStyle style;

  /// Vertical spacing around a text block.
  final VerticalSpacing spacing;

  /// Vertical spacing for individual lines within a text block.
  ///
  final VerticalSpacing lineSpacing;

  /// Decoration of a text block.
  ///
  /// Decoration, if present, is painted in the content area, excluding
  /// any [spacing].
  final BoxDecoration? decoration;

  TextBlockTheme({
    required this.style,
    required this.spacing,
    this.lineSpacing = const VerticalSpacing.zero(),
    this.decoration,
  });
}

/// Theme data for inline code.
class InlineCodeThemeData {

  /// Base text style for an inline code.
  final TextStyle style;

  InlineCodeThemeData(this.style);
}
