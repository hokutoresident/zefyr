import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:zefyr/src/widgets/baseline_proxy.dart';

import '../../zefyr.dart';
import '../services/keyboard.dart' as zefyr;
import 'editable_text_block.dart';
import 'editable_text_line.dart';
import 'editor_input_client_mixin.dart';
import 'editor_keyboard_mixin.dart';
import 'editor_selection_delegate_mixin.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'text_selection.dart';

class ToolbarOptions {
  const ToolbarOptions({
    this.copy = false,
    this.cut = false,
    this.paste = false,
    this.selectAll = false,
  });

  static const ToolbarOptions empty = ToolbarOptions();
  final bool copy;
  final bool cut;
  final bool paste;
  final bool selectAll;
}

/// Builder function for embeddable objects in [ZefyrEditor].
typedef ZefyrEmbedBuilder = Widget Function(
    BuildContext context, EmbedNode node);

typedef DragSelectionUpdateCallback = void Function(
    DragStartDetails startDetails, DragUpdateDetails updateDetails);

/// Default implementation of a builder function for embeddable objects in
/// Zefyr.
///
/// Only supports "horizontal rule" embeds.
Widget defaultZefyrEmbedBuilder(BuildContext context, EmbedNode node) {
  if (node.value.type == 'hr') {
    final theme = ZefyrTheme.of(context);
    return Divider(
      height: (theme.paragraph.style.fontSize ?? 0.0) *
          (theme.paragraph.style.height ?? 0.0),
      thickness: 2,
      color: Colors.grey.shade200,
    );
  }
  throw UnimplementedError(
      'Embeddable type "${node.value.type}" is not supported by default embed '
      'builder of ZefyrEditor. You must pass your own builder function to '
      'embedBuilder property of ZefyrEditor or ZefyrField widgets.');
}

/// Widget for editing rich text documents.
class ZefyrEditor extends StatefulWidget {
  /// Controller object which establishes a link between a rich text document
  /// and this editor.
  ///
  /// Must not be null.
  final ZefyrController controller;

  /// Controls whether this editor has keyboard focus.
  ///
  /// Can be `null` in which case this editor creates its own instance to
  /// control keyboard focus.
  final FocusNode? focusNode;

  /// The [ScrollController] to use when vertically scrolling the contents.
  ///
  /// If `null` then this editor instantiates a new ScrollController.
  ///
  /// Scroll controller must not be `null` if [scrollable] is set to `false`.
  final ScrollController? scrollController;

  /// Whether this editor should create a scrollable container for its content.
  ///
  /// When set to `true` the editor's height can be controlled by [minHeight],
  /// [maxHeight] and [expands] properties.
  ///
  /// When set to `false` the editor always expands to fit the entire content
  /// of the document and should normally be placed as a child of another
  /// scrollable widget, otherwise the content may be clipped.
  ///
  /// The [scrollController] property must not be `null` when this is set to
  /// `false`.
  ///
  /// Set to `true` by default.
  final bool scrollable;

  /// Additional inset to show cursor properly.
  final double scrollBottomInset;

  /// Additional space around the content of this editor.
  final EdgeInsetsGeometry padding;

  /// Whether this editor should focus itself if nothing else is already
  /// focused.
  ///
  /// If true, the keyboard will open as soon as this editor obtains focus.
  /// Otherwise, the keyboard is only shown after the user taps the editor.
  ///
  /// Defaults to `false`. Cannot be `null`.
  final bool autofocus;

  /// Whether to show cursor.
  ///
  /// The cursor refers to the blinking caret when the editor is focused.
  final bool showCursor;

  /// Whether the text can be changed.
  ///
  /// When this is set to `true`, the text cannot be modified
  /// by any shortcut or keyboard operation. The text is still selectable.
  ///
  /// Defaults to `false`. Must not be `null`.
  final bool readOnly;

  /// Whether to enable user interface affordances for changing the
  /// text selection.
  ///
  /// For example, setting this to true will enable features such as
  /// long-pressing the editor to select text and show the
  /// cut/copy/paste menu, and tapping to move the text cursor.
  ///
  /// When this is false, the text selection cannot be adjusted by
  /// the user, text cannot be copied, and the user cannot paste into
  /// the text field from the clipboard.
  final bool enableInteractiveSelection;

  /// The minimum height to be occupied by this editor.
  ///
  /// This only has effect if [scrollable] is set to `true` and [expands] is
  /// set to `false`.
  final double? minHeight;

  /// The maximum height to be occupied by this editor.
  ///
  /// This only has effect if [scrollable] is set to `true` and [expands] is
  /// set to `false`.
  final double? maxHeight;

  /// Whether this editor's height will be sized to fill its parent.
  ///
  /// This only has effect if [scrollable] is set to `true`.
  ///
  /// If expands is set to true and wrapped in a parent widget like [Expanded]
  /// or [SizedBox], the editor will expand to fill the parent.
  ///
  /// [maxHeight] and [minHeight] must both be `null` when this is set to
  /// `true`.
  ///
  /// Defaults to `false`.
  final bool expands;

  /// Configures how the platform keyboard will select an uppercase or
  /// lowercase keyboard.
  ///
  /// Only supports text keyboards, other keyboard types will ignore this
  /// configuration. Capitalization is locale-aware.
  ///
  /// Defaults to [TextCapitalization.sentences]. Must not be `null`.
  final TextCapitalization textCapitalization;

  /// The appearance of the keyboard.
  ///
  /// This setting is only honored on iOS devices.
  ///
  /// Defaults to [Brightness.light].
  final Brightness keyboardAppearance;

  /// The [ScrollPhysics] to use when vertically scrolling the input.
  ///
  /// This only has effect if [scrollable] is set to `true`.
  ///
  /// If not specified, it will behave according to the current platform.
  ///
  /// See [Scrollable.physics].
  final ScrollPhysics? scrollPhysics;

  /// Callback to invoke when user wants to launch a URL.
  final ValueChanged<String>? onLaunchUrl;

  final void Function(EmbeddableObject, {required bool readOnly})?
      onTapEmbedObject;

  /// Builder function for embeddable objects.
  ///
  /// Defaults to [defaultZefyrEmbedBuilder].
  final ZefyrEmbedBuilder embedBuilder;

  ZefyrEditor({
    Key? key,
    required this.controller,
    this.focusNode,
    this.scrollController,
    this.scrollable = true,
    this.scrollBottomInset = 0,
    this.padding = EdgeInsets.zero,
    this.autofocus = false,
    this.showCursor = true,
    this.readOnly = false,
    this.enableInteractiveSelection = true,
    this.minHeight,
    this.maxHeight,
    this.expands = false,
    this.textCapitalization = TextCapitalization.sentences,
    this.keyboardAppearance = Brightness.light,
    this.scrollPhysics,
    this.onLaunchUrl,
    this.onTapEmbedObject,
    this.embedBuilder = defaultZefyrEmbedBuilder,
  }) : super(key: key);

  @override
  _ZefyrEditorState createState() => _ZefyrEditorState();
}

class _ZefyrEditorState extends State<ZefyrEditor>
    implements EditorTextSelectionGestureDetectorBuilderDelegate {
  final GlobalKey<EditorState> _editorKey = GlobalKey<EditorState>();

  @override
  GlobalKey<EditorState> get editableTextKey => _editorKey;

  // TODO: Add support for forcePress on iOS.
  @override
  bool get forcePressEnabled => false;

  @override
  bool get selectionEnabled => widget.enableInteractiveSelection;

  late EditorTextSelectionGestureDetectorBuilder
      _selectionGestureDetectorBuilder;

  void _requestKeyboard() {
    _editorKey.currentState?.requestKeyboard();
  }

  @override
  void initState() {
    super.initState();
    _selectionGestureDetectorBuilder =
        _ZefyrEditorSelectionGestureDetectorBuilder(state: this);
  }

  static const Set<TargetPlatform> _mobilePlatforms = {
    TargetPlatform.iOS,
    TargetPlatform.android
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectionTheme = TextSelectionTheme.of(context);

    TextSelectionControls textSelectionControls;
    bool paintCursorAboveText;
    bool cursorOpacityAnimates;
    Offset? cursorOffset;
    Color cursorColor;
    Color selectionColor;
    Radius? cursorRadius;

    final showSelectionHandles = _mobilePlatforms.contains(theme.platform);

    switch (theme.platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        final cupertinoTheme = CupertinoTheme.of(context);
        textSelectionControls = cupertinoTextSelectionControls;
        paintCursorAboveText = true;
        cursorOpacityAnimates = true;
        cursorColor = selectionTheme.cursorColor ?? cupertinoTheme.primaryColor;
        selectionColor = selectionTheme.selectionColor ??
            cupertinoTheme.primaryColor.withOpacity(0.40);
        selectionColor = selectionTheme.selectionColor ??
            cupertinoTheme.primaryColor.withOpacity(0.40);
        cursorRadius ??= const Radius.circular(2.0);
        cursorOffset = Offset(
            iOSHorizontalOffset / MediaQuery.of(context).devicePixelRatio, 0);
        break;

      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        textSelectionControls = materialTextSelectionControls;
        paintCursorAboveText = false;
        cursorOpacityAnimates = false;
        cursorColor = selectionTheme.cursorColor ?? theme.colorScheme.primary;
        selectionColor = selectionTheme.selectionColor ??
            theme.colorScheme.primary.withOpacity(0.40);
        break;
    }

    final child = RawEditor(
      key: _editorKey,
      controller: widget.controller,
      focusNode: widget.focusNode!,
      scrollController: widget.scrollController,
      scrollable: widget.scrollable,
      padding: widget.padding,
      autofocus: widget.autofocus,
      showCursor: widget.showCursor,
      readOnly: widget.readOnly,
      enableInteractiveSelection: widget.enableInteractiveSelection,
      minHeight: widget.minHeight,
      maxHeight: widget.maxHeight,
      expands: widget.expands,
      textCapitalization: widget.textCapitalization,
      keyboardAppearance: widget.keyboardAppearance,
      scrollPhysics: widget.scrollPhysics,
      onLaunchUrl: widget.onLaunchUrl,
      onTapEmbedObject: widget.onTapEmbedObject,
      embedBuilder: widget.embedBuilder,
      // encapsulated fields below
      cursorStyle: CursorStyle(
        color: cursorColor,
        backgroundColor: Colors.grey,
        width: 2.0,
        radius: cursorRadius,
        offset: cursorOffset,
        paintAboveText: paintCursorAboveText,
        opacityAnimates: cursorOpacityAnimates,
      ),
      selectionColor: selectionColor,
      showSelectionHandles: showSelectionHandles,
      selectionControls: textSelectionControls,
    );

    return _selectionGestureDetectorBuilder.buildGestureDetector(
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }
}

class _ZefyrEditorSelectionGestureDetectorBuilder
    extends EditorTextSelectionGestureDetectorBuilder {
  _ZefyrEditorSelectionGestureDetectorBuilder({
    required _ZefyrEditorState state,
  })  : _state = state,
        super(delegate: state);

  final _ZefyrEditorState _state;

  @override
  void onForcePressStart(ForcePressDetails details) {
    super.onForcePressStart(details);
    if (delegate.selectionEnabled && shouldShowSelectionToolbar) {
      editor?.showToolbar();
    }
  }

  @override
  void onForcePressEnd(ForcePressDetails details) {
    // Not required.
  }

  @override
  void onSingleLongTapMoveUpdate(LongPressMoveUpdateDetails details) {
    if (delegate.selectionEnabled) {
      switch (Theme.of(_state.context).platform) {
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          renderEditor?.selectPositionAt(
            from: details.globalPosition,
            cause: SelectionChangedCause.longPress,
          );
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          renderEditor?.selectWordsInRange(
            from: details.globalPosition - details.offsetFromOrigin,
            to: details.globalPosition,
            cause: SelectionChangedCause.longPress,
          );
          break;
      }
    }
  }

  void _launchUrlIfNeeded(TapUpDetails details) {
    final pos = renderEditor?.getPositionForOffset(details.globalPosition);
    final result = editor?.widget.controller.document.lookupLine(pos!.offset);
    if (result?.node == null) return;
    final line = result!.node as LineNode;
    if (line.hasEmbed) {
      final embed = line.children.single as EmbedNode;
      editor?.widget.onTapEmbedObject
          ?.call(embed.value, readOnly: _state.widget.readOnly);
    }
    final segmentResult = line.lookup(result.offset);
    if (segmentResult.node == null) return;
    final segment = segmentResult.node as LeafNode;
    if (segment.style.contains(NotusAttribute.link) &&
        editor?.widget.onLaunchUrl != null) {
      editor
          ?.widget.onLaunchUrl!(segment.style.get(NotusAttribute.link)!.value!);
    }
  }

  @override
  void onSingleTapUp(TapUpDetails details) {
    editor?.hideToolbar();

    // TODO: Explore if we can forward tap up events to the TextSpan gesture detector
    _launchUrlIfNeeded(details);

    if (delegate.selectionEnabled) {
      switch (Theme.of(_state.context).platform) {
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          switch (details.kind) {
            case PointerDeviceKind.mouse:
            case PointerDeviceKind.stylus:
            case PointerDeviceKind.invertedStylus:
              // Precise devices should place the cursor at a precise position.
              renderEditor?.selectPosition(cause: SelectionChangedCause.tap);
              break;
            case PointerDeviceKind.touch:
            case PointerDeviceKind.trackpad:
            case PointerDeviceKind.unknown:
              // On macOS/iOS/iPadOS a touch tap places the cursor at the edge
              // of the word.
              renderEditor?.selectWordEdge(cause: SelectionChangedCause.tap);
              break;
          }
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          renderEditor?.selectPosition(cause: SelectionChangedCause.tap);
          break;
      }
    }
    _state._requestKeyboard();
    // 遅延実行しないと動かない
    Future.delayed(const Duration(milliseconds: 100)).whenComplete(() {
      editor?.showCaretOnScreen();
    });
    // if (_state.widget.onTap != null)
    //   _state.widget.onTap();
  }

  @override
  void onSingleLongTapStart(LongPressStartDetails details) {
    if (delegate.selectionEnabled) {
      switch (Theme.of(_state.context).platform) {
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          renderEditor?.selectWord(cause: SelectionChangedCause.longPress);
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          renderEditor?.selectWord(cause: SelectionChangedCause.longPress);
          Feedback.forLongPress(_state.context);
          break;
      }
    }
  }
}

class RawEditor extends StatefulWidget {
  RawEditor({
    Key? key,
    required this.controller,
    required this.focusNode,
    this.scrollController,
    this.scrollable = true,
    this.padding = EdgeInsets.zero,
    this.autofocus = false,
    bool? showCursor,
    this.readOnly = false,
    this.enableInteractiveSelection = true,
    this.minHeight,
    this.maxHeight,
    this.expands = false,
    this.textCapitalization = TextCapitalization.none,
    this.keyboardAppearance = Brightness.light,
    this.onLaunchUrl,
    this.onTapEmbedObject,
    required this.selectionColor,
    this.scrollPhysics,
    this.toolbarOptions = const ToolbarOptions(
      copy: true,
      cut: true,
      paste: true,
      selectAll: true,
    ),
    this.cursorStyle,
    this.showSelectionHandles = false,
    this.selectionControls,
    this.embedBuilder = defaultZefyrEmbedBuilder,
  })  : assert(scrollable || scrollController != null),
        assert(maxHeight == null || maxHeight > 0),
        assert(minHeight == null || minHeight >= 0),
        assert(
          (maxHeight == null) ||
              (minHeight == null) ||
              (maxHeight >= minHeight),
          'minHeight can\'t be greater than maxHeight',
        ),
        // keyboardType = keyboardType ?? TextInputType.multiline,
        showCursor = showCursor ?? !readOnly,
        super(key: key);

  /// Controls the document being edited.
  final ZefyrController controller;

  /// Controls whether this editor has keyboard focus.
  final FocusNode focusNode;

  final ScrollController? scrollController;

  final bool scrollable;

  /// Additional space around the editor contents.
  final EdgeInsetsGeometry padding;

  /// Whether the text can be changed.
  ///
  /// When this is set to true, the text cannot be modified
  /// by any shortcut or keyboard operation. The text is still selectable.
  ///
  /// Defaults to false. Must not be null.
  final bool readOnly;

  /// Callback which is triggered when the user wants to open a URL from
  /// a link in the document.
  final ValueChanged<String>? onLaunchUrl;

  final void Function(EmbeddableObject, {required bool readOnly})?
      onTapEmbedObject;

  /// Configuration of toolbar options.
  ///
  /// By default, all options are enabled. If [readOnly] is true,
  /// paste and cut will be disabled regardless.
  final ToolbarOptions toolbarOptions;

  /// Whether to show selection handles.
  ///
  /// When a selection is active, there will be two handles at each side of
  /// boundary, or one handle if the selection is collapsed. The handles can be
  /// dragged to adjust the selection.
  ///
  /// See also:
  ///
  ///  * [showCursor], which controls the visibility of the cursor..
  final bool showSelectionHandles;

  /// Whether to show cursor.
  ///
  /// The cursor refers to the blinking caret when the editor is focused.
  ///
  /// See also:
  ///
  ///  * [cursorStyle], which controls the cursor visual representation.
  ///  * [showSelectionHandles], which controls the visibility of the selection
  ///    handles.
  final bool showCursor;

  /// The style to be used for the editing cursor.
  final CursorStyle? cursorStyle;

  /// Configures how the platform keyboard will select an uppercase or
  /// lowercase keyboard.
  ///
  /// Only supports text keyboards, other keyboard types will ignore this
  /// configuration. Capitalization is locale-aware.
  ///
  /// Defaults to [TextCapitalization.none]. Must not be null.
  ///
  /// See also:
  ///
  ///  * [TextCapitalization], for a description of each capitalization behavior.
  final TextCapitalization textCapitalization;

  /// The maximum height this editor can have.
  ///
  /// If this is null then there is no limit to the editor's height and it will
  /// expand to fill its parent.
  final double? maxHeight;

  /// The minimum height this editor can have.
  final double? minHeight;

  /// Whether this widget's height will be sized to fill its parent.
  ///
  /// If set to true and wrapped in a parent widget like [Expanded] or
  ///
  /// Defaults to false.
  final bool expands;

  /// Whether this editor should focus itself if nothing else is already
  /// focused.
  ///
  /// If true, the keyboard will open as soon as this text field obtains focus.
  /// Otherwise, the keyboard is only shown after the user taps the text field.
  ///
  /// Defaults to false. Cannot be null.
  final bool autofocus;

  /// The color to use when painting the selection.
  final Color selectionColor;

  /// Optional delegate for building the text selection handles and toolbar.
  ///
  /// The [RawEditor] widget used on its own will not trigger the display
  /// of the selection toolbar by itself. The toolbar is shown by calling
  /// [RawEditorState.showToolbar] in response to an appropriate user event.
  final TextSelectionControls? selectionControls;

  /// The appearance of the keyboard.
  ///
  /// This setting is only honored on iOS devices.
  ///
  /// Defaults to [Brightness.light].
  final Brightness keyboardAppearance;

  /// If true, then long-pressing this TextField will select text and show the
  /// cut/copy/paste menu, and tapping will move the text caret.
  ///
  /// True by default.
  ///
  /// If false, most of the accessibility support for selecting text, copy
  /// and paste, and moving the caret will be disabled.
  final bool enableInteractiveSelection;

  /// The [ScrollPhysics] to use when vertically scrolling the input.
  ///
  /// If not specified, it will behave according to the current platform.
  ///
  /// See [Scrollable.physics].
  final ScrollPhysics? scrollPhysics;

  /// Builder function for embeddable objects.
  ///
  /// Defaults to [defaultZefyrEmbedBuilder].
  final ZefyrEmbedBuilder embedBuilder;

  bool get selectionEnabled => enableInteractiveSelection;

  @override
  State<RawEditor> createState() {
    return RawEditorState();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<ZefyrController>('controller', controller));
    properties.add(DiagnosticsProperty<FocusNode>('focusNode', focusNode));
    properties.add(DoubleProperty('maxLines', maxHeight, defaultValue: null));
    properties.add(DoubleProperty('minLines', minHeight, defaultValue: null));
    properties.add(
        DiagnosticsProperty<bool>('autofocus', autofocus, defaultValue: false));
    properties.add(DiagnosticsProperty<ScrollPhysics>(
        'scrollPhysics', scrollPhysics,
        defaultValue: null));
  }
}

/// Base interface for the editor state which defines contract used by
/// various mixins.
///
/// Following mixins rely on this interface:
///
///   * [RawEditorStateKeyboardMixin],
///   * [RawEditorStateTextInputClientMixin]
///   * [RawEditorStateSelectionDelegateMixin]
///
abstract class EditorState extends State<RawEditor> {
  TextEditingValue get textEditingValue;
  set textEditingValue(TextEditingValue value);
  RenderEditor get renderEditor;
  EditorTextSelectionOverlay? get selectionOverlay;
  bool showToolbar();
  void hideToolbar();
  void requestKeyboard();
  void showCaretOnScreen();
}

class RawEditorState extends EditorState
    with
        AutomaticKeepAliveClientMixin<RawEditor>,
        WidgetsBindingObserver,
        TickerProviderStateMixin<RawEditor>,
        RawEditorStateKeyboardMixin,
        RawEditorStateTextInputClientMixin,
        RawEditorStateSelectionDelegateMixin
    implements TextSelectionDelegate {
  final GlobalKey _editorKey = GlobalKey();

  // Theme
  late ZefyrThemeData _themeData;

  // Cursors
  late CursorController _cursorController;
  // ignore: unused_field
  FloatingCursorController? _floatingCursorController;

  // Keyboard
  late zefyr.KeyboardListener _keyboardListener;

  // Selection overlay
  @override
  EditorTextSelectionOverlay? get selectionOverlay => _selectionOverlay;
  EditorTextSelectionOverlay? _selectionOverlay;

  ScrollController? _scrollController;

  final ClipboardStatusNotifier? _clipboardStatus =
      kIsWeb ? null : ClipboardStatusNotifier();
  final LayerLink _toolbarLayerLink = LayerLink();
  final LayerLink _startHandleLayerLink = LayerLink();
  final LayerLink _endHandleLayerLink = LayerLink();

  bool _didAutoFocus = false;
  FocusAttachment? _focusAttachment;
  bool get _hasFocus => widget.focusNode.hasFocus;

  String _searchQuery = '';
  Match? _searchFocus;

  @override
  bool get wantKeepAlive => widget.focusNode.hasFocus;

  TextDirection get _textDirection {
    final result = Directionality.of(context);
    return result;
  }

  /// The renderer for this widget's editor descendant.
  ///
  /// This property is typically used to notify the renderer of input gestures.
  @override
  RenderEditor get renderEditor =>
      _editorKey.currentContext!.findRenderObject() as RenderEditor;

  /// Express interest in interacting with the keyboard.
  ///
  /// If this control is already attached to the keyboard, this function will
  /// request that the keyboard become visible. Otherwise, this function will
  /// ask the focus system that it become focused. If successful in acquiring
  /// focus, the control will then attach to the keyboard and request that the
  /// keyboard become visible.
  @override
  void requestKeyboard() {
    if (_hasFocus) {
      openConnectionIfNeeded();
    } else {
      widget.focusNode.requestFocus();
    }
  }

  /// Shows the selection toolbar at the location of the current cursor.
  ///
  /// Returns `false` if a toolbar couldn't be shown, such as when the toolbar
  /// is already shown, or when no text selection currently exists.
  @override
  bool showToolbar() {
    // Web is using native dom elements to enable clipboard functionality of the
    // toolbar: copy, paste, select, cut. It might also provide additional
    // functionality depending on the browser (such as translate). Due to this
    // we should not show a Flutter toolbar for the editable text elements.
    if (kIsWeb) {
      return false;
    }

    if (_selectionOverlay == null || _selectionOverlay!.toolbarIsVisible) {
      return false;
    }

    _selectionOverlay!.showToolbar();
    return true;
  }

  void _updateSelectionOverlayForScroll() {
    _selectionOverlay?.updateForScroll();
  }

  // State lifecycle:

  @override
  void initState() {
    super.initState();

    widget.controller.onChangeSearchFocus.stream.listen((focus) {
      setState(() {
        _searchFocus = focus;
      });
      _showSearchFocus();
    });

    widget.controller.onChangeSearchFocusTop.stream.listen((focus) {
      setState(() {
        _searchFocus = focus;
      });
      _showSearchFocus(isScrollTop: true);
    });

    widget.controller.onChangeSearchQuery.stream.listen((query) {
      setState(() {
        _searchQuery = query;
      });
    });

    _clipboardStatus?.addListener(_onChangedClipboardStatus);

    widget.controller.addListener(_didChangeTextEditingValue);

    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController!.addListener(_updateSelectionOverlayForScroll);

    // Cursor
    _cursorController = CursorController(
      showCursor: ValueNotifier<bool>(widget.showCursor),
      style: widget.cursorStyle ??
          CursorStyle(
            // TODO: fallback to current theme's accent color
            color: Colors.blueAccent,
            backgroundColor: Colors.grey,
            width: 2.0,
          ),
      tickerProvider: this,
    );

    // Keyboard
    _keyboardListener = zefyr.KeyboardListener(
      onCursorMovement: handleCursorMovement,
      onShortcut: handleShortcut,
      onDelete: handleDelete,
    );

    // Focus
    _focusAttachment = widget.focusNode.attach(context,
        onKeyEvent: (node, event) => _keyboardListener.handleKeyEvent(event));
    widget.focusNode.addListener(_handleFocusChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final parentTheme = ZefyrTheme.maybeOf(context);
    final fallbackTheme = ZefyrThemeData.fallback(context);
    _themeData = (parentTheme != null)
        ? fallbackTheme.merge(parentTheme)
        : fallbackTheme;

    if (!_didAutoFocus && widget.autofocus) {
      FocusScope.of(context).autofocus(widget.focusNode);
      _didAutoFocus = true;
    }
  }

  bool _shouldShowSelectionHandles() {
    return widget.showSelectionHandles &&
        !widget.controller.selection.isCollapsed;
  }

  @override
  void didUpdateWidget(RawEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    _cursorController.showCursor.value = widget.showCursor;
    _cursorController.style = widget.cursorStyle!;

    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_didChangeTextEditingValue);
      widget.controller.addListener(_didChangeTextEditingValue);
      updateRemoteValueIfNeeded();
    }

    if (widget.scrollController != null &&
        widget.scrollController != _scrollController) {
      _scrollController!.removeListener(_updateSelectionOverlayForScroll);
      _scrollController = widget.scrollController;
      _scrollController!.addListener(_updateSelectionOverlayForScroll);
    }

    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode.removeListener(_handleFocusChanged);
      _focusAttachment?.detach();
      _focusAttachment = widget.focusNode.attach(context,
          onKeyEvent: (node, event) => _keyboardListener.handleKeyEvent(event));
      widget.focusNode.addListener(_handleFocusChanged);
      updateKeepAlive();
    }

    if (widget.controller.selection != oldWidget.controller.selection) {
      _selectionOverlay?.update(textEditingValue);
    }

    _selectionOverlay?.handlesVisible = _shouldShowSelectionHandles();
    if (!shouldCreateInputConnection) {
      closeConnectionIfNeeded();
    } else {
      if (oldWidget.readOnly && _hasFocus) {
        openConnectionIfNeeded();
      }
    }

//    if (widget.style != oldWidget.style) {
//      final TextStyle style = widget.style;
//      _textInputConnection?.setStyle(
//        fontFamily: style.fontFamily,
//        fontSize: style.fontSize,
//        fontWeight: style.fontWeight,
//        textDirection: _textDirection,
//        textAlign: widget.textAlign,
//      );
//    }
  }

  @override
  void dispose() {
    closeConnectionIfNeeded();
    assert(!hasConnection);
    _selectionOverlay?.dispose();
    _selectionOverlay = null;
    widget.controller.removeListener(_didChangeTextEditingValue);
    widget.focusNode.removeListener(_handleFocusChanged);
    widget.controller.onChangeSearchFocus.close();
    widget.controller.onChangeSearchQuery.close();
    widget.controller.onChangeSearchFocusTop.close();
    _focusAttachment?.detach();
    _cursorController.dispose();
    _clipboardStatus?.removeListener(_onChangedClipboardStatus);
    _clipboardStatus?.dispose();
    super.dispose();
  }

  void _didChangeTextEditingValue() {
    requestKeyboard();

    showCaretOnScreen();
    updateRemoteValueIfNeeded();
    _cursorController.startOrStopCursorTimerIfNeeded(
        _hasFocus, widget.controller.selection);
    if (hasConnection) {
      // To keep the cursor from blinking while typing, we want to restart the
      // cursor timer every time a new character is typed.
      _cursorController.stopCursorTimer(resetCharTicks: false);
      _cursorController.startCursorTimer();
    }

    // Refresh selection overlay after the build step had a chance to
    // update and register all children of RenderEditor. Otherwise this will
    // fail in situations where a new line of text is entered, which adds
    // a new RenderEditableBox child. If we try to update selection overlay
    // immediately it'll not be able to find the new child since it hasn't been
    // built yet.
    SchedulerBinding.instance.addPostFrameCallback(
        (Duration _) => _updateOrDisposeSelectionOverlayIfNeeded());
//    _textChangedSinceLastCaretUpdate = true;

    setState(() {/* We use widget.controller.value in build(). */});
  }

  void _handleSelectionChanged(
      TextSelection selection, SelectionChangedCause cause) {
    widget.controller.updateSelection(selection, source: ChangeSource.local);

    _selectionOverlay?.handlesVisible = _shouldShowSelectionHandles();

    // This will show the keyboard for all selection changes on the
    // editor, not just changes triggered by user gestures.
    requestKeyboard();
  }

  void _handleFocusChanged() {
    openOrCloseConnection();
    _cursorController.startOrStopCursorTimerIfNeeded(
        _hasFocus, widget.controller.selection);
    _updateOrDisposeSelectionOverlayIfNeeded();
    if (_hasFocus) {
      // Listen for changing viewInsets, which indicates keyboard showing up.
      WidgetsBinding.instance.addObserver(this);
      showCaretOnScreen();
//      _lastBottomViewInset = WidgetsBinding.instance.window.viewInsets.bottom;
//      if (!_value.selection.isValid) {
      // Place cursor at the end if the selection is invalid when we receive focus.
//        _handleSelectionChanged(TextSelection.collapsed(offset: _value.text.length), renderEditable, null);
//      }
    } else {
      WidgetsBinding.instance.removeObserver(this);
      // TODO: teach editor about state of the toolbar and whether the user is in the middle of applying styles.
      //       this is needed because some buttons in toolbar can steal focus from the editor
      //       but we want to preserve the selection, maybe adjusting its style slightly.
      //
      // Clear the selection and composition state if this widget lost focus.
      // widget.controller.updateSelection(TextSelection.collapsed(offset: 0),
      //     source: ChangeSource.local);
//      _currentPromptRectRange = null;
    }
    updateKeepAlive();
  }

  void _updateOrDisposeSelectionOverlayIfNeeded() {
    if (_selectionOverlay != null) {
      if (_hasFocus) {
        _selectionOverlay!.update(textEditingValue);
      } else {
        _selectionOverlay!.dispose();
        _selectionOverlay = null;
      }
    } else if (_hasFocus) {
      _selectionOverlay?.hide();
      _selectionOverlay = null;

      if (widget.selectionControls != null) {
        _selectionOverlay = EditorTextSelectionOverlay(
          clipboardStatus: _clipboardStatus,
          context: context,
          value: textEditingValue,
          debugRequiredFor: widget,
          toolbarLayerLink: _toolbarLayerLink,
          startHandleLayerLink: _startHandleLayerLink,
          endHandleLayerLink: _endHandleLayerLink,
          renderObject: renderEditor,
          selectionControls: widget.selectionControls,
          selectionDelegate: this,
          dragStartBehavior: DragStartBehavior.start,
          // onSelectionHandleTapped: widget.onSelectionHandleTapped,
        );
        _selectionOverlay!.handlesVisible = _shouldShowSelectionHandles();
        _selectionOverlay!.showHandles();
        // if (widget.onSelectionChanged != null)
        //   widget.onSelectionChanged(selection, cause);
      }
    }
  }

  // Animation configuration for scrolling the caret back on screen.
  static const Duration _caretAnimationDuration = Duration(milliseconds: 100);
  static const Curve _caretAnimationCurve = Curves.fastOutSlowIn;

  bool _showCaretOnScreenScheduled = false;

  @override
  void showCaretOnScreen() {
    if (!widget.showCursor || _showCaretOnScreenScheduled) {
      return;
    }

    _showCaretOnScreenScheduled = true;
    Future.delayed(const Duration(milliseconds: 100)).whenComplete(() {
      _showCaretOnScreenScheduled = false;

      final viewport = RenderAbstractViewport.of(renderEditor);
      final editorOffset =
          renderEditor.localToGlobal(Offset(0.0, 0.0), ancestor: viewport);
      final offsetInViewport = _scrollController!.offset + editorOffset.dy;

      final offset = renderEditor.getOffsetToRevealCursor(
        _scrollController!.position.viewportDimension,
        _scrollController!.offset,
        offsetInViewport,
      );

      if (offset != null) {
        _scrollController!.animateTo(
          offset,
          duration: _caretAnimationDuration,
          curve: _caretAnimationCurve,
        );
      }
    });
  }

  void _showSearchFocus({bool isScrollTop = false}) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final viewport = RenderAbstractViewport.of(renderEditor);
    if (_searchFocus == null) return;
    final editorOffset =
        renderEditor.localToGlobal(Offset(0.0, 0.0), ancestor: viewport);
    final offsetInViewport = _scrollController!.offset + editorOffset.dy;
    final offset = renderEditor.getSelectionOffset(
      _scrollController!.position.viewportDimension,
      _scrollController!.offset,
      offsetInViewport,
      TextSelection(
          baseOffset: _searchFocus!.end, extentOffset: _searchFocus!.end),
      isScrollTop: isScrollTop,
    );
    if (offset == null) return;
    await _scrollController!.animateTo(
      offset,
      duration: _caretAnimationDuration,
      curve: _caretAnimationCurve,
    );
  }

  void _onChangedClipboardStatus() {
    setState(() {
      // Inform the widget that the value of clipboardStatus has changed.
    });
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    _focusAttachment!.reparent();
    super.build(context); // See AutomaticKeepAliveClientMixin.

    Widget child = CompositedTransformTarget(
      link: _toolbarLayerLink,
      child: Semantics(
//            onCopy: _semanticsOnCopy(controls),
//            onCut: _semanticsOnCut(controls),
//            onPaste: _semanticsOnPaste(controls),
        child: _Editor(
          key: _editorKey,
          document: widget.controller.document,
          selection: widget.controller.selection,
          hasFocus: _hasFocus,
          textDirection: _textDirection,
          startHandleLayerLink: _startHandleLayerLink,
          endHandleLayerLink: _endHandleLayerLink,
          onSelectionChanged: _handleSelectionChanged,
          padding: widget.padding,
          children: _buildChildren(context),
        ),
      ),
    );

    if (widget.scrollable) {
      /// Since [SingleChildScrollView] does not implement
      /// `computeDistanceToActualBaseline` it prevents the editor from
      /// providing its baseline metrics. To address this issue we wrap
      /// the scroll view with [BaselineProxy] which mimics the editor's
      /// baseline.
      // This implies that the first line has no styles applied to it.
      final baselinePadding =
          EdgeInsets.only(top: _themeData.paragraph.spacing.top);
      child = BaselineProxy(
        textStyle: _themeData.paragraph.style,
        padding: baselinePadding,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: widget.scrollPhysics,
          child: child,
        ),
      );
    }

    final constraints = widget.expands
        ? BoxConstraints.expand()
        : BoxConstraints(
            minHeight: widget.minHeight ?? 0.0,
            maxHeight: widget.maxHeight ?? double.infinity);

    return ZefyrTheme(
      data: _themeData,
      child: MouseRegion(
        cursor: SystemMouseCursors.text,
        child: Container(
          constraints: constraints,
          child: child,
        ),
      ),
    );
  }

  LookupResult? get _inputtingNodeLookup {
    if (inputtingTextEditingValue == null) return null;
    final length = inputtingTextEditingValue!.composing.end -
        inputtingTextEditingValue!.composing.start;
    if (length <= 0) return null;
    final lookupResult = widget.controller.document
        .lookupLine(inputtingTextEditingValue!.composing.start);
    return lookupResult;
  }

  TextRange? Function(Node node) _inputtingTextRange(LookupResult? lookup) {
    return (Node node) {
      if (lookup == null) return null;
      if (node is LineNode && node == lookup.node) {
        final textNode = node.lookup(lookup.offset);
        final length = inputtingTextEditingValue!.composing.end -
            inputtingTextEditingValue!.composing.start;
        return TextRange(start: textNode.offset, end: textNode.offset + length);
      }
      return null;
    };
  }

  List<Widget> _buildChildren(BuildContext context) {
    final result = <Widget>[];
    final lookup = _inputtingNodeLookup;
    final indentLevelCounts = <int, int>{};
    for (final node in widget.controller.document.root.children) {
      if (node is LineNode) {
        result.add(EditableTextLine(
          node: node,
          textDirection: _textDirection,
          indentWidth: _indentWidth(node, _themeData),
          spacing:
              _getSpacingForLine(node, _themeData, firstLine: result.isEmpty),
          cursorController: _cursorController,
          selection: widget.controller.selection,
          selectionColor: widget.selectionColor,
          enableInteractiveSelection: widget.enableInteractiveSelection,
          body: TextLine(
            node: node,
            textDirection: _textDirection,
            embedBuilder: widget.embedBuilder,
            inputtingTextRange: _inputtingTextRange(lookup)(node),
            lookupResult: lookup,
            searchQuery: _searchQuery,
            searchFocus: _searchFocus,
          ),
          hasFocus: _hasFocus,
          devicePixelRatio: MediaQuery.of(context).devicePixelRatio,
          uiExceptionStreamSink: widget.controller.uiExceptionStream.sink,
        ));
      } else if (node is BlockNode) {
        final block = node.style.get(NotusAttribute.block);
        result.add(EditableTextBlock(
          node: node,
          textDirection: _textDirection,
          spacing:
              _getSpacingForBlock(node, _themeData, firstLine: result.isEmpty),
          cursorController: _cursorController,
          selection: widget.controller.selection,
          selectionColor: widget.selectionColor,
          enableInteractiveSelection: widget.enableInteractiveSelection,
          hasFocus: _hasFocus,
          contentPadding:
              (block == NotusAttribute.block.code) ? EdgeInsets.all(8.0) : null,
          embedBuilder: widget.embedBuilder,
          inputtingTextRange: _inputtingTextRange(lookup),
          lookupResult: lookup,
          indentLevelCounts: indentLevelCounts,
          searchQuery: _searchQuery,
          searchFocus: _searchFocus,
          uiExceptionStreamSink: widget.controller.uiExceptionStream.sink,
        ));
      } else {
        throw StateError('Unreachable.');
      }
    }
    return result;
  }

  VerticalSpacing _getSpacingForLine(LineNode node, ZefyrThemeData theme,
      {bool firstLine = false}) {
    VerticalSpacing spacing;
    VerticalSpacing emptyLineSpacing;
    final style = node.style.get(NotusAttribute.heading);
    if (style == NotusAttribute.heading.level1) {
      spacing = theme.heading1.spacing;
      emptyLineSpacing = theme.heading1.emptyLineSpacing;
    } else if (style == NotusAttribute.heading.level2) {
      spacing = theme.heading2.spacing;
      emptyLineSpacing = theme.heading2.emptyLineSpacing;
    } else if (style == NotusAttribute.heading.level3) {
      spacing = theme.heading3.spacing;
      emptyLineSpacing = theme.heading3.emptyLineSpacing;
    } else if (style == NotusAttribute.caption) {
      spacing = theme.caption.spacing;
      emptyLineSpacing = theme.caption.emptyLineSpacing;
    } else {
      spacing = theme.paragraph.spacing;
      emptyLineSpacing = theme.paragraph.emptyLineSpacing;
    }

    final isEmptyLine = node.children.isEmpty;
    if (isEmptyLine) {
      spacing = emptyLineSpacing;
    }

    if (firstLine) {
      spacing = VerticalSpacing(
        top: theme.paragraph.spacing.top,
        bottom: spacing.bottom,
      );
    }
    return spacing;
  }

  VerticalSpacing _getSpacingForBlock(BlockNode node, ZefyrThemeData theme,
      {bool firstLine = false}) {
    VerticalSpacing spacing;
    final style = node.style.get(NotusAttribute.block);
    if (style == NotusAttribute.block.code) {
      spacing = theme.code.spacing;
    } else if (style == NotusAttribute.block.quote) {
      spacing = theme.quote.spacing;
    } else if (style == NotusAttribute.largeHeading) {
      spacing = theme.largeHeading.spacing;
    } else if (style == NotusAttribute.middleHeading) {
      spacing = theme.middleHeading.spacing;
    } else {
      spacing = theme.lists.spacing;
    }
    if (firstLine) {
      spacing = VerticalSpacing(
        top: theme.paragraph.spacing.top,
        bottom: spacing.bottom,
      );
    }
    return spacing;
  }

  double _indentWidth(StyledNode node, ZefyrThemeData theme) {
    final indentValue = node.style.get(NotusAttribute.indent)?.value ?? 0.0;
    return theme.indentWidth * indentValue;
  }

  @override
  void insertTextPlaceholder(Size size) {
    // TODO: implement insertTextPlaceholder
  }

  @override
  void removeTextPlaceholder() {
    // TODO: implement removeTextPlaceholder
  }

  @override
  void didChangeInputControl(
      TextInputControl? oldControl, TextInputControl? newControl) {
    /*
    The framework calls this method to notify that the text input control has been changed.
    The TextInputClient may switch to the new text input control by hiding the old and showing the new input control.
    */
  }

  @override
  void performSelector(String selectorName) {
    /*
    Performs the specified MacOS-specific selector from the NSStandardKeyBindingResponding protocol or user-specified selector from DefaultKeyBinding.Dict.
    */
  }

  @override
  void insertContent(KeyboardInsertedContent content) {
    // TODO: implement insertContent
  }

  @override
  bool get liveTextInputEnabled => false;
  
  @override
  bool get lookUpEnabled => true;
  
  @override
  bool get searchWebEnabled => true;
  
  @override
  bool get shareEnabled => true;
}

class _Editor extends MultiChildRenderObjectWidget {
  _Editor({
    required Key key,
    required List<Widget> children,
    required this.document,
    required this.textDirection,
    required this.hasFocus,
    required this.selection,
    required this.startHandleLayerLink,
    required this.endHandleLayerLink,
    required this.onSelectionChanged,
    this.padding = EdgeInsets.zero,
  }) : super(key: key, children: children);

  final NotusDocument document;
  final TextDirection textDirection;
  final bool hasFocus;
  final TextSelection selection;
  final LayerLink startHandleLayerLink;
  final LayerLink endHandleLayerLink;
  final TextSelectionChangedHandler onSelectionChanged;
  final EdgeInsetsGeometry padding;

  @override
  RenderEditor createRenderObject(BuildContext context) {
    return RenderEditor(
      document: document,
      textDirection: textDirection,
      hasFocus: hasFocus,
      selection: selection,
      startHandleLayerLink: startHandleLayerLink,
      endHandleLayerLink: endHandleLayerLink,
      onSelectionChanged: onSelectionChanged,
      padding: padding,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderEditor renderObject) {
    renderObject.document = document;
    renderObject.node = document.root;
    renderObject.textDirection = textDirection;
    renderObject.hasFocus = hasFocus;
    renderObject.selection = selection;
    renderObject.startHandleLayerLink = startHandleLayerLink;
    renderObject.endHandleLayerLink = endHandleLayerLink;
    renderObject.onSelectionChanged = onSelectionChanged;
    renderObject.padding = padding;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    // TODO
//    properties.add(EnumProperty<Axis>('direction', direction));
  }
}
