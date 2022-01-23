# Text und wahlweise Bilder herunterladen

## Bayerische Staatsbibliothek (BSB)

Die https://www.digitale-sammlungen.de haben sehr viele Texte suchbar in der Volltextsuche, allerdings gibt es derzeit kein Angebot, gesamte Texterkennungstexte herunterzuladen. Daher benutzt dieses Programm [`./bsb_Bilder_und_OCR_herunterladen.sh`](bsb_Bilder_und_OCR_herunterladen.sh) die Programm-Schnitt-Stelle (auch API), das sind XML/HTML Dateien, in der die Texterkennungsschnippsel eingepflegt sind. Eine XSL-Filterdatei, mit der man XML-Elemente durchfragen und gezielt herausfiltern kann, wirkt dazu, die Texterkennungsschnippsel zusammenzufügen. Es wird schlußendlich eine XML-Datei erstellt und falls möglich auch ein reine Textdatei.

```bash
# 1. Variablen im Skript anpassen
# 
# 2. Skript ausführen, das Programm ist so angelegt, daß es viele Hinweise gibt
# 2.1. Beispiel ohne Bilder, Variable LADE_BILDER_HERUNTER=0 wurde auf Null gesetzt, also keine Bilder herunterladen
./bsb_Bilder_und_OCR_herunterladen.sh
##########################
# Nur XML-Texterkennungsseiten herunterladen und XML Textauszug erstellen …
# Jetzt 1 bis 1140 Seitennummern mit Bibliothek-Code bsb10119000 herunterladen und Text in Textseiten_bsb10119000_allesamt.xml zusammenfügen?
# (ja/nein) j
# …

# 2.2. Beispiel mit Bildern, Variable LADE_BILDER_HERUNTER=1 wurde auf eins gesetzt, also Bilder herunterladen
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

