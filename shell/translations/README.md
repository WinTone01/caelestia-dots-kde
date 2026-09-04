# Catalogues

`caelestia_<code>.ts` files are Qt Linguist catalogues for the shell UI. English
is the source language and needs no catalogue of its own; a new one is generated
from the sources by the script below.

`caelestia_<code>.qm` next to each source is the compiled catalogue, committed
so that a build without Qt's Linguist tools still ships every language rather
than silently falling back to English. The script below recompiles it; do not
edit it by hand.

Refresh them after changing `qsTr()` strings, or start a new language:

```bash
scripts/update-translations.sh          # update every catalogue here
scripts/update-translations.sh es       # add Spanish
```

See [../../.github/docs/translations.md](../../.github/docs/translations.md) for
the full guide.
