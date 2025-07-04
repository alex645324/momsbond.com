import 'package:flutter_test/flutter_test.dart';
import 'package:mvp_code/Database_logic/simple_matching.dart';

void main() {
  group('_extractQuestions helper (FAST)', () {
    test('includes all question sets 1,2,3', () {
      final userData = {
        'questionSet1': ['Q1'],
        'questionSet2': ['Q2a', 'Q2b'],
        'questionSet3': ['Q3'],
      };

      final questions = SimpleMatching.extractQuestionsPublic(userData);

      expect(questions, containsAll(['Q1', 'Q2a', 'Q2b', 'Q3']));
    });

    test('handles missing sets gracefully', () {
      final userData = {
        'questionSet2': 'SingleQ', // as string
      };

      final questions = SimpleMatching.extractQuestionsPublic(userData);

      expect(questions.length, 1);
      expect(questions.first, 'SingleQ');
    });
  });
} 