---
layout: default
title: Server Setup
description: Where research data goes, and how to build the app for a server
---

# Server setup

Research data goes to the **Wellbeing Mapper server**, a small service in
its own repository:
[ActivitySpaceLab/wellbeing-mapper-server](https://github.com/ActivitySpaceLab/wellbeing-mapper-server).
Its README is the deployment guide: running it on a VPS with Docker Compose
or as a systemd service, generating keys and participant codes, backups,
day-to-day operation and decrypting the data. This page covers the app side.

## What the app sends

Only in research mode, only after the participant has completed the consent
form, and only when the build was given a server URL (below):

| What | Endpoint | Contents |
| --- | --- | --- |
| Initial survey | `POST /api/v1/surveys/encrypted` | the answers |
| Biweekly survey | `POST /api/v1/surveys/encrypted` | the answers and the location history the participant chose to share |
| Consent form | `POST /api/v1/consent/encrypted` | the consent record |
| Participant code check | `POST /api/v1/participants/validate` | the SHA-256 hash of the code, never the code |

Every survey and consent upload is encrypted on the phone with the study's
public key (AES-256-GCM for the data, RSA-OAEP-SHA-256 for the key), so the
server stores files it cannot read. Each upload also carries a
`submission_id`, a hash of the participant id, record type and local record
id, so a retry after a lost answer is stored only once. The code lives in
`lib/services/research_server_service.dart`; the paths are in
`lib/util/env.dart`.

Uploads are retried with backoff after network errors and server errors,
and the records stay in the local database until the server has confirmed
them. A survey is never lost by a failed upload.

## Building the app for a server

1. **Key**: generate the study's key pair as described in the server README
   ("Keys") and paste the *public* key into `ENV.researchPublicKey` in
   `lib/util/env.dart`. The app ships with a placeholder key whose private
   half is not held by anyone, so this step is required before data
   collection. The private key stays offline with the research team.
2. **URL**: build with the server's address.

```bash
fvm flutter build apk --flavor production --dart-define=APP_FLAVOR=production \
  --dart-define=SERVER_BASE_URL=https://your-host/api/v1
fvm flutter build ipa --flavor production --dart-define=APP_FLAVOR=production \
  --dart-define=SERVER_BASE_URL=https://your-host/api/v1
```

A build without `SERVER_BASE_URL` never uploads and cannot unlock research
mode with a real participant code; it accepts only the fixed test codes
(`TESTER`, `TEST123`, `DEV001`). `test/services/upload_guard_test.dart`
pins this.

## Participant codes

Codes are generated with `generate_participant_codes.py` in the server
repository. The server gets a file of hashes; the CSV of codes is handed to
participants and kept off the server. A participant types their code in the
app, the app sends its hash, and the server answers whether it is valid.

## Checking it works

* Locally: start the server (`scripts/dev.sh` in its repository) and run
  the app against it with `scripts/run-with-local-server.sh`, which sets
  `SERVER_BASE_URL=http://localhost:3000/api/v1` (iOS simulator) or
  `http://10.0.2.2:3000/api/v1` (Android emulator). Plain HTTP is allowed
  only to local hosts (`NSAllowsLocalNetworking` in `ios/Runner/Info.plist`).
* Against a deployment: `scripts/check-deployment.sh https://your-host`
  in the server repository, then submit a survey from a research-mode build
  and decrypt the stored file with `tools/decrypt_received.py` there.
