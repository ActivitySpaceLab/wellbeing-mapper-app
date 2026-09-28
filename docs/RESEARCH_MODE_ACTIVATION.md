# Research mode activation

Research mode is what makes the app upload data. A participant unlocks it
with a participant code; everything else about the app works the same in
private mode.

## For participants

1. Open the menu and choose research participation.
2. Enter the code the research team gave you. Codes are not case-sensitive.
3. Read and complete the consent form.

From then on, surveys and the location history you choose to share are
uploaded to the research server. You can switch back to private mode at any
time from the menu.

## For the research team

1. **Deploy the server** and **build the app** for it, following
   [Server Setup](SERVER_SETUP.md).
2. **Generate codes** in the server repository:
   `python3 generate_participant_codes.py --count 500`. Put the resulting
   `participant_codes.json` (hashes only) on the server as its README
   describes; keep the CSV of codes private.
3. **Hand each participant one code**, for example printed on the consent
   information sheet.

## How a code is checked

The app hashes the code (SHA-256, uppercased) and sends the hash to
`POST /api/v1/participants/validate`; the server compares it with its list of
hashes and answers `valid: true` with the code's type (`study`, `pilot` or
`test`). The code itself never leaves the phone, and the server never holds
codes. The validated hash is stored in the app's preferences; the app does
not check it again.

Without a server URL in the build, or in a debug build when the server cannot
be reached, the app accepts only the fixed test codes `TESTER`, `TEST123`
and `DEV001` (`ParticipantValidationService`). They are meant for trying the
research flow without a server. A participant whose code was accepted that
way never uploads anything, not even after the app is updated to a build
with a server URL: uploads require a code the server itself confirmed
(`ResearchServerService.uploadBlockedReason`). Do not add the test codes to
the production `participant_codes.json` (the generator leaves them out unless
asked), or anyone who knows them could unlock research mode in the released
app.

## Checking

* A code from the CSV unlocks research mode in a build made with
  `SERVER_BASE_URL`; a made-up code is rejected with "Invalid participant
  code".
* `scripts/check-deployment.sh https://your-host` in the server repository
  confirms the server has its code file loaded.
