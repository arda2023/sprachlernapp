# Synthetic private-release fixture

Export from the isolated Paket-2 browser fixture, not production or personal data.
The JSON files retain the real editor export's validation, review, registry and
inventory attestations. `content.sql` is its SQLite dump. Dart tests reconstruct
a temporary SQLite file and update only the physical SQLite byte hash/size in
the transport manifest; table inventories remain unchanged. Edge tests verify
the export's original JSON attestations. No credentials or real user database.
