#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Tests für rename-tracks.py — vor allem Groß-/Kleinschreibung.

    python3 test-rename-tracks.py
"""
import importlib.util
import os
import sys

# Kein __pycache__ im Musikordner anlegen — das würde nur in Google Drive
# synchronisieren. (Und: veralteter Bytecode lässt Mutationsproben
# falsch-grün aussehen, siehe Kommentar am Ende der Datei.)
sys.dont_write_bytecode = True

_hier = os.path.dirname(os.path.abspath(__file__))
_spec = importlib.util.spec_from_file_location("rt", os.path.join(_hier, "rename-tracks.py"))
rt = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(rt)

fehler = []


def pruefe(bezeichnung, ist, soll):
    if ist != soll:
        fehler.append(f"{bezeichnung}\n      ist:  {ist!r}\n      soll: {soll!r}")


# ── Title Case: kleine Wörter ──────────────────────────────────────────────
for roh, soll in [
    ("The Look Of Love",            "The Look of Love"),
    ("Genie In A Bottle",           "Genie in a Bottle"),
    ("The Power Of Love",           "The Power of Love"),
    ("In The Air Tonight",          "In the Air Tonight"),
    ("Where Is The Love",           "Where Is the Love"),
    ("Through the Fire and Flames", "Through the Fire and Flames"),
    ("girls just want to have fun", "Girls Just Want to Have Fun"),
    ("life is a flower",            "Life Is a Flower"),
    # erstes und letztes Wort werden IMMER groß geschrieben
    ("never gonna give you up",     "Never Gonna Give You Up"),
    ("the kids aren't alright",     "The Kids Aren't Alright"),
    ("A Day In The Life",           "A Day in the Life"),
    ("what is love",                "What Is Love"),
    ("in the end",                  "In the End"),
    # nach Klammer/Doppelpunkt/Bindestrich wieder groß
    ("hikikomori (oskar offermann remix)", "Hikikomori (Oskar Offermann Remix)"),
    ("sex (ian levine remix)",      "Sex (Ian Levine Remix)"),
    ("song (the remix)",            "Song (The Remix)"),
    ("eagle-eye view",              "Eagle-Eye View"),
    # erstes Wort ist ein kleines Wort -> trotzdem groß
    ("a day in the life",           "A Day in the Life"),
    ("the of the of",               "The of the Of"),
    # letztes Wort ist ein kleines Wort -> trotzdem groß
    ("what are you waiting for",    "What Are You Waiting For"),
    ("nowhere to run to",           "Nowhere to Run To"),
    # letztes Wort vor schließender Klammer -> ebenfalls groß
    ("song (something to think of)", "Song (Something to Think Of)"),
    # kleines Wort direkt VOR einer schließenden Klammer, aber nicht am Ende
    ("song (think of) again",       "Song (Think Of) Again"),
    # "feat." bleibt klein, auch mitten im Titel und nach einer Klammer
    ("Glamorous (feat. Ludacris)",  "Glamorous (feat. Ludacris)"),
    ("glamorous (ft. ludacris)",    "Glamorous (ft. Ludacris)"),
]:
    pruefe(f"titel_case({roh!r})", rt.titel_case(roh), soll)

# ── Akronyme und CamelCase bleiben unangetastet ────────────────────────────
for roh, soll in [
    ("MGMT",       "MGMT"),
    ("ABC",        "ABC"),
    ("OMC",        "OMC"),
    ("The KLF",    "The KLF"),
    ("OutKast",    "OutKast"),
    ("DragonForce", "DragonForce"),
    ("McCartney",  "McCartney"),
    ("iPhone",     "iPhone"),
    ("Ms. Jackson", "Ms. Jackson"),
    ("Driver's Seat", "Driver's Seat"),
    ("You're My Heart, You're My Soul", "You're My Heart, You're My Soul"),
]:
    pruefe(f"titel_case({roh!r}) unverändert", rt.titel_case(roh), soll)

# ── Künstler: Versalien entschreien, kurze Akronyme behalten ───────────────
for roh, soll in [
    ("DRAGONFORCE",  "DragonForce"),
    ("ABC",          "ABC"),
    ("MGMT",         "MGMT"),
    ("OMC",          "OMC"),
    ("The KLF",      "The KLF"),
    ("OutKast",      "OutKast"),
    ("Ede, Deckert", "Ede & Deckert"),
    ("Sniff 'n' The Tears", "Sniff 'n' The Tears"),
    ("Héroes del Silencio", "Héroes del Silencio"),
    ("Eagle-Eye Cherry",    "Eagle-Eye Cherry"),
    ("Manfred Mann's Earth Band", "Manfred Mann's Earth Band"),
    ("METALLICA",    "Metallica"),
    # Ganzer Name geschrien: dort ist KEIN kurzes Wort ein Akronym.
    # (Vorher wurde daraus "PINK Floyd" bzw. gar "DAFT PUNK".)
    ("PINK FLOYD",   "Pink Floyd"),
    ("IRON MAIDEN",  "Iron Maiden"),
    ("DEEP PURPLE",  "Deep Purple"),
    ("THE WHO",      "The Who"),
    ("DAFT PUNK",    "Daft Punk"),
    # Echte Akronyme überleben das Entschreien trotzdem
    ("DJ BOBO",      "DJ Bobo"),
    ("MTV UNPLUGGED", "MTV Unplugged"),
    # Bekannte Grenze: ein Versalienname mit HÖCHSTENS 4 Buchstaben ist von
    # einem echten Akronym nicht zu unterscheiden (TOTO vs. MGMT). Er bleibt
    # deshalb stehen — auflösbar nur über KUENSTLER_MAP.
    ("XYZW",         "XYZW"),
    ("TOTO",         "Toto"),      # nur dank Eintrag in KUENSTLER_MAP
    ("ABBA",         "ABBA"),
]:
    pruefe(f"kuenstler_case({roh!r})", rt.kuenstler_case(roh), soll)

# ── Fremdsprachige Titel behalten ihre Schreibweise ────────────────────────
for roh in [
    "An Tagen wie diesen",
    "Entre dos tierras",
    "Ella, elle l'a",
    "Lille Vals",
    "Du hast",
    "La vie en rose",
    "Nel blu dipinto di blu",
]:
    pruefe(f"fremdsprachig unverändert {roh!r}", rt.titel_normalisieren(roh), roh)

# Bekannte Grenze: ein fremdsprachiger Titel ohne erkennbares Stoppwort
# (hier sind beide Wörter auch englische Wörter) wird NICHT erkannt.
# Dafür — und nur dafür — gibt es TITEL_AUSNAHMEN.
pruefe("Grenze der Heuristik ohne Ausnahme-Eintrag",
       rt.titel_case("Voyage voyage"), "Voyage Voyage")
rt.TITEL_AUSNAHMEN["voyage voyage"] = "Voyage voyage"
pruefe("TITEL_AUSNAHMEN sticht die Heuristik",
       rt.titel_normalisieren("Voyage voyage"), "Voyage voyage")

# Durchgehend geschriene TITEL werden ebenfalls entschrien
for roh, soll in [
    ("SOME TRACK OF THINGS", "Some Track of Things"),
    ("THE WALL",             "The Wall"),
]:
    pruefe(f"geschrienen Titel entschreien {roh!r}", rt.titel_normalisieren(roh), soll)

# ... aber ein einzelnes Versalienwort in gemischtem Text bleibt Akronym
for roh, soll in [
    ("Live on MTV",        "Live on MTV"),
    ("The ABC of Love",    "The ABC of Love"),
]:
    pruefe(f"Akronym in gemischtem Titel {roh!r}", rt.titel_normalisieren(roh), soll)

# TITEL_AUSNAHMEN liefert die kanonische Schreibweise, nicht nur "nicht anfassen"
pruefe("Ausnahme normalisiert Versalien",
       rt.titel_normalisieren("AN TAGEN WIE DIESEN"), "An Tagen wie diesen")
pruefe("Ausnahme normalisiert Kleinschreibung",
       rt.titel_normalisieren("entre DOS tierras"), "Entre dos tierras")

# … und englische eben nicht
pruefe("englisch wird angefasst", rt.titel_normalisieren("the look OF love"),
       "The Look of Love")

# ── Ganze Dateinamen ───────────────────────────────────────────────────────
for roh, soll in [
    # Ballast
    ("OutKast - Ms. Jackson (Official Video) [EUVo8epKwv0]", "OutKast - Ms. Jackson"),
    ("Toto - Africa (Official Music Video)",                 "Toto - Africa"),
    ("Toto - Africa [HD]",                                   "Toto - Africa"),
    ("Blondie - Maria (Lyrics)",                             "Blondie - Maria"),
    ("Eagles - Hotel California - Topic",                    "Eagles - Hotel California"),
    # Features
    ("Fergie - Glamorous ft. Ludacris",      "Fergie - Glamorous (feat. Ludacris)"),
    ("Fergie - Glamorous (ft. Ludacris)",    "Fergie - Glamorous (feat. Ludacris)"),
    ("Fergie feat. Ludacris - Glamorous",    "Fergie - Glamorous (feat. Ludacris)"),
    ("Fergie - Glamorous featuring ludacris", "Fergie - Glamorous (feat. Ludacris)"),
    ("song - title feat. the roots",         "song - Title (feat. The Roots)"),
    # Zeichen
    ("Modern Talking - You´re My Heart",  "Modern Talking - You're My Heart"),
    ("Ede， Deckert - Immer (Narciss Venice Remix)",
     "Ede & Deckert - Immer (Narciss Venice Remix)"),
    ("Ace of Base – Life Is a Flower",    "Ace of Base - Life Is a Flower"),
    ("Blondie - Maria?",                  "Blondie - Maria"),
    ("Snap! - Rhythm Is A Dancer",        "Snap! - Rhythm Is a Dancer"),
    # Remix bleibt
    ("Sylvester - Sex (Ian Levine Remix)", "Sylvester - Sex (Ian Levine Remix)"),
    # Manuelle Ausnahmen
    ("Don´t Let Me Be Misunderstood - Santa Esmeralda - Kill Bill Vol. 1",
     "Santa Esmeralda - Don't Let Me Be Misunderstood"),
    ("Dan Hartman - Vertigo - Relight My Fire", "Dan Hartman - Relight My Fire"),
]:
    neu, hinweis = rt.neuer_stamm(roh)
    pruefe(f"neuer_stamm({roh!r}) hinweis={hinweis}", neu, soll)

# ── Mehrdeutiges wird NICHT angefasst, sondern gemeldet ────────────────────
for roh in [
    "Irgendwas - Zweites - Drittes",
    "NurEinName",
]:
    neu, hinweis = rt.neuer_stamm(roh)
    if neu is not None or not hinweis:
        fehler.append(f"{roh!r} hätte als unklar gemeldet werden müssen, "
                      f"bekam aber {neu!r}")

# ── Idempotenz: zweiter Lauf ändert nichts mehr ────────────────────────────
for roh in [
    "ABC - The Look Of Love",
    "Fergie - Glamorous ft. Ludacris",
    "DRAGONFORCE - Through the Fire and Flames",
    "Fettes Brot - An Tagen wie diesen",
    "Héroes del Silencio - Entre dos tierras",
    "Zola Jesus - Hikikomori (Oskar Offermann Remix)",
]:
    einmal, _ = rt.neuer_stamm(roh)
    zweimal, _ = rt.neuer_stamm(einmal)
    pruefe(f"idempotent {roh!r}", zweimal, einmal)

# ── Dateisystem: echte Umbenennung, Groß-/Kleinschreibung, Rücknahme ───────
import shutil
import subprocess
import tempfile

sandkasten = tempfile.mkdtemp(prefix="rename-test-")
try:
    proben = [
        "ABC - The Look Of Love.m4a",
        "DRAGONFORCE - Through the Fire and Flames.m4a",
        "OutKast - Ms. Jackson (Official Video) [EUVo8epKwv0].m4a",
        "Fettes Brot - An Tagen wie diesen.m4a",       # bleibt
        "Irgendwas - Zweites - Drittes.m4a",           # unklar, bleibt
        "Cover - Front Of Album.jpg",                  # kein Audio, bleibt UNVERÄNDERT
    ]
    for n in proben:
        with open(os.path.join(sandkasten, n), "w") as fh:
            fh.write(n)

    skript = os.path.join(_hier, "rename-tracks.py")

    # Vorschau darf NICHTS verändern
    subprocess.run([sys.executable, skript, "--dir", sandkasten],
                   capture_output=True, check=True)
    if sorted(os.listdir(sandkasten)) != sorted(proben):
        fehler.append("Vorschau hat Dateien verändert")

    # --apply
    r = subprocess.run([sys.executable, skript, "--dir", sandkasten, "--apply"],
                       capture_output=True, text=True, check=True)
    da = set(os.listdir(sandkasten))
    for erwartet in [
        "ABC - The Look of Love.m4a",
        "DragonForce - Through the Fire and Flames.m4a",
        "OutKast - Ms. Jackson.m4a",
        "Fettes Brot - An Tagen wie diesen.m4a",
        "Irgendwas - Zweites - Drittes.m4a",
        "Cover - Front Of Album.jpg",
    ]:
        if erwartet not in da:
            fehler.append(f"nach --apply fehlt: {erwartet}\n      da: {sorted(da)}")

    # Inhalte stimmen noch (nichts überschrieben)
    pfad = os.path.join(sandkasten, "ABC - The Look of Love.m4a")
    if os.path.exists(pfad) and open(pfad).read() != "ABC - The Look Of Love.m4a":
        fehler.append("Dateiinhalt nach Umbenennung verändert")

    # Zweiter Lauf: nichts mehr zu tun (Idempotenz auf Dateiebene)
    r2 = subprocess.run([sys.executable, skript, "--dir", sandkasten],
                        capture_output=True, text=True, check=True)
    if "0 umzubenennen" not in r2.stdout:
        fehler.append(f"zweiter Lauf will erneut umbenennen:\n{r2.stdout}")

    # Rücknahme
    logs = [f for f in os.listdir(sandkasten) if f.startswith(".rename-log-")]
    if len(logs) != 1:
        fehler.append(f"erwartet genau eine Log-Datei, gefunden: {logs}")
    else:
        subprocess.run([sys.executable, skript, "--undo",
                        os.path.join(sandkasten, logs[0])],
                       capture_output=True, check=True)
        zurueck = set(os.listdir(sandkasten))
        for erwartet in proben:
            if erwartet not in zurueck:
                fehler.append(f"nach --undo fehlt: {erwartet}")

    # --leise unterdrückt die Liste, aber nie die Zusammenfassung
    with open(os.path.join(sandkasten, "TESTER - Quiet Test Of Things.m4a"), "w") as fh:
        fh.write("x")
    rq = subprocess.run([sys.executable, skript, "--dir", sandkasten, "--leise"],
                        capture_output=True, text=True, check=True)
    if "UMBENENNEN" in rq.stdout or "Vorschau" in rq.stdout:
        fehler.append(f"--leise druckt trotzdem die Liste:\n{rq.stdout}")
    if "umzubenennen" not in rq.stdout or "Audio-Dateien" not in rq.stdout:
        fehler.append(f"--leise unterdrückt die Zusammenfassung:\n{rq.stdout}")
    rl = subprocess.run([sys.executable, skript, "--dir", sandkasten],
                        capture_output=True, text=True, check=True)
    if "UMBENENNEN" not in rl.stdout:
        fehler.append("ohne --leise fehlt die Liste")
    subprocess.run([sys.executable, skript, "--dir", sandkasten, "--apply", "--leise"],
                   capture_output=True, check=True)
    if "Tester - Quiet Test of Things.m4a" not in os.listdir(sandkasten):
        fehler.append(f"--apply --leise hat nicht umbenannt: {sorted(os.listdir(sandkasten))}")

    # Reine Groß-/Kleinschreibungs-Änderung auf case-insensitivem Dateisystem
    nur_case = os.path.join(sandkasten, "TESTBAND - some title.m4a")
    with open(nur_case, "w") as fh:
        fh.write("x")
    subprocess.run([sys.executable, skript, "--dir", sandkasten, "--apply"],
                   capture_output=True, check=True)
    treffer = [f for f in os.listdir(sandkasten) if f.lower().startswith("testband")]
    if treffer != ["Testband - Some Title.m4a"]:
        fehler.append(f"Groß-/Kleinschreib-Umbenennung fehlgeschlagen: {treffer}")
    # umbenennen(alt, alt) ist ein No-op und hinterlaesst keine Restdatei
    vorher = sorted(os.listdir(sandkasten))
    irgendeine = [f for f in vorher if f.endswith(".m4a")][0]
    rt.umbenennen(sandkasten, irgendeine, irgendeine)
    if sorted(os.listdir(sandkasten)) != vorher:
        fehler.append("umbenennen(x, x) hat das Verzeichnis verändert")
finally:
    shutil.rmtree(sandkasten, ignore_errors=True)

# ── Ergebnis ───────────────────────────────────────────────────────────────
gesamt = 0
for quelle in (sys.modules[__name__],):
    pass
if fehler:
    print(f"\n{len(fehler)} FEHLGESCHLAGEN:\n")
    for f in fehler:
        print("  " + f + "\n")
    sys.exit(1)
print("Alle Tests grün.")

# Hinweis für spätere Mutationsproben (Test absichtlich kaputt machen und
# prüfen, ob die Suite rot wird): dabei IMMER __pycache__ leeren bzw.
# python3 -B verwenden. Sonst lädt der Unterprozess den alten Bytecode und
# meldet Testlücken, die keine sind — genau das ist beim Bau hier passiert.
