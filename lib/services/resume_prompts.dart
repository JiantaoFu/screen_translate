/// Which prompt a resume gets. At most one, in a fixed order.
enum ResumePrompt { none, paywall, accessibilityExplainer, review }

/// Runs the resume prompts in priority order and stops at the first one that
/// takes the resume.
///
/// The order is the point, and it is by how little each one gets to ask
/// again:
///
/// 1. the lite paywall, which is due the moment the last free translation
///    has been used and would be stale by the next resume;
/// 2. the accessibility explainer, shown at most once per install;
/// 3. the review prompt, which gets every later resume and is rate-limited
///    on its own (3 sessions, once per 90 days).
///
/// Without this order the review prompt would take every resume — it is
/// eligible on almost all of them — and the explainer, which has exactly one
/// chance per install, would never be reached.
///
/// Each step both decides and acts: the callbacks show their own prompt and
/// report whether they did. [reviewIsDue] is the exception, because the
/// review prompt's own rate limiting lives in ReviewPromptService and runs
/// inside [promptReview]; a due review still counts as taking the resume,
/// so nothing else is tried after it.
Future<ResumePrompt> chooseResumePrompt({
  required bool Function() showPaywallIfPending,
  required Future<bool> Function() explainAccessibility,
  required bool Function() reviewIsDue,
  required void Function() promptReview,
}) async {
  if (showPaywallIfPending()) return ResumePrompt.paywall;
  if (await explainAccessibility()) return ResumePrompt.accessibilityExplainer;
  if (reviewIsDue()) {
    promptReview();
    return ResumePrompt.review;
  }
  return ResumePrompt.none;
}
