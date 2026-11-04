import 'package:flutter_test/flutter_test.dart';
import 'package:screen_translate/services/resume_prompts.dart';

void main() {
  late List<String> tried;

  /// A chooser whose steps record that they ran; each returns whether it
  /// took the resume.
  Future<ResumePrompt> choose({
    bool paywall = false,
    bool explainer = false,
    bool reviewDue = false,
  }) {
    tried = [];
    return chooseResumePrompt(
      showPaywallIfPending: () {
        tried.add('paywall');
        return paywall;
      },
      explainAccessibility: () async {
        tried.add('explainer');
        return explainer;
      },
      reviewIsDue: () {
        tried.add('review?');
        return reviewDue;
      },
      promptReview: () => tried.add('review!'),
    );
  }

  test('the paywall takes the resume and nothing else is tried', () async {
    expect(await choose(paywall: true, explainer: true, reviewDue: true),
        ResumePrompt.paywall);
    expect(tried, ['paywall']);
  });

  // The explainer gets one chance per install; the review prompt gets every
  // later resume. Reversing these two would mean the explainer is never
  // reached, because a due review is eligible on almost every resume.
  test('the explainer goes before the review prompt', () async {
    expect(await choose(explainer: true, reviewDue: true),
        ResumePrompt.accessibilityExplainer);
    expect(tried, ['paywall', 'explainer']);
  });

  test('a declined explainer falls through to the review prompt', () async {
    expect(await choose(reviewDue: true), ResumePrompt.review);
    expect(tried, ['paywall', 'explainer', 'review?', 'review!']);
  });

  test('nothing due leaves the resume alone', () async {
    expect(await choose(), ResumePrompt.none);
    expect(tried, ['paywall', 'explainer', 'review?']);
    expect(tried, isNot(contains('review!')));
  });
}
