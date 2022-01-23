#!/bin/bash
# ------------------------------------------------
# Was tut das Linux-BASH-Programm?
#   Verarbeite HTML/XML Dateien von https://api.digitale-sammlungen.de und filtere die XML-Texterkennungs-Elemente so heraus, daß
#   erkannter Text in Zeilen und Absätze herausgefiltert wird (Anpassungen siehe XSL_STIL_DATEI) und erstelle schlußendlich eine 
#   Gesamt XML-Datei aus (siehe Variable (${ZIELDATEI_ZUSAMMENGEKLAUBTER_XML_TEXTE}). Das Programm ist nicht perfekt, es kann sein,
#   daß die Netzquellen (API URL) im Programm-Code angepaßt werden müssen. Schon heruntergeladene XML-Bibliotheksdateien oder auch 
#   Bilder werden nicht noch einmal heruntergeladen, also sie werden nicht überschrieben. Das Programm fragt zuerst ab, bevor es 
#   durchläuft. Es müssen zuerst die Variablen in diesem Programm stimmen und angepaßt werden, bevor man es laufen läßt.
# ------------------------------------------------
# Abhängigkeit: Java 
# Abhängigkeit: Java Paket saxon9 Paket für XSLT Verarbeitung (zwingend erforderlich)
# Abhängigkeit: XSL Datei der Stilverarbeitungsanweisungen bsb_OCR_Text_herausfiltern.xsl (zwingend erforderlich)
# Abhängigkeit: pandoc (XML => Textumwandlung, kann fehlen) sed (Stream Editor, kann fehlen)

# ------------------------------------------------
# Variablen zum Anpassen bevor Programm ausgeführt wird
# Anfang einstellbarer Variablen
# ------------------------------------------------
  XSL_STIL_DATEI="bsb_OCR_Text_herausfiltern.xsl"
  # Hinweis: zu prüfen ist vielleicht auch, ob die api URL stimmig ist, siehe BASH-Funktionen:
  # - dieseXmlNetzQuelle
  # - diesesBildGroesstmoeglichAlsNetzQuelle
  # # # # # 
  ERSTE_SEITENNUMMER=1    # Ganzzahl: die tatsächliche Index-Nummer der Seite
  LETZTE_SEITENNUMMER=1140 # Ganzzahl
  # BIB_CODE_NUMER="bsb10112188" # Alexander Kaufmann
  # BIB_CODE_NUMER="bsb10114299" # Mäurer, German: Gedichte und Gedanken eines Deutschen in Paris. 1: Gedichte
  # BIB_CODE_NUMER="bsb11161548" # Chwatal, Franz Xaver: Kinderlieder für Schule und Haus
  # BIB_CODE_NUMER="bsb10148142" # Estienne, Charles: Siben Bücher Von dem Feldbau vnd vollkom[m]ener bestellung
  BIB_CODE_NUMER="bsb10119000" # Fischart, Johann: Johann Fischart's Geschichtklitterung und aller Praktik Großmutter

  LADE_BILDER_HERUNTER=0     # 0 oder 1
# ------------------------------------------------
# Ende einstellbarer Variablen
# ------------------------------------------------


# # # # # # # Eigentliches Programm: ab hier nur für Programmierer # # # # # # # # # # # # # #

ZIELDATEI_ZUSAMMENGEKLAUBTER_XML_TEXTE="Textseiten_${BIB_CODE_NUMER}_allesamt.xml"
SAXON_JAR_DATEI_PFAD="/usr/share/java/saxon9.jar"
# siehe auch in den Funktionen Variable $GanzahlStellen

function testeProgrammAbhaengigkeiten () {
  # Beschreibung: teste Abhängigkeiten für diesen Programm-Code
  local brecheSkriptAb=0
  if ! command -v java &> /dev/null
  then
      echo -e "\e[31m# Fehler:\e[0m Programm für java (zur Verarbeitung des SAXON Paket) konnte nicht gefunden werden. Bitte über die Software-Verwaltung installieren oder Programm-Code entsprechend umschreiben für ein anderes XSLT-Verarbeitungsprogram (Stop)";
      brecheSkriptAb=1;
  fi
  if ! [[ -e "$SAXON_JAR_DATEI_PFAD" ]];
  then
      echo -e "\e[31m# Fehler:\e[0m Programm für SAXON Paket (XSLT-Verarbeitung) konnte nicht gefunden werden. Bitte über die Software-Verwaltung installieren oder Programm-Code entsprechend umschreiben für ein anderes XSLT-Verarbeitungsprogram (Stop)";
      brecheSkriptAb=1;
  fi
  if ! command -v wget &> /dev/null
  then
      echo -e "\e[31m# Fehler:\e[0m Programm wget (Herunterladen von Dateien) nicht gefunden. Bitte über die Software-Verwaltung installieren. (Stop)";
      brecheSkriptAb=1;
  fi
  if ! command -v pandoc &> /dev/null
  then
      echo -e "\e[31m# Warnung:\e[0m Programm pandoc (Umwandeln von XML Datei in Textdatei) nicht gefunden. Bitte über die Software-Verwaltung installieren. (Programm läuft weiter ohne XML -> Textumwandlung)";
  elif  ! command -v sed &> /dev/null
  then
      echo -e "\e[31m# Fehler:\e[0m Programm pandoc (Umwandeln von XML Datei in Textdatei) gefunden, aber Programm sed (Stream EDitor für Textersetzungen) fehlt. Bitte über die Software-Verwaltung installieren. (Stop)";
      brecheSkriptAb=1;
  fi
  if ! [[ -e "$XSL_STIL_DATEI" ]];
  then
      echo -e "\e[31m# Fehler:\e[0m XSLT-Datei zum Auslesen der XML-Bibliotheksdateien nicht gefunden. Es wurde nach folgender Datei gesucht: '$XSL_STIL_DATEI' (Programm-Variable: \$XSL_STIL_DATEI; Stop)";
      brecheSkriptAb=1;
  fi
  
  if [[ $brecheSkriptAb -gt 0 ]]; then exit; fi
}
testeProgrammAbhaengigkeiten

function dieseTexterkennungsXmlDatei () {
  # Pflichtparameter: $1 = Index-Nummer
  # Benutzung: dieseTexterkennungsXmlDatei 04 → Textauszug_04.html
  # Benutzung: dieseTexterkennungsXmlDatei  4 → Textauszug_04.html
  # Abhängigkeit: Variable LETZTE_SEITENNUMMER
  # Abhängigkeit: Variable BIB_CODE_NUMER
  local GanzahlStellen=${#LETZTE_SEITENNUMMER}
  local dieseNummer=`expr $1 + 0`
  printf "Textauszug_${BIB_CODE_NUMER}_%0${GanzahlStellen}d.html" $dieseNummer
}

function dieseXmlBibliotheksportalDatei () {
  # Pflichtparameter: $1 = Index-Nummer
  # Benutzung: dieseXmlBibliotheksportalDatei 04 → Texterkennungseite_Bibliothek_04.html
  # Benutzung: dieseXmlBibliotheksportalDatei  4 → Texterkennungseite_Bibliothek_04.html
  # Abhängigkeit: Variable LETZTE_SEITENNUMMER
  # Abhängigkeit: Variable BIB_CODE_NUMER
  local GanzahlStellen=${#LETZTE_SEITENNUMMER}
  local dieseNummer=`expr $1 + 0`
  printf "Texterkennungseite_Bibliothek_${BIB_CODE_NUMER}_%0${GanzahlStellen}d.html"  $dieseNummer
}

function dieseBilddatei () {
  # Pflichtparameter: $1 = Index-Nummer
  # Benutzung: dieseBilddatei 04 → Bild_04.jpg
  # Benutzung: dieseBilddatei  4 → Bild_04.jpg
  # Abhängigkeit: Variable LETZTE_SEITENNUMMER
  # Abhängigkeit: Variable BIB_CODE_NUMER
  local GanzahlStellen=${#LETZTE_SEITENNUMMER}
  local dieseNummer=`expr $1 + 0`
  printf "Bild_${BIB_CODE_NUMER}_%0${GanzahlStellen}d.jpg" $dieseNummer
}

function dieseXmlNetzQuelle () {
  local GanzahlStellen=8 # einstellbar
  # Pflichtparameter: $1 = Index-Nummer
  # Benutzung: dieseXmlNetzQuelle 04 → http…usw.…/4
  # Benutzung: dieseXmlNetzQuelle  4 → http…usw.…/4
  # Abhängigkeit: Variable LETZTE_SEITENNUMMER
  # Abhängigkeit: Variable BIB_CODE_NUMER
  local dieseNummer=`expr $1 + 0`
  #   printf "https://api.digitale-sammlungen.de/ocr/bsb10112188/%d" $dieseNummer
  printf "https://api.digitale-sammlungen.de/ocr/${BIB_CODE_NUMER}/%d" $dieseNummer
}

function diesesBildGroesstmoeglichAlsNetzQuelle () {
  # Pflichtparameter: $1 = Index-Nummer
  local GanzahlStellen=5 # einstellbar
  # Benutzung: diesesBildGroesstmoeglichAlsNetzQuelle 04 → http…usw.…00000004.tif.original.jpg o.ä
  # Benutzung: diesesBildGroesstmoeglichAlsNetzQuelle  4 → http…usw.…00000004.tif.original.jpg o.ä.
  # Abhängigkeit: Variable LETZTE_SEITENNUMMER
  # Abhängigkeit: Variable BIB_CODE_NUMER
  local dieseNummer=`expr $1 + 0`

  # https://api.digitale-sammlungen.de/iiif/image/v2/bsb10114299_00117/full/full/0/default.jpg
  printf "https://api.digitale-sammlungen.de/iiif/image/v2/${BIB_CODE_NUMER}_%0${GanzahlStellen}d/full/full/0/default.jpg" $dieseNummer
  
}

# ------------------------------------------------
# Ausgabe bevor Programm beginnt
# ------------------------------------------------
echo -e "\033[0;32m##########################\033[0m"
if [[ $LADE_BILDER_HERUNTER -gt 0 ]];then
echo -e "\033[0;32m# Bilddateien und XML-Texterkennungsseiten herunterladen und XML Textauszug erstellen …\033[0m"
else
echo -e "\033[0;32m# Nur XML-Texterkennungsseiten herunterladen und XML Textauszug erstellen …\033[0m"
fi 
echo -e "\033[0;32m# Jetzt ${ERSTE_SEITENNUMMER} bis ${LETZTE_SEITENNUMMER} Seitennummern von \033[0m${BIB_CODE_NUMER}\033[0;32m herunterladen und Text in \033[0m${ZIELDATEI_ZUSAMMENGEKLAUBTER_XML_TEXTE}\033[0;32m zusammenfügen?\033[0m"
if [[ -e "${ZIELDATEI_ZUSAMMENGEKLAUBTER_XML_TEXTE}" ]];then
echo -e "\033[0;32m# (Datei ${ZIELDATEI_ZUSAMMENGEKLAUBTER_XML_TEXTE} wird überschrieben)\033[0m"
fi
echo -en "\033[0;32m# (ja/nein)\033[0m "

# ------------------------------------------------
# lese Kommandozeilen-Eingabe
# ------------------------------------------------
read janein
if [[ -z ${janein// /} ]];then janein="nein"; fi
case $janein in
  [jJ]|[jJ][aA])
    echo "# Weiter ..."
  ;;
  [nN]|[nN][eE][iI][nN])
    echo "# Stop";
    exit 1
  ;;
  *) 
    if [[ -z ${janein// /} ]];then
      echo -e "\033[0;32m# Stop\033[0m"
    else
      echo "# Eingabe nicht (als ja oder nein) erkannt „${janein}“ (Stop)"
    fi
    exit 1
  ;;
esac

# ------------------------------------------------
# Herunterladen der Bilder und XML-Dateien
# ------------------------------------------------
for s in `seq --equal-width $ERSTE_SEITENNUMMER  $LETZTE_SEITENNUMMER`; do
  
  # # # # # # # # # # # # # # # # # 
  if [[ $LADE_BILDER_HERUNTER -gt 0 ]];then
    echo -en "# $s von $LETZTE_SEITENNUMMER Bildseiten: "` dieseBilddatei $s `" herunterladen …"; 
    if [[ -e `dieseBilddatei $s` ]]; then
      if [[ $(find . -maxdepth 1 -empty -name $(dieseBilddatei $s)) ]]; then
        echo -en ` dieseBilddatei $s ` " (überschreibe leere Bilddatei) …\n"; 
        wget --quiet ` diesesBildGroesstmoeglichAlsNetzQuelle $s `  --output-document=` dieseBilddatei $s ` ;
      else
        echo -en ` dieseBilddatei $s ` " (überspringe, vorhandenes Bild) …\n"; 
      fi
    else
      echo -en "\n"
      wget --quiet ` diesesBildGroesstmoeglichAlsNetzQuelle $s `  --output-document=` dieseBilddatei $s ` ;
    fi
  fi
  # # # # # # # # # # # # # # # # #   
  
  echo -en "# $s von $LETZTE_SEITENNUMMER Texterkennungsseiten: "` dieseXmlBibliotheksportalDatei $s ` "herunterladen …"; 
  if [[ -e `dieseXmlBibliotheksportalDatei $s` ]]; then
    if [[ $(find . -maxdepth 1 -empty -name $(dieseXmlBibliotheksportalDatei $s)) ]]; then
    echo -en ` dieseXmlBibliotheksportalDatei $s ` " (überschreibe leere Bibliotheksdatei) …\n"; 
    wget --quiet `dieseXmlNetzQuelle $s`  --output-document=`dieseXmlBibliotheksportalDatei $s`;
    else
    echo -en ` dieseXmlBibliotheksportalDatei $s ` " (überspringe, weil Bibliotheksdatei schon vorhanden) …\n"; 
    fi
  else
    echo -en "\n"
    wget --quiet `dieseXmlNetzQuelle $s`  --output-document=`dieseXmlBibliotheksportalDatei $s`;
  fi
done

# ------------------------------------------------
# Texterkennung vermittels XSLT herauslesen und Einzeldokumente schreiben und Gesamtdokument erstellen
# ------------------------------------------------
for s in `seq --equal-width $ERSTE_SEITENNUMMER  $LETZTE_SEITENNUMMER`; do
  if [[ ` expr $s + 0 ` -eq `expr $ERSTE_SEITENNUMMER + 0 ` ]];then 
    echo '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' > $ZIELDATEI_ZUSAMMENGEKLAUBTER_XML_TEXTE; 
  fi

  echo -en "# $s von $LETZTE_SEITENNUMMER Seiten: "` dieseXmlBibliotheksportalDatei $s `" auslesen, hinein in "` dieseTexterkennungsXmlDatei $s `" … ";
  
  if [[ $(find . -maxdepth 1 -empty -name $(dieseXmlBibliotheksportalDatei $s)) ]]; then
    echo -e "\n\e[31m# Fehler:\e[0m Datei ` dieseXmlBibliotheksportalDatei $s ` ist leer. Kann keine Textdaten auslesen (überspringe diesen Schritt)";
  else
    java -jar $SAXON_JAR_DATEI_PFAD  -xsl:"$XSL_STIL_DATEI" -s:` dieseXmlBibliotheksportalDatei $s ` -o:` dieseTexterkennungsXmlDatei $s `;
    echo -en "und in $ZIELDATEI_ZUSAMMENGEKLAUBTER_XML_TEXTE einfüllen …\n"
    echo '<!--' "Seite $s -->"            >> $ZIELDATEI_ZUSAMMENGEKLAUBTER_XML_TEXTE;
    cat ` dieseTexterkennungsXmlDatei $s ` >> $ZIELDATEI_ZUSAMMENGEKLAUBTER_XML_TEXTE;
  fi

  
done


# ------------------------------------------------
# Textumwandlung von XML in reinen Text
# ------------------------------------------------
if command -v pandoc &> /dev/null
then
  if [[ -e "${ZIELDATEI_ZUSAMMENGEKLAUBTER_XML_TEXTE}" ]] ||  [[ $(find . -maxdepth 1 -empty -name "${ZIELDATEI_ZUSAMMENGEKLAUBTER_XML_TEXTE}") ]]; then
    echo "# Verarbeitung: erstelle Textdatei (XML -> TXT, Programm pandoc) ${ZIELDATEI_ZUSAMMENGEKLAUBTER_XML_TEXTE}.txt …"
    echo "# Verarbeitung: füge <br/> zwischenzeitlich ein vor jeder </Zeile>, damit Zeilenumbrüche in Textdatei erscheinen, sonst würde pandoc fließende Absätze ausformen …"
    sed -r 's@</Zeile>$@<br/></Zeile>@;'  "${ZIELDATEI_ZUSAMMENGEKLAUBTER_XML_TEXTE}" | pandoc -f html -t plain > "${ZIELDATEI_ZUSAMMENGEKLAUBTER_XML_TEXTE}.txt"
    echo "# Ergebnis siehe  XML-Datei: ${ZIELDATEI_ZUSAMMENGEKLAUBTER_XML_TEXTE}"
    echo "# Ergebnis siehe Text-Datei: ${ZIELDATEI_ZUSAMMENGEKLAUBTER_XML_TEXTE}.txt"
  else
    echo -e "\e[31m# Fehler:\e[0m XML-Datei für den Textauszug ${ZIELDATEI_ZUSAMMENGEKLAUBTER_XML_TEXTE} konnte nicht erstellt werden (vielleicht gibt es Netzwerkprobleme oder andere Fehler) …"
  fi
fi

echo "# ---------------------------------------------------------------------"
echo "# Ende: folgende Dateien bleiben noch übrig (könnten später vielleicht glöscht werden) …"
suche_1=`echo $(dieseXmlBibliotheksportalDatei $LETZTE_SEITENNUMMER) | sed -r 's@_[0-9]+.html@_*.html@' `
  ls $suche_1 | sed -r 's@_[0-9]+.html@_………….html@' | uniq -c | sed 's@^@# Siehe auch Dateien:@'
suche_2=`echo $(dieseTexterkennungsXmlDatei $LETZTE_SEITENNUMMER) | sed -r 's@_[0-9]+.html@_*.html@' `
  ls $suche_2 | sed -r 's@_[0-9]+.html@_………….html@' | uniq -c | sed 's@^@# Siehe auch Textauszug-Dateien:@'
if [[ $LADE_BILDER_HERUNTER -gt 0 ]];then
suche_3=`echo $(dieseBilddatei $LETZTE_SEITENNUMMER) | sed -r 's@_[0-9]+.jpg@_*.jpg@' `
  ls $suche_3 | sed -r 's@_[0-9]+.jpg@_………….jpg@' | uniq -c | sed 's@^@# Siehe auch Bild-Dateien:@'
fi
echo "# Fertig."
