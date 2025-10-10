# Timestamp Field Reference

## Overview
This note documents how the mobile app, local database, proxy service, and data-analysis toolkit generate and interpret the primary timestamp fields associated with survey submissions.

## Field Definitions

### Submitted_at
- Captured on-device the moment a participant taps submit.
- Generated via `DateTime.now()` and stored in SQLite using `toIso8601String()` without an explicit offset.
- Represents the participant’s local wall-clock time; for Gauteng deployments this aligns with SAST (UTC+02:00).
- Passed unchanged through the encrypted upload pipeline and written verbatim into the CSV exports.

### Created_at
- Added by SQLite with `CURRENT_TIMESTAMP` when a survey row is inserted.
- Stored in UTC per SQLite’s default behaviour.
- Useful as an ingestion audit trail when a device clock may be skewed or a submission is delayed offline.

### Timestamp
- Set when the encryption service packages a payload for upload, again using `DateTime.now()` on the device.
- Serialized as `decrypted_timestamp` by the decryption pipeline and output in the CSV `timestamp` column.
- If the app omits this value, the proxy server falls back to the server’s `new Date().toISOString()` (UTC).

### Location Payload Timestamp
- Location bundles embedded within survey payloads reuse the survey’s `submitted_at` value.
- Enables analysts to align shared traces with the participant’s perception of submission timing.

## Usage Guidelines
- Prefer `submitted_at` when analysing participant experience or sequencing responses within their local timezone.
- Use `created_at` to audit storage chronology or to normalise events to UTC.
- Reference `timestamp` to investigate encryption or network-transfer timing, especially when uploads occur long after completion.
