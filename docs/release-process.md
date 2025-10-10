# Release Process – Barcelona Wellbeing Mapper

This guide covers how we cut Barcelona beta and production releases across Android and iOS. Follow the sections in order and update the checklists as tooling improves.

## 1. Roles & cadence

- **Release driver**: owns the checklist, coordinates QA, presses the publish buttons.
- **QA lead**: runs through `docs/testing/beta-testing-checklist.md`, signs off in the tracking ticket.
- **Ops liaison**: monitors server load and Telemetry when production is opened wider than the Barcelona pilot.

We ship **beta builds weekly** (or as needed) and **production builds monthly** unless incidents require a hotfix.

## 2. Prep work (applies to all releases)

| Step | Owner | Command / Link |
| --- | --- | --- |
| Ensure your branch is merged to `main` | Release driver | Pull request with green CI |
| Bump version in `pubspec.yaml` | Release driver | Update `version: X.Y.Z+build` |
| Sync native build numbers | Release driver | `./sync-version.sh` |
| Confirm changelog draft | Product/Research | Update `docs/surveys/changelog.md` & release issue |
| Verify secrets in GitHub Actions | Ops liaison | Check repository → Settings → Secrets → Actions |

> Keep the release issue up to date with links to CI runs, QA notes, and store submission status.

## 3. Automated validation

Run the following locally before triggering any release workflow:

```bash
fvm flutter clean
fvm flutter pub get
fvm flutter analyze
fvm flutter test --dart-define=FLUTTER_TEST_MODE=true
```

Optional but recommended:

```bash
fvm dart run integration_test/driver.dart
```

Record pass/fail in the release issue. If tests fail, resolve before proceeding.

## 4. Beta release flow

1. Create a beta tag once QA has signed off:
   ```bash
   git tag vX.Y.Z-beta.N
   git push origin vX.Y.Z-beta.N
   ```
2. The **Deploy Beta Release to GitHub Releases** workflow runs automatically:
   - Builds Android AAB + APK and iOS IPA using the beta flavor (`APP_FLAVOR=beta`).
   - Uploads artifacts to the tag’s GitHub release draft.
3. Download artifacts, install on physical devices, and perform a 30-minute smoke test.
4. Publish the GitHub release with beta notes once QA confirms the build is good.
5. Distribute to TestFlight / Internal App Sharing:
   - iOS: Upload the IPA via Transporter, assign to the Barcelona beta group.
   - Android: Upload the AAB to the Play Console internal track. Keep the APK for side-loading when needed.

## 5. Production release flow

1. Cut the production tag:
   ```bash
   git tag vX.Y.Z[-BUILD]
   git push origin vX.Y.Z[-BUILD]
   ```
   Use the optional `-BUILD` suffix when you need to encode an internal build counter.
2. Ensure the **Deploy Production Release to GitHub Releases** workflow succeeds:
   - Validates the tag format and matches `pubspec.yaml`.
   - Cleans caches and runs `sync-version.sh` automatically.
   - Builds Android and iOS artifacts with `APP_FLAVOR=production`.
   - Drafts the GitHub release and attaches binaries.
3. When the workflow finishes, run the manual `./build-release.sh` locally to keep a reproducible local copy. Smoke-test on a production-configured device (no beta flags).
4. Publish the GitHub release with final notes, linking to the release issue and QA sign-off.
5. Submit to the stores:
   - **Google Play**: Upload the AAB to the production track, add changelog in Catalan/Spanish/English, and start rollout at ≤10% for the first 24 hours.
   - **App Store Connect**: Use Transporter for the IPA, complete compliance questions, and submit for review. Monitor `Resolution Center` until approved.
6. Notify stakeholders in Slack `#barcelona-release` with:
   - Links to the GitHub release and store submissions.
   - Rollout status (percentage, regions enabled).

## 6. Post-release checklist

- ✅ Close the release issue and link it in the CHANGELOG (once standardized).
- ✅ Move leftover tasks to the next milestone.
- ✅ Monitor crash and performance dashboards for 48 hours (Sentry, App Store metrics, Play Console vitals).
- ✅ Update `docs/testing/beta-testing-checklist.md` with any new regressions to cover.
- ✅ Archive the tagged artifacts in the shared Drive folder (`Barcelona Releases/YYYY/MM`).

## 7. Incident & rollback

- If a critical issue is reported, pause the rollout (App Store: remove from sale; Play Store: halt staged rollout).
- Patch the fix, increment the build number, and follow the same steps with a `.hotfix` suffix in the release issue.
- Document the incident in `docs/ops/runbook.md` under “Post-release incidents”.

## 8. Reference materials

- `.github/workflows/CD-deploy-beta-releases.yml`
- `.github/workflows/CD-deploy-github-releases.yml`
- `build-release.sh`
- `docs/testing/beta-testing-checklist.md`
- `docs/ops/runbook.md`

Keep this document evergreen—if the workflows change or we automate store uploads, reflect the new source of truth here.
