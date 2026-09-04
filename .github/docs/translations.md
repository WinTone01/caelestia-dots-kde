# Translations

The shell UI is translatable through Qt Linguist. Source strings live in the QML
files wrapped in `qsTr()`, the catalogues live in `shell/translations/`, and the
`Translations` singleton loads them at runtime.

English is the source language, so it needs no catalogue. Turkish (`tr`) ships as
the first translation.

## How it fits together

| Piece | Where | What it does |
|-------|-------|--------------|
| Source strings | `shell/**/*.qml` | Anything user-facing is wrapped in `qsTr("...")` |
| Catalogues | `shell/translations/caelestia_<code>.ts` | Qt Linguist XML, one per language |
| Extraction | `scripts/update-translations.sh` | Runs `lupdate` over the shell sources |
| Compilation | `shell/CMakeLists.txt` | Runs `lrelease`, installs `caelestia_<code>.qm` next to the shell |
| Loading | `shell/plugin/src/Caelestia/translations.{hpp,cpp}` | `Translations` singleton, installs a `QTranslator` and retranslates the engine |
| Setting | `general.language` in `shell.json` | `"system"` (default) or a locale code such as `"tr"` |
| UI | Nexus -> Language & region -> Shell language | Writes `general.language` |

Switching languages takes effect immediately - the singleton calls
`QQmlEngine::retranslate()`, so bindings that use `qsTr()` re-evaluate without a
shell restart. Strings a catalogue does not cover fall back to English.

Catalogues are looked up in this order:

1. `$CAELESTIA_TRANSLATIONS_DIR` (colon separated, handy for testing)
2. `<shell>/translations/` next to the running `shell.qml` (repo checkout or install tree)
3. The path baked in at build time (`<INSTALL_QSCONFDIR>/translations`)

## Adding a language

1. Create the catalogue (this also refreshes every existing one):

   ```bash
   scripts/update-translations.sh es
   ```

   `es` is the locale code. Region specific codes work too (`pt_BR`), and the
   loader falls back from `pt_BR` to `pt` when only the bare catalogue exists.

2. Translate `shell/translations/caelestia_es.ts` - with Qt Linguist
   (`linguist6 shell/translations/caelestia_es.ts`) or any text editor. Leave an
   entry untranslated to keep the English text.

3. Rebuild and install the shell:

   ```bash
   bash scripts/08-build-shell.sh
   ```

4. Pick the language in Nexus -> Language & region -> Shell language. It appears
   automatically once the `.qm` file is installed.

Qt's Linguist tools are needed to build catalogues. The installer and
`caelestia-update` pull them in automatically (`qt6-tools` on Arch,
`qt6-qttools-devel` on Fedora, `qt6-l10n-tools` + `qt6-tools-dev` on Debian).
Without them the build still succeeds, it just warns and ships English only.

## Keeping catalogues current

After adding or changing `qsTr()` strings, run:

```bash
scripts/update-translations.sh
```

With no arguments it updates every existing catalogue. New strings land as
`type="unfinished"`, obsolete ones are dropped.

## Writing translatable strings

- Wrap user-facing text in `qsTr()`: `text: qsTr("Wallpapers")`.
- Keep placeholders out of the sentence structure - use `%1` with `.arg()`
  rather than concatenation, so translators can reorder them:

  ```qml
  // Good
  text: qsTr("Saved weather coordinates: %1").arg(coords)
  // Bad
  text: qsTr("Saved weather coordinates: ") + coords
  ```

- Do not translate identifiers: Material Symbol icon names (`text: "search"` on
  a `MaterialIcon`), config keys, class names, or command placeholders like
  `ghp_...`.
- `qsTr()` context is the QML file's base name, so the same English word in two
  files can be translated differently.
