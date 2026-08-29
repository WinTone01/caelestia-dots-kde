# Catalogues

`caelestia_<code>.ts` files are Qt Linguist catalogues for the shell UI. English
is the source language and needs no translations - `caelestia_en.ts` is kept as
an up-to-date template to copy from.

Refresh them after changing `qsTr()` strings, or start a new language:

```bash
scripts/update-translations.sh          # update every catalogue here
scripts/update-translations.sh es       # add Spanish
```

See [../../.github/docs/translations.md](../../.github/docs/translations.md) for
the full guide.
