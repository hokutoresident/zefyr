import 'package:flutter/widgets.dart';

import '../rendering/paragraph_proxy.dart';

class RichTextProxy extends SingleChildRenderObjectWidget {
  /// Child argument should be an instance of RichText widget.
  RichTextProxy({
    required RichText child,
    required this.textStyle,
    required this.textDirection,
    required this.locale,
    required this.strutStyle,
    this.textScaler = TextScaler.noScaling,
    this.textWidthBasis = TextWidthBasis.parent,
    this.textHeightBehavior,
  }) : super(child: child);

  final TextStyle textStyle;
  final TextDirection? textDirection;
  final TextScaler textScaler;
  final Locale? locale;
  final StrutStyle strutStyle;
  final TextWidthBasis textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;

  @override
  RenderParagraphProxy createRenderObject(BuildContext context) {
    return RenderParagraphProxy(
      textStyle: textStyle,
      textDirection: textDirection,
      textScaler: textScaler,
      locale: locale,
      strutStyle: strutStyle,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderParagraphProxy renderObject) {
    renderObject.textStyle = textStyle;
    renderObject.textDirection = textDirection!;
    renderObject.textScaler = textScaler;
    renderObject.locale = locale;
    renderObject.strutStyle = strutStyle;
    renderObject.textWidthBasis = textWidthBasis;
    renderObject.textHeightBehavior = textHeightBehavior;
  }
}
