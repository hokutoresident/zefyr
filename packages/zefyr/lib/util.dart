// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Utility functions for Zefyr.
library zefyr.util;

import 'dart:math' as math;

import 'package:kana_kit/kana_kit.dart';
import 'package:quill_delta/quill_delta.dart';

export 'src/fast_diff.dart';

int getPositionDelta(Delta user, Delta actual) {
  final userIter = DeltaIterator(user);
  final actualIter = DeltaIterator(actual);
  var diff = 0;
  while (userIter.hasNext || actualIter.hasNext) {
    final length = math.min(userIter.peekLength(), actualIter.peekLength());
    final userOp = userIter.next(length);
    final actualOp = actualIter.next(length);
    assert(userOp.length == actualOp.length);
    if (userOp.key == actualOp.key) continue;
    if (userOp.isInsert && actualOp.isRetain) {
      diff -= userOp.length;
    } else if (userOp.isDelete && actualOp.isRetain) {
      diff += userOp.length;
    } else if (userOp.isRetain && actualOp.isInsert) {
      final opText = actualOp.data is String ? actualOp.data as String : '';
      if (opText.startsWith('\n')) {
        // At this point user input reached its end (retain). If a heuristic
        // rule inserts a new line we should keep cursor on it's original position.
        continue;
      }
      diff += actualOp.length;
    } else {
      // TODO: this likely needs to cover more edge cases.
    }
  }
  return diff;
}

extension StringEx on String {
  List<Match> findMatches(String query, [int matchOffset = 0]) {
    if (query.isEmpty) return [];
    return query.normalized()
        .allMatches(normalized(), matchOffset)
        .toList();
  }

  bool containsMatch(String query) {
    return normalized()
        .contains(query.normalized());
  }

  String normalized() {
    return KanaKit()
        .copyWithConfig(passKanji: true, passRomaji: true)
        .toKatakana(toLowerCase());
  }
}
