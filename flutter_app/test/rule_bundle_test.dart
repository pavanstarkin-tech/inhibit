import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/core/models/rule_bundle_model.dart';

void main() {
  group('RuleBundle Tests', () {
    test('Parses raw Instagram rule bundle correctly', () {
      final file = File('../rules/instagram.json');
      if (file.existsSync()) {
        final raw = file.readAsStringSync();
        final bundle = RuleBundle.fromRawJson(raw);

        expect(bundle.version, greaterThanOrEqualTo(1));
        expect(bundle.services.containsKey('instagram'), isTrue);

        final insta = bundle.services['instagram']!;
        expect(insta.match.contains('*://*.instagram.com/*'), isTrue);
        expect(insta.authAllowList.contains('^/accounts/'), isTrue);

        expect(insta.surfaces.containsKey('reels-tab'), isTrue);
        final reelsTab = insta.surfaces['reels-tab']!;
        expect(reelsTab.kind, 'dom-remove');
        expect(reelsTab.selectors.isNotEmpty, isTrue);
      }
    });

    test('Parses raw YouTube rule bundle correctly', () {
      final file = File('../rules/youtube.json');
      if (file.existsSync()) {
        final raw = file.readAsStringSync();
        final bundle = RuleBundle.fromRawJson(raw);

        expect(bundle.services.containsKey('youtube'), isTrue);
        final yt = bundle.services['youtube']!;
        expect(yt.surfaces.containsKey('shorts-shelf') || yt.surfaces.containsKey('shorts-pivot'), isTrue);
      }
    });
  });
}
