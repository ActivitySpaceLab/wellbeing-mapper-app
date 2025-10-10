# Barcelona Beta Testing Checklist

This checklist keeps our beta testers and internal QA aligned on what to verify before shipping a production build.

## Pre-install steps

- Confirm you are using the latest tagged beta build (matching the `vX.Y.Z-betaN` tag).
- Ensure Private Mode is enabled unless you are running supervised research sessions.
- Back up any previous beta data from Settings → Advanced → Export Local Data.

## Functional areas to exercise

- **Surveys and forms**: Complete the onboarding flow, daily wellbeing survey, and any scheduled follow-ups. Confirm reminders arrive on time.
- **Map experience**: Toggle between city-wide heatmap and personal timeline, verify Barcelona-specific tiles render correctly.
- **Background location**: Leave the app for at least 30 minutes and verify new points appear in the timeline without user intervention.
- **Notifications**: Trigger consent reminders, safety check-ins, and experimental nudges; review the copy for Catalan, Spanish, and English locales.
- **Sync and exports**: Upload a test dataset through the in-app export and confirm encrypted payloads arrive on the staging server.

## Reliability checks

- Review battery impact over a four-hour walking session (target <8% additional drain).
- Stress-test offline mode by disabling connectivity for two hours, then re-enable and confirm queued transmissions clear.
- Inspect crash and error logs in Sentry for new regressions tied to the beta version.

## Regression guardrails

- Complete the privacy wipe flow (Settings → Advanced) and ensure all local data is erased.
- Validate TestFlight or internal Android installs can coexist with the production app without clashing bundle IDs.
- Run the `flutter test --dart-define=FLUTTER_TEST_MODE=true` suite locally and verify it passes on the beta tag commit.

## Feedback loop

- File issues in GitHub using the `beta` label with clear reproduction steps and device context.
- Share qualitative observations and screenshots in the beta feedback Slack channel.
- Summarize testing outcomes in the weekly QA report template stored in `docs/ops/qa-weekly-report.md` (create if missing).

Keep this checklist up to date as new Barcelona-specific features roll out.
