# Barcelona Operations Runbook

Use this playbook when you are on operational support for the Barcelona pilot. Update it whenever tooling or ownership changes.

## 1. Monitoring surfaces

| Surface | Access | What to watch |
| --- | --- | --- |
| Sentry project `wellbeing-mapper-barcelona` | https://sentry.io/organizations/activityspacelab | New crashes, spike in `LocationService` errors |
| Google Play Console → Android vitals | Shared `ops@activityspacelab.org` account | ANR rate, crash rate, excessive wakeups |
| App Store Connect → Metrics | Same account as release driver | Crash-free sessions, install trends |
| DigitalOcean droplet (future) | `ssh ops@barcelona-do` (see `docs/server/README.md`) | CPU < 70%, disk usage < 80% |
| Slack `#barcelona-release` | Workspace invite required | Rollout updates, partner feedback |

> If a monitoring link changes, update the table and drop a note in `#barcelona-release`.

## 2. Daily checks (15 minutes)

1. Review Sentry issues created in the last 24 hours and triage severity.
2. Check Android vitals and App Store metrics for regressions in the latest release.
3. Confirm GitHub Actions scheduled runs (CI + nightly integration tests) completed successfully.
4. Skim the beta feedback form responses and log actionable bugs as GitHub issues.

Log findings and follow-ups in the weekly QA report (`docs/ops/qa-weekly-report.md`).

## 3. On-call rotation & escalation

- On-call schedule lives in the shared Calendar “Barcelona Ops”.
- Primary responder: acknowledges within 30 minutes during local Barcelona hours (08:00–20:00 CET).
- Escalation chain:
	1. Product lead (Slack DM)
	2. Research coordinator (email `barcelona-research@activityspacelab.org`)
	3. Engineering manager (phone tree in shared 1Password vault)

Document every incident in the QA report and follow up with a retro if severity ≥ 2.

## 4. Release day responsibilities

- Partner with the release driver to monitor rollout metrics (Section 1).
- If crash rate exceeds 2% or ANR rate exceeds 1%, halt rollout immediately and page engineering.
- Archive the final GitHub Actions run logs in the `Barcelona Releases/YYYY/MM` Drive folder.

Refer to `docs/release-process.md` for the full release checklist.

## 5. Manual recovery procedures

| Scenario | Response |
| --- | --- |
| Crash/ANR spike post-release | Pause rollout → create hotfix issue → coordinate patch build |
| Server outage (once backend is live) | SSH into droplet → run `docker compose ps` → restart failing service → notify infrastructure |
| Stuck background jobs | Check server queue dashboard (TBD) → retry or purge queue → document action |
| Participant data export request | Verify requester via research coordinator → trigger export in tooling (TBD) → share via encrypted channel |

Fill the “TBD” actions as soon as the server stack ships.

## 6. Contact directory

| Role | Person | Contact |
| --- | --- | --- |
| Product lead | _(TBD)_ | _(add email)_ |
| Research coordinator | _(TBD)_ | _(add email)_ |
| Engineering manager | _(TBD)_ | _(add phone/Slack)_ |
| Ops liaison | _(TBD)_ | _(add phone/Slack)_ |

Replace the placeholders during the first ops readiness review.
