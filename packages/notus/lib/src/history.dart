import 'package:notus/src/document.dart';
import 'package:quill_delta/quill_delta.dart';
import 'package:tuple/tuple.dart';

class History {
  History({
    this.ignoreChange = false,
    this.maxStack = 100,
    this.lastRecorded = 0,
  });

  /// record interval (ms)
  final int interval = 400;

  final HistoryStack stack = HistoryStack.empty();
  bool get hasUndo => stack.undo.isNotEmpty;
  bool get hasRedo => stack.redo.isNotEmpty;

  /// used for disable redo or undo function
  bool ignoreChange;

  int lastRecorded;

  /// max operation count for undo;
  final int maxStack;

  void handleDocChange(NotusChange change) {
    if (ignoreChange) return;
    if (change.source == ChangeSource.local) {
      record(change.change, change.before);
    } else {
      transform(change.change);
    }
  }

  void clear() {
    stack.clear();
  }

  void record(Delta change, Delta before) {
    if(change.isEmpty) return;
    stack.redo.clear();
    var undoDelta = change.invert(before);
    final timeStamp = DateTime.now().millisecondsSinceEpoch;

    if(lastRecorded + interval > timeStamp && stack.undo.isNotEmpty) {
      final lastDelta = stack.undo.removeLast();
      undoDelta = undoDelta.compose(lastDelta);
    } else {
      lastRecorded = timeStamp;
    }

    if(undoDelta.isEmpty) return;
    stack.undo.add(undoDelta);

    if(stack.undo.length > maxStack) {
      stack.undo.removeAt(0);
    }
  }

  ///
  /// It will override pre local undo delta,replaced by remote change
  ///
  void transform(Delta delta) {
    transformStack(stack.undo, delta);
    transformStack(stack.redo, delta);
  }

  void transformStack(List<Delta> stack, Delta delta) {
    for (var i = stack.length - 1; i >= 0; i -= 1) {
      final oldDelta = stack[i];
      stack[i] = delta.transform(oldDelta, true);
      delta = oldDelta.transform(delta, false);
      if (stack[i].length == 0) {
        stack.removeAt(i);
      }
    }
  }

  Tuple2<bool, int> _change(
    NotusDocument doc,
    List<Delta> source,
    List<Delta> dest,
  ) {
    if(source.isEmpty) {
      return const Tuple2(false, 0);
    }

    final delta = source.removeLast();
    // look for insert or delete
    var len = 0;
    final ops = delta.toList();
    
    // calculate cursor point
    ops.forEach((op) {
      if(op.key == Operation.insertKey) {
        len = op.length;
      } else if (op.key == Operation.deleteKey) {
        len = op.length * -1;
      }
    });
    final base = Delta.from(doc.toDelta());
    final inverseDelta = delta.invert(base);
    dest.add(inverseDelta);
    lastRecorded = 0;
    ignoreChange = true;
    doc.compose(delta, ChangeSource.local);
    ignoreChange = false;
    return Tuple2(true, len);
  }

  Tuple2<bool, int> undo(NotusDocument doc) {
    return _change(doc, stack.undo, stack.redo);
  }

  Tuple2<bool, int> redo(NotusDocument doc) {
    return _change(doc, stack.redo, stack.undo);
  }
}

class HistoryStack {
  HistoryStack.empty() 
    : undo = [], 
      redo = [];

  final List<Delta> undo;
  final List<Delta> redo;

  void clear() {
    undo.clear();
    redo.clear();
  }
}
