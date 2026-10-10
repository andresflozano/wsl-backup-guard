# Threat Model

## Assets

- encrypted WSL backup archives;
- checksum and manifest evidence;
- encryption recovery material;
- local and off-device copies;
- scripts that could overwrite or delete artifacts.

## Primary risks

- publishing private machine metadata;
- committing archives or secrets;
- treating file presence as recoverability;
- deleting the previous valid backup before validating a replacement;
- exposing a password in command history or process arguments;
- overwriting a destination silently;
- validating only a synchronized local cloud folder, not cloud presence;
- using production distribution names during restore tests.

## Controls in the initial slice

- synthetic examples only;
- `.gitignore` excludes archive and evidence outputs by default;
- routine checks are read-only;
- explicit non-zero exit codes;
- no password handling;
- no retention deletion;
- no overwrite behavior;
- validation limitations are returned and documented.
