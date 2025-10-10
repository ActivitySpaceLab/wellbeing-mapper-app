# Getting Started with the Barcelona Wellbeing Mapper

This guide lets a new contributor go from a fresh macOS install to running the Barcelona app in under an hour. Follow the steps in order and keep the checklist handy for future machines.

## 1. Prerequisites

| Tool | Minimum Version | Install Notes |
| --- | --- | --- |
| macOS | 14.0 (Sonoma) | Older versions work, but Sonoma is the shared baseline for CI parity. |
| Xcode | 16.0 or newer | Install from the App Store, then run `sudo xcode-select --switch /Applications/Xcode.app`. Launch once to accept the license. |
| Command Line Tools | matching Xcode | `xcode-select --install` if prompted. |
| Android Studio | 2024.1 “Ladybug” | Required for Android SDK Manager and emulators. |
| Flutter | 3.27.1 (FVM-managed) | We pin the toolchain to stay in sync with CI. |
| CocoaPods | 1.15+ | `sudo gem install cocoapods`. |
| Git | 2.40+ | Use Homebrew (`brew install git`) if the system version lags. |
| Homebrew (optional) | 4.x | Simplifies installing the rest of the toolchain. |

### Recommended Homebrew bundle

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew bundle --file=./project_assets/Brewfile.dev
```

The bundled formulae cover `fvm`, `git`, `ruby` updates, and Android platform tools. Adjust as needed if you already maintain these globally.

## 2. Clone the repository

```bash
mkdir -p ~/projects/activityspacelab
cd ~/projects/activityspacelab
git clone git@github.com:ActivitySpaceLab/barcelona-wellbeing-mapper-app.git
cd barcelona-wellbeing-mapper-app
git checkout feature/barcelona-reset-customizations # or your working branch
```

> **SSH note:** If you need HTTPS, swap the clone URL and configure a personal access token.

## 3. Configure Flutter with FVM

We commit an `.fvmrc` so the pinned SDK is automatic.

```bash
fvm install
fvm use
fvm flutter doctor -v
```

Resolve any red items before continuing. Typical misses include:

- iOS toolchain not authorized (`sudo xcodebuild -license`)
- Missing Android licenses (`fvm flutter doctor --android-licenses`)
- Outdated CocoaPods (`sudo gem install cocoapods`)

To run Flutter commands in this repo, prefix with `fvm` (e.g., `fvm flutter pub get`).

## 4. Bootstrap local tooling

1. Install iOS and Android dependencies:
   ```bash
   fvm flutter pub get
   cd ios && pod install && cd ..
   ```
2. Accept Android licenses if you skipped the `doctor` step:
   ```bash
   fvm flutter doctor --android-licenses
   ```
3. Verify the repo structure matches the flattened layout (no nested app directory). If you see `gauteng-wellbeing-mapper-app/`, remove it and reclone.

## 5. Environment configuration

The Barcelona build does not require additional `.env` files for local runs. Runtime configuration is driven by `lib/util/env.dart` and build-time `--dart-define` flags in the workflows.

If you need to test against staging services, request credentials from the research infrastructure team and create a local `.env.development` file mirroring the DigitalOcean endpoints. Do **not** commit secrets.

## 6. Running the app

### iOS Simulator

```bash
fvm flutter run \
  --flavor=beta \
  --dart-define=APP_FLAVOR=beta \
  -d ios
```

Pick the desired simulator from the presented list (we standardize on “iPhone 16 Pro”). The first build can take several minutes while CocoaPods compiles native pods.

### Android Emulator

```bash
fvm flutter run \
  --flavor=beta \
  --dart-define=APP_FLAVOR=beta \
  -d emulator-5554
```

Replace `emulator-5554` with the ID from `adb devices`. If you maintain a dedicated production testing emulator, adjust the flavor and defines accordingly.

## 7. Testing and quality gates

| Command | Purpose |
| --- | --- |
| `fvm flutter analyze` | Static analysis (run before every commit). |
| `fvm flutter test --dart-define=FLUTTER_TEST_MODE=true` | Fast unit/widget test suite. |
| `fvm dart run integration_test/driver.dart` | Optional; spins up integration flows used in CI. |

CI enforces analyze + test on every pull request. Integration tests run nightly and before tagging releases.

## 8. Troubleshooting quick hits

- **Pods fail to install**: `sudo gem install cocoapods` and `pod repo update`.
- **Xcode complains about signing**: for simulators use the “Automatically manage signing” toggle with your personal team; real devices require the ops-managed profiles.
- **Android build runs out of memory**: ensure the emulator is cold-booted and consider `export _JAVA_OPTIONS="-Xmx4g"` before the build.
- **App stuck on splash screen**: check `fvm flutter logs` for missing `APP_FLAVOR` defines; beta flavor uses `APP_FLAVOR=beta`.

## 9. Next steps

- Read `docs/release-process.md` once it lands for the full delivery checklist.
- Skim `docs/testing/beta-testing-checklist.md` to understand the QA expectations.
- Join the Barcelona dev Slack channel (`#barcelona-wellbeing`) for coordination and build notifications.

Keep this file updated as tooling decisions evolve. Drop a PR whenever you change the build scripts or onboarding flow.
