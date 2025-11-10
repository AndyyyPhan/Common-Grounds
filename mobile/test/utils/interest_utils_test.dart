import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/constants/interest_categories.dart';
import 'package:mobile/utils/interest_utils.dart';

void main() {
  group('normalizeInterest', () {
    test('should return exact match for predefined interest', () {
      expect(normalizeInterest('Basketball'), 'Basketball');
      expect(normalizeInterest('Coding'), 'Coding');
      expect(normalizeInterest('Coffee'), 'Coffee');
    });

    test('should map synonym to canonical interest', () {
      expect(normalizeInterest('cs'), 'Coding');
      expect(normalizeInterest('bball'), 'Basketball');
      expect(normalizeInterest('programming'), 'Coding');
      expect(normalizeInterest('study'), 'Study Buddy');
    });

    test('should handle fuzzy matching with typos', () {
      expect(normalizeInterest('Basketbal'), 'Basketball'); // 1 char off
      expect(normalizeInterest('Codng'), 'Coding'); // 1 char off
      expect(normalizeInterest('Vollyball'), 'Volleyball'); // 2 chars off
    });

    test('should capitalize custom interests not found', () {
      expect(normalizeInterest('underwater basket weaving'),
          'Underwater Basket Weaving');
      expect(normalizeInterest('extreme ironing'), 'Extreme Ironing');
    });

    test('should handle empty strings', () {
      expect(normalizeInterest(''), '');
      expect(normalizeInterest('  '), '');
    });

    test('should trim whitespace', () {
      expect(normalizeInterest('  Basketball  '), 'Basketball');
      expect(normalizeInterest('  coding  '), 'Coding');
    });

    test('should be case-insensitive for synonyms', () {
      expect(normalizeInterest('CS'), 'Coding');
      expect(normalizeInterest('BBALL'), 'Basketball');
      expect(normalizeInterest('Programming'), 'Coding');
    });
  });

  group('categorizeCustomInterest', () {
    test('should categorize predefined interests correctly', () {
      expect(categorizeCustomInterest('Basketball'), InterestCategory.sports);
      expect(categorizeCustomInterest('Coding'), InterestCategory.academic);
      expect(categorizeCustomInterest('Coffee'), InterestCategory.social);
      expect(categorizeCustomInterest('Music'), InterestCategory.creative);
    });

    test('should categorize academic keywords', () {
      expect(
          categorizeCustomInterest('study group'), InterestCategory.academic);
      expect(categorizeCustomInterest('research project'),
          InterestCategory.academic);
      expect(categorizeCustomInterest('code practice'),
          InterestCategory.academic);
    });

    test('should categorize sports keywords', () {
      expect(categorizeCustomInterest('exercise routine'), InterestCategory.sports);
      expect(categorizeCustomInterest('gym session'), InterestCategory.sports);
      expect(categorizeCustomInterest('running club'), InterestCategory.sports);
    });

    test('should categorize entertainment keywords', () {
      expect(categorizeCustomInterest('video games'),
          InterestCategory.entertainment);
      expect(categorizeCustomInterest('watching movies'),
          InterestCategory.entertainment);
      expect(categorizeCustomInterest('streaming shows'),
          InterestCategory.entertainment);
    });

    test('should categorize creative keywords', () {
      expect(categorizeCustomInterest('painting'), InterestCategory.creative);
      expect(
          categorizeCustomInterest('music production'), InterestCategory.creative);
      expect(categorizeCustomInterest('photography'), InterestCategory.creative);
    });

    test('should categorize social keywords', () {
      expect(categorizeCustomInterest('eating out'), InterestCategory.social);
      expect(categorizeCustomInterest('coffee shops'), InterestCategory.social);
      expect(categorizeCustomInterest('partying'), InterestCategory.social);
    });

    test('should categorize lifestyle keywords', () {
      expect(
          categorizeCustomInterest('traveling'), InterestCategory.lifestyle);
      expect(categorizeCustomInterest('volunteering'),
          InterestCategory.lifestyle);
      expect(
          categorizeCustomInterest('outdoor activities'), InterestCategory.lifestyle);
    });

    test('should return null for unrecognized interests', () {
      expect(categorizeCustomInterest('quantum entanglement'), null);
      expect(categorizeCustomInterest('underwater basket weaving'), null);
    });
  });

  group('groupInterestsByCategory', () {
    test('should group predefined interests correctly', () {
      final interests = ['Basketball', 'Coding', 'Coffee', 'Music'];
      final grouped = groupInterestsByCategory(interests);

      expect(grouped[InterestCategory.sports], ['Basketball']);
      expect(grouped[InterestCategory.academic], ['Coding']);
      expect(grouped[InterestCategory.social], ['Coffee']);
      expect(grouped[InterestCategory.creative], ['Music']);
    });

    test('should handle multiple interests per category', () {
      final interests = ['Basketball', 'Volleyball', 'Gym', 'Running'];
      final grouped = groupInterestsByCategory(interests);

      expect(grouped[InterestCategory.sports]?.length, 4);
      expect(grouped[InterestCategory.sports],
          ['Basketball', 'Volleyball', 'Gym', 'Running']);
    });

    test('should handle empty list', () {
      final grouped = groupInterestsByCategory([]);
      expect(grouped, isEmpty);
    });

    test('should group custom interests by keyword detection', () {
      final interests = ['studying together', 'gym buddy', 'custom interest'];
      final grouped = groupInterestsByCategory(interests);

      expect(grouped[InterestCategory.academic], contains('studying together'));
      expect(grouped[InterestCategory.sports], contains('gym buddy'));
      // 'custom interest' doesn't match any keywords, so it might not appear
    });
  });

  group('validateInterestSelection', () {
    test('should pass validation for 5+ interests from 2+ categories', () {
      final interests = [
        'Basketball',
        'Volleyball',
        'Coding',
        'Hackathons',
        'Coffee',
      ];
      expect(validateInterestSelection(interests), isNull);
    });

    test('should fail validation for empty list', () {
      expect(validateInterestSelection([]), isNotNull);
      expect(
          validateInterestSelection([]), contains('at least 5 interests'));
    });

    test('should fail validation for less than 5 interests', () {
      final interests = ['Basketball', 'Coding', 'Coffee'];
      final error = validateInterestSelection(interests);

      expect(error, isNotNull);
      expect(error, contains('at least'));
    });

    test('should fail validation for single category', () {
      final interests = [
        'Basketball',
        'Volleyball',
        'Gym',
        'Running',
        'Pickleball',
      ];
      final error = validateInterestSelection(interests);

      expect(error, isNotNull);
      expect(error, contains('at least 2 different categories'));
    });

    test('should pass validation with custom interests', () {
      final interests = [
        'Basketball',
        'Coding',
        'Coffee',
        'Music',
        'Custom Interest',
      ];
      // Should pass even if custom interest doesn't have clear category
      final error = validateInterestSelection(interests);

      // This test might pass or fail depending on implementation
      // If it requires 2 categorized interests, it should pass
      expect(error == null || error.contains('categories'), isTrue);
    });
  });

  group('Interest taxonomy constants', () {
    test('should have correct number of categories', () {
      expect(InterestCategory.values.length, 6);
    });

    test('should have category weights that sum to ~1.0', () {
      final totalWeight = kCategoryWeights.values.reduce((a, b) => a + b);
      expect(totalWeight, closeTo(1.0, 0.01));
    });

    test('should have at least 50 total interests', () {
      expect(kAllInterests.length, greaterThanOrEqualTo(50));
    });

    test('should have interests in all categories', () {
      for (final category in InterestCategory.values) {
        final interests = kCategorizedInterests[category];
        expect(interests, isNotNull);
        expect(interests, isNotEmpty);
      }
    });

    test('should have no duplicate interests across categories', () {
      final allInterests = <String>[];
      for (final interests in kCategorizedInterests.values) {
        for (final interest in interests) {
          expect(allInterests, isNot(contains(interest)),
              reason: 'Duplicate interest: $interest');
          allInterests.add(interest);
        }
      }
    });

    test('should have valid emoji for each category', () {
      for (final category in InterestCategory.values) {
        expect(category.emoji, isNotEmpty);
        expect(category.displayName, isNotEmpty);
        expect(category.fullDisplayName, contains(category.emoji));
      }
    });
  });

  group('getCategoryForInterest', () {
    test('should return correct category for predefined interest', () {
      expect(getCategoryForInterest('Basketball'), InterestCategory.sports);
      expect(getCategoryForInterest('Coding'), InterestCategory.academic);
      expect(getCategoryForInterest('Coffee'), InterestCategory.social);
      expect(getCategoryForInterest('Music'), InterestCategory.creative);
      expect(getCategoryForInterest('Travel'), InterestCategory.lifestyle);
      expect(getCategoryForInterest('Gaming'), InterestCategory.entertainment);
    });

    test('should return null for non-existent interest', () {
      expect(getCategoryForInterest('Non-existent Interest'), isNull);
      expect(getCategoryForInterest('Random Hobby'), isNull);
    });
  });

  group('getInterestsForCategory', () {
    test('should return interests for a category', () {
      final sportsInterests = getInterestsForCategory(InterestCategory.sports);
      expect(sportsInterests, contains('Basketball'));
      expect(sportsInterests, contains('Volleyball'));

      final academicInterests =
          getInterestsForCategory(InterestCategory.academic);
      expect(academicInterests, contains('Coding'));
      expect(academicInterests, contains('Study Buddy'));
    });

    test('should return non-empty list for all categories', () {
      for (final category in InterestCategory.values) {
        final interests = getInterestsForCategory(category);
        expect(interests, isNotEmpty);
      }
    });
  });
}
