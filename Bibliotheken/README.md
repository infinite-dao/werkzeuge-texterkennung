Alle Programme sind in der Entwicklung β-Status bis stabil; für das Ausführen sind grundlegende Bedienungskenntnisse für die Linux/Unix/?Mac-Konsole nötig. Zur Korrektur von Programm-Fehlern oder Anpassungen sind eigentlich Programmierkenntnisse erforderlich, oder zumindest ein feinsinniger Forschergeist ;-), um zu reparieren, was genau denn nun falsch verlaufen ist.

# Text und wahlweise Bilder herunterladen

## Bayerische Staatsbibliothek (BSB)

Die https://www.digitale-sammlungen.de haben sehr viele Texte suchbar in der Volltextsuche, allerdings gibt es derzeit kein Angebot, gesamte Texterkennungstexte herunterzuladen. Daher benutzt dieses Programm [`./bsb-muenchen_Bilder_und_Texterkennung_herunterladen.sh`](bsb-muenchen_Bilder_und_Texterkennung_herunterladen.sh) die Programm-Schnitt-Stelle (auch API), das sind XML/HTML Dateien, in der die Texterkennungsschnippsel eingepflegt sind. Eine XSL-Filterdatei, mit der man XML-Elemente durchfragen und gezielt herausfiltern kann, wirkt dazu, die Texterkennungsschnippsel zusammenzufügen. Es wird schlußendlich eine XML-Datei erstellt und falls möglich auch ein reine Textdatei.

Nötige Dateien:
- [`./bsb-muenchen_Bilder_und_Texterkennung_herunterladen.sh`](bsb-muenchen_Bilder_und_Texterkennung_herunterladen.sh) (BASH-Programm)
- [`./bsb-muenchen_Texterkennung_herausfiltern.xsl`](bsb-muenchen_Texterkennung_herausfiltern.xsl) (XML-Verarbeitung)

```bash
# 1. Variablen im Skript anpassen (BIB_CODE_NUMER, ERSTE_SEITENNUMMER, LETZTE_SEITENNUMMER) und abspeichern
# 2. Hinweis: Die 2 Skripte kann man auch mittels symbolischer Verknüpfung in den gewünschten Ordner hinverknüpfen und dasig darinnen ausführen lassen
# 3. Skript ausführen, das Programm ist so angelegt, daß es viele Hinweise gibt
# 3.1. Beispiel ohne Bilder, Variable wurde auf Null gesetzt: ANWEISUNG_LADE_BILDER_HERUNTER=0 , also keine Bilder herunterladen
./bsb-muenchen_Bilder_und_Texterkennung_herunterladen.sh
##########################
# Nur XML-Texterkennungsseiten herunterladen und XML Textauszug erstellen …
# Jetzt 1 bis 1140 Seitennummern mit Bibliothek-Code bsb10119000 herunterladen und Text in Textseiten_bsb10119000_allesamt.xml zusammenfügen?
# (ja/nein) j
# …

# 3.2. Beispiel mit Bildern, Variable wurde auf eins gesetzt: ANWEISUNG_LADE_BILDER_HERUNTER=1 , also Bilder herunterladen
./bsb-muenchen_Bilder_und_Texterkennung_herunterladen.sh
##########################
# Bilddateien und XML-Texterkennungsseiten herunterladen und XML Textauszug erstellen …
# Jetzt 1 bis 1140 Seitennummern mit Bibliothek-Code bsb10119000 herunterladen und Text in Textseiten_bsb10119000_allesamt.xml zusammenfügen?
# (ja/nein) j
# …
```

## Sächsische Landesbibliothek - Staats- und Universitätsbibliothek Dresden (SLUB)

Über https://digital.slub-dresden.de/kollektionen kann man hier Volltextsuche oder auch Titelsuchen durchführen. Zum Herunterladen der Einzelbilder oder Texterkennungsschnippsel, geht man gleichfalls vor, wie oben beschrieben, nur sind die nötige Dateien folgende:

- [`./slub-dresden_Bilder_und_Texterkennung_herunterladen.sh`](slub-dresden_Bilder_und_Texterkennung_herunterladen.sh) (BASH-Programm)
- [`./slub-dresden_Texterkennung_herausfiltern.xsl`](slub-dresden_Texterkennung_herausfiltern.xsl) (XML-Verarbeitung)

### Inhaltsverzeichnis eines Werkes zusammenstellen

Auf der Werk-Ansicht-Seite (z.B. http://digital.slub-dresden.de/id399169482/9) befindet sich links meistens eine Inhaltsgliederung, die von der Bibliothek bereits erfaßt wurde, und den Kapiteltext, Seitennummer und den Netzwerk-Ort (URL) angibt. Durch JavaScript kann man sich daraus ein Inhaltsverzeichnis erstellen.

Für Wikitext, wenn man jQuery in des Netzprogramms Entwicklerkonsole zur Verfügung hat, erstellt man die Verweise, Kapitelbezeichnugen und Seitennummern wie folgt:
```JavaScript
jQuery('ul.toc li').each(function() {
  var $a=jQuery(this).find('a'), wikitext="";
  wikitext="[" 
  + document.location.origin + $a.attr('href')
  + " "
  + $a.attr('title') 
  + " (" 
  + $a.find('span.pagination').text()
  + ")"
  + "]" 
  ;
  console.log(wikitext);
});
/* erzeugt Wikitext
 [https://digital.slub-dresden.de/werkansicht/dlf/97829/17 Abbildung (1)]
 [https://digital.slub-dresden.de/werkansicht/dlf/97829/19 Der Maschinenbauer und seine Hülfsmittel (3)]
 usw.
*/
```

## Technische Abhängigkeiten

- Linux, BASH oder UNIX (?Mac)
- Java und [Java Paket saxon9](https://www.saxonica.com/html/documentation9.4/documentation.html) für XSLT Verarbeitung (zwingend erforderlich, könnte auch ein anderer XSLT-Interpreter sein)
- `nice` (Rechen-Priorität für java reduzieren und als Hintergrundprozess befehligen)
- XSL Dateien zu Stilverarbeitungsanweisungen (kann angepaßt werden falls sich XML-Struktur der Programm-Schnitt-Stelle (auch API) änderte oder falls andere Ausgabe gewünscht)

  - [`./bsb-muenchen_Texterkennung_herausfiltern.xsl`](bsb-muenchen_Texterkennung_herausfiltern.xsl)
  - [`./slub-dresden_Texterkennung_herausfiltern.xsl`](bsb-muenchen_Texterkennung_herausfiltern.xsl)

- `sed` (Stream Editor); `pandoc` (XML → Textumwandlung, kann fehlen, siehe https://pandoc.org) 

