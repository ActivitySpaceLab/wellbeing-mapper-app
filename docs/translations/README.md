# Translation Workflow (CSV)

This project now supports a simple CSV workflow for string review.

## Files

- `docs/translations/strings.csv`: editable translation sheet
- `scripts/export_translations.dart`: export current JSON strings to CSV
- `scripts/import_translations.dart`: import CSV updates back into JSON

## Export

Run from project root:

```bash
dart run scripts/export_translations.dart
```

This reads `lang/en.json` and `lang/it.json` and writes `docs/translations/strings.csv`.

## Edit

Share `docs/translations/strings.csv` with reviewers.

Columns:

- `key`
- `en`
- `it`
- `status` (optional, e.g. `draft`, `reviewed`, `approved`)
- `notes` (optional)

## Import

After edits are done:

```bash
dart run scripts/import_translations.dart
```

This updates:

- `lang/en.json`
- `lang/it.json`

Keys are sorted alphabetically on write for easy diffs.
