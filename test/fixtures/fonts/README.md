# Fonts for reproducible accessibility tests

These are the exact normal variants requested by google_fonts 9.0.0 in the app.
Downloaded from the URLs and checked against both SHA256 and byte sizes declared
by that package. See manifest.json. No network access is required at test time.

Figtree and Source Serif 4 are licensed under SIL OFL 1.1; the original notices
and full licenses are included in the two *-OFL.txt files.

Keep test loading scoped to the accessibility test executable; do not list these
files as app assets or add global test font loading. Existing Ahem goldens must
retain their original rendering. A test helper can expose a synthetic font asset
manifest and route only these asset requests through TestDefaultBinaryMessenger;
all other requests delegate to the platform asset loader.
