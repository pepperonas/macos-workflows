#!/usr/bin/env python3
# -*- coding: utf-8 -*-
r"""
rename-tracks.py — vereinheitlicht Musik-Dateinamen auf die Konvention

    Künstler - Titel.ext

Regeln (siehe KONVENTION unten für Details):
  1. Genau ein " - " als Trenner zwischen Künstler und Titel
  2. Englische Titel in Title Case; kleine Wörter (a, an, the, of, in, to …)
     bleiben klein, außer am Anfang/Ende oder direkt nach ( [ : -
  3. Fremdsprachige Titel behalten ihre Schreibweise (Stoppwort-Erkennung
     für DE/FR/ES/IT/NL/DA/SV + Ausnahmeliste TITEL_AUSNAHMEN)
  4. Download-Ballast raus: "(Official Video)", "[dQw4w9WgXcQ]", " - Topic" …
  5. Features einheitlich als "(feat. X)" am Titelende
  6. Remix/Version bleibt in runden Klammern am Titelende
  7. ASCII-Interpunktion; keine  ? " * | < > / \ :  (Windows-/Android-Sync)
  8. Künstler: ALL-CAPS wird entschrien, Sonderschreibweisen per KUENSTLER_MAP
  9. Bereits gemischt geschriebene Wörter (OutKast, McCartney) bleiben unangetastet

Aufruf:
    python3 rename-tracks.py                  # Vorschau (ändert NICHTS)
    python3 rename-tracks.py --apply          # umbenennen
    python3 rename-tracks.py --dir ~/Musik    # anderes Verzeichnis
    python3 rename-tracks.py --undo .rename-log-20260830-141500.tsv

Ohne --apply passiert grundsätzlich nichts.
"""

import argparse
import datetime as _dt
import os
import re
import sys
import unicodedata

# ──────────────────────────────────────────────────────────────────────────
# KONVENTION — hier anpassen
# ──────────────────────────────────────────────────────────────────────────

ENDUNGEN = {".m4a", ".mp3", ".flac", ".wav", ".aac", ".opus", ".ogg", ".aiff", ".alac"}

# Kleine Wörter, die in englischen Titeln klein bleiben (außer erstes/letztes Wort)
KLEIN = {
    "a", "an", "the",
    "and", "but", "or", "nor",
    "as", "at", "by", "for", "in", "of", "on", "to",
    "from", "into", "onto", "with", "over", "upon",
    "vs", "via", "per", "n", "'n'",
}

# Akronyme, die auch beim Entschreien eines DURCHGEHEND groß geschriebenen
# Namens groß bleiben. Bewusst kurz gehalten: jedes Wort hier kann in einem
# normalen Titel nicht mehr klein geschrieben werden.
AKRONYME = {
    "DJ", "MC", "USA", "UK", "EU", "NYC", "TV", "MTV", "BBC", "FM",
    "XXL", "NASA", "CD", "LP", "EP", "DNA", "UFO", "LSD", "NYC", "AC/DC",
}

# Künstler mit fester Schreibweise. Schlüssel: kleingeschrieben, Leerraum normalisiert.
KUENSTLER_MAP = {
    "dragonforce":        "DragonForce",
    "ede, deckert":       "Ede & Deckert",
    "outkast":            "OutKast",
    "the klf":            "The KLF",
    "klf":                "The KLF",
    "mgmt":               "MGMT",
    "abc":                "ABC",
    "omc":                "OMC",
    "des'ree":            "Des'ree",
    "sniff 'n' the tears": "Sniff 'n' The Tears",
    "heroes del silencio": "Héroes del Silencio",
    "héroes del silencio": "Héroes del Silencio",
    "eagle-eye cherry":   "Eagle-Eye Cherry",
    "huey lewis & the news": "Huey Lewis & The News",
    "the black eyed peas": "The Black Eyed Peas",
    "toto":               "Toto",
    "abba":               "ABBA",
    "acdc":               "AC-DC",
    "ac-dc":              "AC-DC",
    "will.i.am":          "will.i.am",
}

# Titel, die exakt so bleiben sollen (Schlüssel kleingeschrieben).
# Nötig für fremdsprachige Titel, die die Stoppwort-Erkennung nicht greift.
TITEL_AUSNAHMEN = {
    "an tagen wie diesen": "An Tagen wie diesen",
    "entre dos tierras":   "Entre dos tierras",
    "ella, elle l'a":      "Ella, elle l'a",
    "lille vals":          "Lille Vals",
}

# Namen, die sich nicht automatisch auflösen lassen (z. B. drei " - "-Teile).
# Schlüssel: aktueller Dateiname OHNE Endung. Wert: gewünschter Name OHNE Endung.
MANUELL = {
    "Don´t Let Me Be Misunderstood - Santa Esmeralda - Kill Bill Vol. 1":
        "Santa Esmeralda - Don't Let Me Be Misunderstood",
    "Dan Hartman - Vertigo - Relight My Fire":
        "Dan Hartman - Relight My Fire",
}

# ──────────────────────────────────────────────────────────────────────────
# Zeichen-Normalisierung
# ──────────────────────────────────────────────────────────────────────────

# Typografische / Fullwidth-Zeichen → ASCII
ZEICHEN = {
    "´": "'", "`": "'", "‘": "'", "’": "'", "ʼ": "'",
    "“": "", "”": "", "„": "", "＂": "",
    "，": ",", "：": "", "；": ";", "？": "", "！": "!",
    "｜": "-", "（": "(", "）": ")", "＆": "&", "／": ",",
    "–": "-", "—": "-", "‐": "-", "‑": "-", "−": "-",
    " ": " ", " ": " ", " ": " ", "​": "", "﻿": "",
    "…": "...",
}

# Für Datei-Systeme / Sync unzulässig oder heikel
UNSICHER = {
    "?": "", '"': "", "*": "", "|": "-", "<": "", ">": "", ":": "",
    "/": ",", "\\": ",",
}

# ──────────────────────────────────────────────────────────────────────────
# Ballast aus YouTube- & Co.-Downloads
# ──────────────────────────────────────────────────────────────────────────

_B = re.IGNORECASE
BALLAST = [
    re.compile(r"\s*\[[A-Za-z0-9_-]{11}\]\s*"),                       # YouTube-ID
    re.compile(r"\s*[\(\[]\s*(?:official\s*)?(?:music\s*)?"
               r"(?:video|videoclip|audio|lyrics?|lyric\s*video|"
               r"visuali[sz]er|clip)\s*[\)\]]\s*", _B),
    re.compile(r"\s*[\(\[]\s*official(?:\s+\w+)*\s*[\)\]]\s*", _B),
    re.compile(r"\s*[\(\[]\s*(?:hd|hq|4k|8k|full\s*hd|1080p|720p)\s*[\)\]]\s*", _B),
    re.compile(r"\s*[\(\[]\s*(?:video\s*oficial|videoclip\s*oficial|"
               r"offizielles?\s*(?:musik)?video)\s*[\)\]]\s*", _B),
    re.compile(r"\s+-\s+Topic\s*$", _B),
    re.compile(r"\s*\(\s*\)\s*"),                                     # leere Klammern
]

FEAT = re.compile(
    r"\s*[\(\[]?\s*(?:feat|ft|featuring)\.?\s+([^)\]]+?)\s*[\)\]]?\s*$", _B
)

WORT = re.compile(r"[^\W_]+(?:'[^\W_]+)*'?|'[^\W_]+'", re.UNICODE)

# ──────────────────────────────────────────────────────────────────────────
# Sprach-Erkennung (nur Wörter, die es im Englischen NICHT gibt)
# ──────────────────────────────────────────────────────────────────────────

STOPPWOERTER = {
    # Deutsch
    "der", "das", "den", "dem", "des", "ein", "eine", "einen", "einem", "eines",
    "und", "oder", "wie", "nicht", "noch", "schon", "immer", "wenn", "dann",
    "auch", "für", "fuer", "mit", "von", "zum", "zur", "beim", "vom", "ins",
    "diesen", "dieser", "dieses", "diese", "ich", "du", "wir", "ihr", "mich",
    "dich", "sich", "ist", "sind", "wird", "werden", "kann", "soll", "muss",
    "über", "unter", "ohne", "gegen", "wieder", "ganz", "hier", "jetzt",
    "nichts", "alles", "etwas", "tagen", "leben", "nacht", "welt", "zeit",
    "wär", "wärst", "hätte", "möchte", "gibt", "geht", "steht",
    "dass", "weil", "denn", "sondern", "damit", "obwohl", "während", "seit",
    "bei", "mir", "dir", "uns", "euch", "ihm", "ihn", "ihnen", "kein",
    "keine", "keinen", "viel", "sehr", "nur", "mal", "doch", "aber",
    "wirklich", "zusammen", "zurück", "vorbei", "weiter", "vielleicht",
    # Französisch
    "le", "les", "une", "des", "du", "et", "je", "tu", "il", "elle", "nous",
    "vous", "ils", "elles", "ce", "cette", "qui", "que", "quoi", "pour",
    "avec", "sans", "dans", "mon", "mes", "ton", "tes", "ses", "est", "sont",
    "être", "avoir", "très", "tout", "tous", "toute", "rien", "jamais",
    "toujours", "moi", "toi", "aime", "amour", "coeur", "cœur", "nuit",
    "vie", "ciel", "chanson", "chansons", "oublier", "aimer", "vivre",
    "mourir", "veux", "peux", "viens", "quand", "comme", "chez", "depuis",
    "pendant", "parce", "autre", "autres", "même", "était", "étais", "avait",
    "mademoiselle", "monsieur", "merci", "oui", "alors", "ainsi", "donc",
    # Spanisch / Portugiesisch
    "el", "los", "las", "unos", "unas", "del", "por", "para", "está", "están",
    "más", "muy", "todo", "todos", "nada", "nunca", "siempre", "entre", "dos",
    "tres", "tierras", "corazón", "amor", "vida", "noche", "eu", "não", "você",
    "quiero", "quiere", "está", "hacia", "desde", "porque", "cuando",
    "también", "pero", "mundo", "cielo", "bailar", "cantar", "cómo",
    "dónde", "cuándo", "quién", "qué", "nosotros", "ellos", "ellas",
    # Italienisch
    "gli", "che", "di", "da", "non", "più", "sono", "siamo", "mio", "mia",
    "tuo", "tua", "questo", "questa", "cosa", "amore", "notte", "sempre",
    "mai", "tutto", "perché", "cuore",
    # Niederländisch / Skandinavisch
    "het", "een", "van", "voor", "met", "niet", "ook", "maar", "jag", "och",
    "att", "som", "det", "är", "till", "inte", "vi", "min", "din", "jeg",
    "og", "ikke", "vil", "har", "kärlek", "hjärta", "natt",
}


def _nfc(s):
    return unicodedata.normalize("NFC", s)


def _buchstaben(s):
    return [c for c in s if c.isalpha()]


def zeichen_normalisieren(s, unsicher=True):
    """Typografische Zeichen → ASCII, danach die sync-unsicheren entfernen."""
    s = _nfc(s)
    s = s.translate(str.maketrans(ZEICHEN))
    if unsicher:
        s = s.translate(str.maketrans(UNSICHER))
    s = re.sub(r"\s+", " ", s)
    s = re.sub(r"\s+([,;!.])", r"\1", s)   # Leerzeichen vor Satzzeichen weg
    return s.strip(" .,-_")


def ballast_entfernen(s):
    vorher = None
    while vorher != s:
        vorher = s
        for muster in BALLAST:
            s = muster.sub(" ", s)
        s = re.sub(r"\s+", " ", s).strip()
    return s


def ist_fremdsprachig(titel):
    if titel.lower() in TITEL_AUSNAHMEN:
        return True
    woerter = {w.lower() for w in WORT.findall(titel)}
    return bool(woerter & STOPPWOERTER)


def _wort_case(w, entschreien=False):
    """Ein einzelnes Wort groß schreiben — Akronyme und CamelCase bleiben.

    entschreien=True: der GANZE Name ist geschrien (PINK FLOYD, THE WHO), also
    ist ein kurzes Versalienwort darin kein Akronym, sondern nur laut. Ohne
    diesen Modus blieb jedes Wort bis 4 Buchstaben stehen und aus "PINK FLOYD"
    wurde "PINK Floyd" bzw. aus "DAFT PUNK" gar nichts.
    """
    b = _buchstaben(w)
    if not b:
        return w
    # Bereits gemischte Schreibweise (OutKast, McCartney, iPhone) unangetastet
    if any(c.isupper() for c in w[1:]) and not w.isupper():
        return w
    # Kurzes Akronym (ABC, MGMT, KLF, DJ)
    if w.isupper() and len(b) <= 4 and not entschreien:
        return w
    if entschreien and w.strip(".,!?") in AKRONYME:
        return w
    for i, c in enumerate(w):
        if c.isalpha():
            return w[:i] + c.upper() + w[i + 1:].lower()
    return w


def titel_case(s, entschreien=False):
    """Englische Title-Case-Regeln, längentreu (Indizes bleiben gültig)."""
    treffer = list(WORT.finditer(s))
    if not treffer:
        return s
    zeichen = list(s)
    letzter = len(treffer) - 1
    for i, m in enumerate(treffer):
        w = m.group()
        davor = s[:m.start()].rstrip()
        vor = davor[-1] if davor else ""
        danach = s[m.end():].lstrip()
        nach = danach[0] if danach else ""

        # ACHTUNG: "" in "abc" ist in Python True — vor/nach müssen
        # ausdrücklich auf Nicht-Leer geprüft werden, sonst hängt die
        # Erstes-/Letztes-Wort-Regel nur zufällig am leeren Umfeld.
        erstes = (i == 0) or (vor != "" and vor in "([{-:;/•.!?")
        letztes = (i == letzter) or (nach != "" and nach in ")]}")

        if w.lower() in ("feat", "ft"):          # nie "Feat."
            neu = "feat"
        elif erstes or letztes:
            neu = _wort_case(w, entschreien)
        elif w.lower() in KLEIN and not (any(c.isupper() for c in w[1:]) and not w.isupper()):
            neu = w.lower()
        else:
            neu = _wort_case(w, entschreien)

        if len(neu) == len(w):
            zeichen[m.start():m.end()] = neu
    return "".join(zeichen)


def kuenstler_case(a):
    schluessel = re.sub(r"\s+", " ", a).strip().lower()
    if schluessel in KUENSTLER_MAP:
        return KUENSTLER_MAP[schluessel]
    # Nur schreiende Versalien entschreien (ABC/MGMT/KLF bleiben)
    if a.isupper() and len(_buchstaben(a)) > 4:
        a = titel_case(a, entschreien=True)
        if a.lower() in KUENSTLER_MAP:
            return KUENSTLER_MAP[a.lower()]
    return re.sub(r"\s+", " ", a).strip()


def titel_normalisieren(t):
    schluessel = re.sub(r"\s+", " ", t).strip().lower()
    if schluessel in TITEL_AUSNAHMEN:
        return TITEL_AUSNAHMEN[schluessel]
    if ist_fremdsprachig(t):
        return t                       # Originalschreibweise behalten
    # Durchgehend geschriener Titel: dort ist kein kurzes Wort ein Akronym.
    schreit = t.isupper() and len(_buchstaben(t)) > 4
    return titel_case(t, entschreien=schreit)


def gast_ausschneiden(s):
    """Gibt (rest, gaeste) zurück; gaeste ist None wenn kein feat. vorhanden."""
    m = FEAT.search(s)
    if not m:
        return s, None
    rest = s[:m.start()].strip(" -,")
    gaeste = re.sub(r"\s+", " ", m.group(1)).strip(" ,&")
    if not rest or not gaeste:
        return s, None
    return rest, gaeste


def neuer_stamm(stamm):
    """Kompletter Namen-Umbau. Gibt (neuer_stamm, hinweis) zurück."""
    if stamm in MANUELL:
        return MANUELL[stamm], None
    roh = zeichen_normalisieren(stamm)
    if roh in MANUELL:
        return MANUELL[roh], None

    roh = ballast_entfernen(roh)
    teile = [t.strip() for t in re.split(r"\s+-\s+", roh) if t.strip()]

    if len(teile) == 1:
        return None, "kein ' - ' Trenner gefunden"
    if len(teile) > 2:
        return None, f"{len(teile)} Teile durch ' - ' getrennt (mehrdeutig)"

    kuenstler, titel = teile

    kuenstler, gast_k = gast_ausschneiden(kuenstler)
    titel, gast_t = gast_ausschneiden(titel)
    gaeste = gast_t or gast_k

    kuenstler = kuenstler_case(kuenstler)
    titel = titel_normalisieren(titel)

    if gaeste:
        titel = f"{titel} (feat. {titel_case(gaeste)})"

    neu = f"{kuenstler} - {titel}"
    neu = re.sub(r"\s+", " ", neu).strip(" .-")
    if not kuenstler or not titel:
        return None, "Künstler oder Titel leer nach Bereinigung"
    return neu, None


# ──────────────────────────────────────────────────────────────────────────
# Datei-Operationen
# ──────────────────────────────────────────────────────────────────────────

def sammeln(ordner):
    eintraege = []
    for name in sorted(os.listdir(ordner)):
        pfad = os.path.join(ordner, name)
        if not os.path.isfile(pfad) or name.startswith("."):
            continue
        stamm, endung = os.path.splitext(_nfc(name))
        if endung.lower() not in ENDUNGEN:
            continue
        eintraege.append((name, stamm, endung))
    return eintraege


def umbenennen(ordner, alt, neu):
    """Zwei Schritte — sonst scheitern reine Groß-/Kleinschreib-Änderungen
    auf case-insensitiven Dateisystemen (APFS, exFAT, Google Drive)."""
    a = os.path.join(ordner, alt)
    n = os.path.join(ordner, neu)
    if alt == neu:
        return
    zwischen = os.path.join(ordner, f".tmp-rename-{os.getpid()}-{abs(hash(alt)) % 10**8}")
    os.rename(a, zwischen)
    try:
        os.rename(zwischen, n)
    except Exception:
        os.rename(zwischen, a)
        raise


def undo(logdatei):
    ordner = os.path.dirname(os.path.abspath(logdatei)) or "."
    zeilen = []
    with open(logdatei, encoding="utf-8") as fh:
        for z in fh:
            z = z.rstrip("\n")
            if not z or z.startswith("#"):
                continue
            alt, neu = z.split("\t")
            zeilen.append((alt, neu))
    fehler = 0
    for alt, neu in reversed(zeilen):
        if not os.path.exists(os.path.join(ordner, neu)):
            print(f"  fehlt: {neu}")
            fehler += 1
            continue
        umbenennen(ordner, neu, alt)
        print(f"  ← {alt}")
    print(f"\n{len(zeilen) - fehler} zurückgenommen, {fehler} übersprungen.")
    return 1 if fehler else 0


def main():
    p = argparse.ArgumentParser(
        description="Vereinheitlicht Musik-Dateinamen auf 'Künstler - Titel.ext'.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="Ohne --apply wird nur angezeigt, was passieren würde.",
    )
    p.add_argument("--dir", "-d", default=os.path.dirname(os.path.abspath(__file__)),
                   help="Verzeichnis (Vorgabe: Ordner des Skripts)")
    p.add_argument("--apply", "-a", action="store_true",
                   help="Umbenennungen tatsächlich ausführen")
    p.add_argument("--undo", metavar="LOG",
                   help="Umbenennungen aus einer Log-Datei zurücknehmen")
    p.add_argument("--alle", action="store_true",
                   help="auch unveränderte Dateien auflisten")
    p.add_argument("--leise", "-q", action="store_true",
                   help="nur die Zusammenfassung ausgeben (für Wrapper-Skripte)")
    args = p.parse_args()

    if args.undo:
        return undo(args.undo)

    ordner = os.path.abspath(os.path.expanduser(args.dir))
    if not os.path.isdir(ordner):
        print(f"Kein Verzeichnis: {ordner}", file=sys.stderr)
        return 2

    eintraege = sammeln(ordner)
    if not eintraege:
        print(f"Keine Audio-Dateien in {ordner}")
        return 0

    plan, unklar, gleich = [], [], []
    ziele = {}

    for name, stamm, endung in eintraege:
        neu_stamm, hinweis = neuer_stamm(stamm)
        if neu_stamm is None:
            unklar.append((name, hinweis))
            continue
        neu = neu_stamm + endung.lower()
        if neu == name:
            gleich.append(name)
            continue
        if neu.lower() in ziele and ziele[neu.lower()] != name:
            unklar.append((name, f"Namenskollision mit '{ziele[neu.lower()]}'"))
            continue
        vorhanden = os.path.join(ordner, neu)
        if os.path.exists(vorhanden) and _nfc(neu).lower() != _nfc(name).lower():
            unklar.append((name, f"Ziel existiert bereits: {neu}"))
            continue
        ziele[neu.lower()] = name
        plan.append((name, neu))

    breite = max((len(a) for a, _ in plan), default=0)
    print(f"Verzeichnis: {ordner}")
    print(f"{len(eintraege)} Audio-Dateien — {len(plan)} umzubenennen, "
          f"{len(gleich)} bereits korrekt, {len(unklar)} unklar\n")

    if plan and not args.leise:
        print("UMBENENNEN")
        for alt, neu in plan:
            print(f"  {alt:<{breite}}  →  {neu}")
        print()

    if unklar and not args.leise:
        print("UNKLAR — bitte von Hand prüfen (werden nicht angefasst)")
        for name, hinweis in unklar:
            print(f"  {name}\n      ↳ {hinweis}")
        print("      Tipp: passenden Eintrag in MANUELL{} im Skript ergänzen.\n")

    if args.alle and gleich:
        print("UNVERÄNDERT")
        for name in gleich:
            print(f"  {name}")
        print()

    if not args.apply:
        if not args.leise:
            print("Vorschau — es wurde nichts geändert. Mit --apply ausführen.")
        return 0

    if not plan:
        print("Nichts zu tun.")
        return 0

    zeit = _dt.datetime.now().strftime("%Y%m%d-%H%M%S")
    logpfad = os.path.join(ordner, f".rename-log-{zeit}.tsv")
    erledigt = 0
    with open(logpfad, "w", encoding="utf-8") as log:
        log.write("# alt\tneu — zurücknehmen mit: "
                  f"python3 rename-tracks.py --undo {os.path.basename(logpfad)}\n")
        for alt, neu in plan:
            try:
                umbenennen(ordner, alt, neu)
            except OSError as e:
                print(f"  FEHLER bei {alt}: {e}", file=sys.stderr)
                continue
            log.write(f"{alt}\t{neu}\n")
            log.flush()
            erledigt += 1

    print(f"{erledigt} Dateien umbenannt.")
    print(f"Log: {logpfad}")
    print(f"Zurücknehmen: python3 rename-tracks.py --undo '{logpfad}'")
    return 0


if __name__ == "__main__":
    sys.exit(main())
