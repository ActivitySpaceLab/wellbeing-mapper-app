# Encryption setup

Every survey and consent record the app uploads is encrypted on the phone
before it is sent. The server stores the encrypted files as they are; only
the research team, with the private key, can read them.

## The scheme

For each upload (`ResearchServerService._encrypt`):

1. The record is serialised to JSON.
2. A fresh 256-bit AES key and a 16-byte IV are drawn from a secure random
   source, and the JSON is encrypted with **AES-256-GCM**. The GCM tag is
   appended to the ciphertext.
3. The AES key is wrapped with the study's RSA public key using
   **RSA-OAEP with SHA-256**. (The RSA plaintext is the base64 text of the
   key; the decryption tool accounts for this.)
4. The pieces are put in a JSON envelope, `{encryptedData, iv, encryptedKey,
   algorithm: "AES-256-GCM+RSA-OAEP-SHA256", researchSite, timestamp}`,
   which is base64-encoded and sent as `encrypted_data`.

The server checks that a request has this shape and stores it; it never
decrypts. `tools/decrypt_received.py` in the server repository reverses the
steps, and `tools/encrypt_sample.js` there produces test data the same way.

## Keys

```bash
openssl genrsa -out wellbeing_private_key.pem 4096
openssl rsa -in wellbeing_private_key.pem -pubout -out wellbeing_public_key.pem
```

* The **public key** is compiled into the app: paste the contents of
  `wellbeing_public_key.pem` into `ENV.researchPublicKey` in
  `lib/util/env.dart` and rebuild. It is the only copy of the key the app
  needs (`EncryptedSurveyService` reads the same constant).
* The **private key** is kept offline by the research team, with a backup
  in a password manager or the university's secrets vault. It is used only
  to decrypt downloaded submissions. It must never be on the server or in
  git (`*.pem` is ignored in both repositories). If it is lost, the data
  cannot be recovered; if it leaks, generate a new pair and ship a new app
  version. Data encrypted with the old key still needs the old private key.

The app carries the study's public key, generated on 2026-09-28. Its SHA-256
fingerprint is in the comment above `ENV.researchPublicKey`, with the command
that checks a private key against it.

## Decrypting

On a research team computer:

```bash
pip install cryptography
python3 tools/decrypt_received.py --key wellbeing_private_key.pem --out decrypted/ received/
```

See the server README, "Decrypting the data".
