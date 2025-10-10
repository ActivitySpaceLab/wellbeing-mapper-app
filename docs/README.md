# Barcelona Wellbeing Mapper Documentation

This directory will host the refreshed documentation set for the Barcelona deployment. Everything below is a scaffolding pass so we can iterate quickly without the Gauteng-specific baggage.

## Writing principles

- **Barcelona-first**: assume this repository serves the Barcelona study unless a comparison is explicitly needed.
- **Less, but better**: keep each document short, focused, and maintained. If content grows large, split it into smaller topic guides.
- **Executable guidance**: prefer checklists, CLI snippets, and configuration tables that somebody new to the project can follow without guesswork.
- **Document owner**: each file should name an owner (person or role) responsible for updates after major code changes.

## Immediate todo list

| Doc | Purpose | Status | Owner |
| --- | --- | --- | --- |
| `getting-started.md` | Quickstart for new developers (macOS + Flutter) | ✅ Ready for review | _Mobile Platform_ |
| `release-process.md` | End-to-end release checklist (Android/iOS) | ✅ Ready for review | _Release driver_ |
| `server/README.md` | DigitalOcean setup, API contract, monitoring | ⬜️ Draft | _Infra_ |
| `surveys/README.md` | Survey authoring, localization, validation steps | ⬜️ Draft | _Research Ops_ |
| `security.md` | Key management, data protection, compliance notes | ⬜️ Draft | _Security_ |
| `ops/runbook.md` | Production support runbook (alerts, dashboards) | 🟡 In progress | _Ops liaison_ |
| `ops/qa-weekly-report.md` | QA + stability reporting template | ✅ Ready to use | _QA lead_ |
| `testing/beta-testing-checklist.md` | Structured guidance for Barcelona beta QA sessions | ✅ Maintained | _DevOps/QA_ |

Feel free to adjust or expand this list as you flesh out the docs.

## Suggested file layout

```
docs/
├── README.md                  # This file
├── getting-started.md         # How to bootstrap the Flutter app locally
├── release-process.md         # Release cadence, versioning, store submission
├── security.md                # Encryption, tokens, handling sensitive data
├── testing/
│   └── beta-testing-checklist.md # Scenario-driven guidance for beta QA
├── server/
│   ├── README.md              # Infrastructure overview
│   └── api-contract.md        # REST endpoints consumed by the app
├── surveys/
│   ├── README.md              # Survey editing and translation workflow
│   └── changelog.md           # Track wording/version changes
└── ops/
    ├── runbook.md             # Operational procedures
    └── qa-weekly-report.md    # Weekly QA status template
```

## Next steps

1. Confirm the target documentation audiences (internal devs, researchers, beta testers).
2. Prioritize which guides you want first (likely **Getting Started** and **Server** for the backend migration).
3. Create the placeholder files listed above and start filling them in during the next work session.

Once we agree on priorities, I can help author the first batch of documents and ensure they stay in sync with the source code.
