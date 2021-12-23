import 'package:flutter/material.dart';
import 'package:zefyr/zefyr.dart';

class HistoryButton extends StatelessWidget {

  const HistoryButton({
    required this.icon,
    required this.controller,
    required this.isEnabled,
    required this.isRedo,
  });

  final IconData icon;
  final ZefyrController controller;
  final bool isEnabled;
  final bool isRedo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // If the cursor is currently inside a code block we disable all
    // toggle style buttons (except the code block button itself) since there
    // is no point in applying styles to a unformatted block of text.
    // TODO: Add code block checks to heading and embed buttons as well.
    return ZIconButton(
      highlightElevation: 0,
      hoverElevation: 0,
      size: 32,
      icon: Icon(
        icon, 
        size: 18, 
        color: isEnabled
          ? theme.primaryIconTheme.color
          : theme.iconTheme.color,
      ),
      onPressed: isRedo ? controller.redo : controller.undo,
    );
  }
}

