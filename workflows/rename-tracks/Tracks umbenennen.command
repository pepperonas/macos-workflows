#!/bin/sh
# Doppelklickbar im Finder: zeigt erst die Vorschau, benennt erst nach
# Rückfrage um. Die Logik steckt in rename-tracks.py — hier steht nur der
# Startknopf.
#
# Kein venv, keine Installation: rename-tracks.py nutzt ausschließlich die
# Python-Standardbibliothek und läuft mit dem python3, das macOS mitbringt.

cd "$(dirname "$0")" || exit 1

schliessen() { printf '\nEnter zum Schließen '; read -r _; exit "${1:-0}"; }

# Erstes vorhandenes python3 nehmen — Homebrew wenn da, sonst das von macOS.
for kandidat in /opt/homebrew/bin/python3 /usr/local/bin/python3 /usr/bin/python3; do
    [ -x "$kandidat" ] && { py="$kandidat"; break; }
done
[ -n "$py" ] || { echo "Kein python3 gefunden." >&2; schliessen 1; }
[ -f rename-tracks.py ] || { echo "rename-tracks.py fehlt in $PWD" >&2; schliessen 1; }

printf '\033[1mTracks umbenennen\033[0m\n'

# Vorschau EINMAL laufen lassen und die Ausgabe für beides nutzen; der
# "--apply"-Hinweis der Vorschau passt hier nicht, die Rückfrage kommt gleich.
vorschau=$("$py" rename-tracks.py --dir "$PWD" 2>&1 | grep -v '^Vorschau —') \
    || { echo "$vorschau" >&2; schliessen 1; }
echo "$vorschau"

case "$vorschau" in
    *"— 0 umzubenennen"*) schliessen 0 ;;
esac

printf '\nUmbenennen? [j/N] '
read -r antwort
case "$antwort" in
    j|J|y|Y|ja|Ja|JA)
        echo
        "$py" rename-tracks.py --dir "$PWD" --apply --leise || schliessen 1
        ;;
    *)
        echo "Abgebrochen — nichts geändert."
        ;;
esac

schliessen 0
