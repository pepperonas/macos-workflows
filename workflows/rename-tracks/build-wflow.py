#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Erzeugt den COMMAND_STRING der Quick Action aus rename-tracks.py.

Das Python-Skript ist die EINZIGE Quelle der Wahrheit; die .wflow bekommt eine
eingebettete Kopie (so läuft die Quick Action auch ohne dieses Repo). Damit
beide nicht auseinanderlaufen, wird die Kopie hier erzeugt und von
tests/test-rename-tracks.sh byte-für-byte gegen das Original gepinnt.

    python3 build-wflow.py           # prüft, ob die .wflow aktuell ist
    python3 build-wflow.py --write   # schreibt sie neu
"""
import os
import plistlib
import re
import sys

HIER = os.path.dirname(os.path.abspath(__file__))
PY = os.path.join(HIER, "rename-tracks.py")
WFLOW = os.path.join(HIER, "Rename Tracks.workflow", "Contents", "document.wflow")

# Marker, zwischen denen die eingebettete Kopie liegt. Der Test schneidet
# an genau diesen Zeilen aus.
START = "cat > \"$skript\" <<'PYEOF'\n"
ENDE = "\nPYEOF\n"

RUMPF = """export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# Die Logik liegt in rename-tracks.py (nur Standardbibliothek, kein venv).
# Sie wird hier eingebettet, damit die Quick Action ohne das Repo läuft.
skript=$(mktemp -t rename-tracks-XXXXXX)
trap 'rm -f "$skript"' EXIT
{start}{code}{ende}
frage() {{
    osascript - "$1" "$2" <<'AS' 2>/dev/null
on run argv
    set kopf to item 1 of argv
    set knopf to item 2 of argv
    display dialog kopf with title "Rename Tracks" ¬
        buttons {{"Abbrechen", knopf}} default button "Abbrechen"
    return button returned of result
end run
AS
}}

melde() {{
    osascript - "$1" <<'AS' 2>/dev/null
on run argv
    display dialog (item 1 of argv) with title "Rename Tracks" ¬
        buttons {{"OK"}} default button "OK" giving up after 20
end run
AS
}}

for ordner in "$@"; do
    [ -d "$ordner" ] || continue

    vorschau=$(python3 "$skript" --dir "$ordner" 2>&1)
    if [ $? -ne 0 ]; then
        melde "Fehler:

$vorschau"
        continue
    fi

    # Zusammenfassungszeile + Umbenenn-Liste, auf 15 Zeilen gekürzt.
    kopf=$(printf '%s\\n' "$vorschau" | sed -n '2p')
    liste=$(printf '%s\\n' "$vorschau" | sed -n '/^UMBENENNEN$/,/^$/p' | sed '1d;$d')
    unklar=$(printf '%s\\n' "$vorschau" | sed -n '/^UNKLAR/,/^$/p' | grep -c '^  [^ ]' || true)

    case "$vorschau" in
        *"— 0 umzubenennen"*)
            melde "$kopf

Alle Namen entsprechen bereits der Konvention."
            continue
            ;;
    esac

    zeilen=$(printf '%s\\n' "$liste" | wc -l | tr -d ' ')
    if [ "$zeilen" -gt 15 ]; then
        liste=$(printf '%s\\n' "$liste" | head -15)
        liste="$liste
  … und $((zeilen - 15)) weitere"
    fi

    text="$kopf

$liste"
    if [ "$unklar" -gt 0 ]; then
        text="$text

$unklar Name(n) sind mehrdeutig und bleiben unangetastet."
    fi

    antwort=$(frage "$text" "Umbenennen")
    [ "$antwort" = "Umbenennen" ] || continue

    ergebnis=$(python3 "$skript" --dir "$ordner" --apply --leise 2>&1)
    melde "$(printf '%s\\n' "$ergebnis" | grep -E 'umbenannt|FEHLER|Nichts zu tun')

Rückgängig über die Log-Datei im Ordner:
python3 rename-tracks.py --undo <log>"
done
"""


def kommandostring():
    with open(PY, encoding="utf-8") as fh:
        code = fh.read()
    if "PYEOF" in code:
        sys.exit("rename-tracks.py enthält 'PYEOF' — das würde den Heredoc beenden.")
    return RUMPF.format(start=START, code=code.rstrip("\n"), ende=ENDE)


def lies_wflow():
    with open(WFLOW, "rb") as fh:
        return plistlib.load(fh)


def main():
    schreiben = "--write" in sys.argv
    neu = kommandostring()
    doc = lies_wflow()
    params = doc["actions"][0]["action"]["ActionParameters"]
    if params.get("COMMAND_STRING") == neu:
        print("document.wflow ist aktuell.")
        return 0
    if not schreiben:
        print("document.wflow ist VERALTET — mit --write neu erzeugen.", file=sys.stderr)
        return 1
    params["COMMAND_STRING"] = neu
    params["shell"] = "/bin/zsh"
    params["inputMethod"] = 1
    with open(WFLOW, "wb") as fh:
        plistlib.dump(doc, fh)
    print(f"document.wflow neu geschrieben ({len(neu)} Zeichen COMMAND_STRING).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
