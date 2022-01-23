Alle Programme sind in der Entwicklung β-Status bis stabil; für das Ausführen sind grundlegende Bedienungskenntnisse für die Linux/Unix/?Mac-Konsole nötig. Zur Korrektur von Programm-Fehlern oder Anpassungen sind eigentlich Programmierkenntnisse erforderlich, oder zumindest ein feinsinniger Forschergeist ;-), um zu reparieren, was genau denn nun falsch verlaufen ist.

# Text und wahlweise Bilder herunterladen

## Bayerische Staatsbibliothek (BSB)

Die https://www.digitale-sammlungen.de haben sehr viele Texte suchbar in der Volltextsuche, allerdings gibt es derzeit kein Angebot, gesamte Texterkennungstexte herunterzuladen. Daher benutzt dieses Programm [`./bsb_Bilder_und_OCR_herunterladen.sh`](bsb_Bilder_und_OCR_herunterladen.sh) die Programm-Schnitt-Stelle (auch API), das sind XML/HTML Dateien, in der die Texterkennungsschnippsel eingepflegt sind. Eine XSL-Filterdatei, mit der man XML-Elemente durchfragen und gezielt herausfiltern kann, wirkt dazu, die Texterkennungsschnippsel zusammenzufügen. Es wird schlußendlich eine XML-Datei erstellt und falls möglich auch ein reine Textdatei.

Nötige Dateien:
- [`./bsb_Bilder_und_OCR_herunterladen.sh`](bsb_Bilder_und_OCR_herunterladen.sh) (BASH-Programm)
- [`./bsb_OCR_Text_herausfiltern.xsl`](bsb_OCR_Text_herausfiltern.xsl) (XML-Verarbeitung)

```bash
# 1. Variablen im Skript anpassen (BIB_CODE_NUMER, ERSTE_SEITENNUMMER, LETZTE_SEITENNUMMER) und abspeichern
# 2. Hinweis: Die 2 Skripte kann man auch mittels symbolischer Verknüpfung in den gewünschten Ordner hinverknüpfen und dasig darinnen ausführen lassen
# 3. Skript ausführen, das Programm ist so angelegt, daß es viele Hinweise gibt
# 3.1. Beispiel ohne Bilder, Variable wurde auf Null gesetzt: LADE_BILDER_HERUNTER=0 , also keine Bilder herunterladen
./bsb_Bilder_und_OCR_herunterladen.sh
##########################
# Nur XML-Texterkennungsseiten herunterladen und XML Textauszug erstellen …
# Jetzt 1 bis 1140 Seitennummern mit Bibliothek-Code bsb10119000 herunterladen und Text in Textseiten_bsb10119000_allesamt.xml zusammenfügen?
# (ja/nein) j
# …

# 3.2. Beispiel mit Bildern, Variable wurde auf eins gesetzt: LADE_BILDER_HERUNTER=1 , also Bilder herunterladen
./bsb_Bilder_und_OCR_herunterladen.sh
##########################
# Bilddateien und XML-Texterkennungsseiten herunterladen und XML Textauszug erstellen …
# Jetzt 1 bis 1140 Seitennummern mit Bibliothek-Code bsb10119000 herunterladen und Text in Textseiten_bsb10119000_allesamt.xml zusammenfügen?
# (ja/nein) j
# …
```
## Technische Abhängigkeiten

- Linux, BASH oder UNIX (?Mac)
- Java und [Java Paket saxon9](https://www.saxonica.com/html/documentation9.4/documentation.html) für XSLT Verarbeitung (zwingend erforderlich, könnte auch ein anderer XSLT-Interpreter sein)
- XSL Datei [`./bsb_OCR_Text_herausfiltern.xsl`](bsb_OCR_Text_herausfiltern.xsl) zu Stilverarbeitungsanweisungen (kann angepaßt werden falls sich XML-Struktur der Programm-Schnitt-Stelle (auch API) änderte oder falls andere Ausgabe gewünscht
- `pandoc` (XML → Textumwandlung, kann fehlen, siehe https://pandoc.org) `sed` (Stream Editor, kann fehlen)

