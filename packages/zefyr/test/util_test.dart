// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:flutter_test/flutter_test.dart';
import 'package:quill_delta/quill_delta.dart';
import 'package:zefyr/util.dart';

void main() {
  group('getPositionDelta', () {
    test('actual has more characters inserted than user', () {
      final user = Delta()
        ..retain(7)
        ..insert('a');
      final actual = Delta()
        ..retain(7)
        ..insert('\na');
      final result = getPositionDelta(user, actual);
      expect(result, 1);
    });

    test('actual has less characters inserted than user', () {
      final user = Delta()
        ..retain(7)
        ..insert('abc');
      final actual = Delta()
        ..retain(7)
        ..insert('ab');
      final result = getPositionDelta(user, actual);
      expect(result, -1);
    });

    test('actual has less characters deleted than user', () {
      final user = Delta()
        ..retain(7)
        ..delete(3);
      final actual = Delta()
        ..retain(7)
        ..delete(2);
      final result = getPositionDelta(user, actual);
      expect(result, 1);
    });
  });

  group('findMatches', () {
    group('find lower case in UPPER CASE', () {
      test('a equal A', () {
        expect('ABC'.findMatches('a').length, 1);
      });
      test('ab equal AB', () {
        expect('ABC'.findMatches('ab').length, 1);
      });
    });
    group('find UPPER CASE in lower case', () {
      test('A equal a', () {
        expect('abc'.findMatches('A').length, 1);
      });
      test('AB equal ab', () {
        expect('abc'.findMatches('AB').length, 1);
      });
    });
    group('mix UPPER CASE and lower case', () {
      test('AbC equal abc', () {
        expect('AbC'.findMatches('abc').length, 1);
      });
      test('abc equal AbC', () {
        expect('abc'.findMatches('AbC').length, 1);
      });
    });
    group('find カタカナ in ひらがな', () {
      test('ア equal あ', () {
        expect('あいう'.findMatches('ア').length, 1);
      });
      test('アイ equal あい', () {
        expect('あいう'.findMatches('アイ').length, 1);
      });
    });
    group('find ひらがな in カタカナ', () {
      test('あ equal ア', () {
        expect('アイウ'.findMatches('あ').length, 1);
      });
      test('あい equal アイ', () {
        expect('アイウ'.findMatches('アイ').length, 1);
      });
    });
    group('mix ひらがな and カタカナ', () {
      test('アいウ equal アイウ', () {
        expect('アイウ'.findMatches('アいウ').length, 1);
      });
      test('アイウ equal アいウ', () {
        expect('アいウ'.findMatches('アイウ').length, 1);
      });
    });
    test('mix UPPER CASE, lower case, ひらがな and カタカナ', () {
      expect('AbCアいウ'.findMatches('アイウ').length, 1);
      expect('AbCアいウ'.findMatches('Bc').length, 1);
    });
  });
}
