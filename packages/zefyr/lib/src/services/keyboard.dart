// ignore_for_file: omit_local_variable_types
// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum CursorMovement { left, right, up, down }

/// Callback for cursor movement keyboard events.
///
/// The `key` parameter can be one of [LogicalKeyboardKey.arrowLeft],
/// [LogicalKeyboardKey.arrowRight], [LogicalKeyboardKey.arrowUp] or
/// [LogicalKeyboardKey.arrowDown].
typedef CursorMovementCallback = void Function(
  LogicalKeyboardKey key, {
  required bool wordModifier,
  required bool lineModifier,
  required bool shift,
});

enum InputShortcut { cut, copy, paste, selectAll }

typedef InputShortcutCallback = Future<void> Function(InputShortcut shortcut);
typedef OnDeleteCallback = void Function(bool forward);

final Set<LogicalKeyboardKey> _movementKeys = <LogicalKeyboardKey>{
  LogicalKeyboardKey.arrowRight,
  LogicalKeyboardKey.arrowLeft,
  LogicalKeyboardKey.arrowUp,
  LogicalKeyboardKey.arrowDown,
};

final Set<LogicalKeyboardKey> _shortcutKeys = <LogicalKeyboardKey>{
  LogicalKeyboardKey.keyA,
  LogicalKeyboardKey.keyC,
  LogicalKeyboardKey.keyV,
  LogicalKeyboardKey.keyX,
  LogicalKeyboardKey.delete,
  LogicalKeyboardKey.backspace,
};

final Set<LogicalKeyboardKey> _nonModifierKeys = <LogicalKeyboardKey>{
  ..._shortcutKeys,
  ..._movementKeys,
};

final Set<LogicalKeyboardKey> _modifierKeys = <LogicalKeyboardKey>{
  LogicalKeyboardKey.shift,
  LogicalKeyboardKey.control,
  LogicalKeyboardKey.alt,
};

final Set<LogicalKeyboardKey> _macOsModifierKeys = <LogicalKeyboardKey>{
  LogicalKeyboardKey.shift,
  LogicalKeyboardKey.meta,
  LogicalKeyboardKey.alt,
};

final Set<LogicalKeyboardKey> _interestingKeys = <LogicalKeyboardKey>{
  ..._modifierKeys,
  ..._macOsModifierKeys,
  ..._nonModifierKeys,
};

/// Keyboard listener for editable widgets.
class KeyboardListener {
  final CursorMovementCallback onCursorMovement;
  final InputShortcutCallback onShortcut;
  final OnDeleteCallback onDelete;

  KeyboardListener({
    required this.onCursorMovement,
    required this.onShortcut,
    required this.onDelete,
  });

  KeyEventResult handleKeyEvent(KeyEvent keyEvent) {
    if (kIsWeb) {
      // On web platform, we should ignore the key because it's processed already.
      return KeyEventResult.ignored;
    }

    if (keyEvent is! KeyDownEvent) return KeyEventResult.ignored;

    final Set<LogicalKeyboardKey> keysPressed =
        LogicalKeyboardKey.collapseSynonyms(
            HardwareKeyboard.instance.logicalKeysPressed);
    final LogicalKeyboardKey key = keyEvent.logicalKey;

    if (!_nonModifierKeys.contains(key) ||
        keysPressed.difference(_modifierKeys).length > 1 ||
        keysPressed.difference(_interestingKeys).isNotEmpty) {
      // If the most recently pressed key isn't a non-modifier key, or more than
      // one non-modifier key is down, or keys other than the ones we're interested in
      // are pressed, just ignore the keypress.
      return KeyEventResult.ignored;
    }

    if (_movementKeys.contains(key)) {
      onCursorMovement(key,
          wordModifier: HardwareKeyboard.instance.isControlPressed,
          lineModifier: HardwareKeyboard.instance.isAltPressed,
          shift: HardwareKeyboard.instance.isShiftPressed);
    } else if (HardwareKeyboard.instance.isControlPressed &&
        _shortcutKeys.contains(key)) {
      final _keyToShortcut = {
        LogicalKeyboardKey.keyX: InputShortcut.cut,
        LogicalKeyboardKey.keyC: InputShortcut.copy,
        LogicalKeyboardKey.keyV: InputShortcut.paste,
        LogicalKeyboardKey.keyA: InputShortcut.selectAll,
      };
      onShortcut(_keyToShortcut[key]!);
    } else if (key == LogicalKeyboardKey.delete) {
      onDelete(true);
    } else if (key == LogicalKeyboardKey.backspace) {
      onDelete(false);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }
}
