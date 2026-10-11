# G7 SE descriptor 0630 protocol fixtures

These small JSON fixtures contain confirmed USB requests/responses from Linux
probes and owner-supplied Windows Nexus Legacy 1.5.3.0 captures. Source filenames
and hashes identify the original local captures; raw captures are not required to run the tests.

- `g7se-0630-nexus.json`: short reads, target writes, rear records and readbacks.
- `g7se-0630-linux-roundtrip.json`: complete record remap, Default and restoration.
- `g7se-0630-rates.json`: captured 250/500/1000 Hz writes and acknowledgements
  across all four banks, plus covering read replies after reconnect. These
  verify configured values, not physical polling frequency.
- `g7se-0630-auth.json`: authentication framing, reconstructed handshake messages
  and controller chunk acknowledgements. The device certificate is replaced in
  both packets and messages by a generated test-only RSA public key and zero
  padding, preserving lengths and chunk boundaries. No real device certificate
  or private key is included. Production generates fresh session material; no
  premaster or master secret is included or replayed.
- `g7se-0630-gip-identification.json`: bounded identification and chunk ACKs.
- `g7se-0630-input.json`: standard Xbox input reports and expected readouts.
- `g7se-0630-firmware.json`, `g7se-0630-info-0b.json`: information replies.
- `g7se-0630-nexus-startup.json`: earlier transient startup candidates, distinct
  from the verified fresh authentication path.

Historical fixtures include the readable fourth bank. Nexus exposes three
editable remap profiles, so tests require rear-record writes to bank 4 to be
refused. Its one-byte report-rate field is the sole allowed bank-4 write. Device backups, full local diagnostics and Windows vendor bundles
are excluded from the upstream change.
