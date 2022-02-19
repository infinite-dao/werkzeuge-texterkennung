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
# Abhängigkeit: nice (zwingend erforderlich; java als Hintergrundprozess starten)
# Abhängigkeit: sed (Stream Editor), uniq (zum Zählen)
# Abhängigkeit: pandoc (XML => Textumwandlung, kann fehlen)

# ------------------------------------------------
# Variablen zum Anpassen bevor Programm ausgeführt wird
# Anfang einstellbarer Variablen
# ------------------------------------------------
  XSL_STIL_DATEI="bsb_OCR_Text_herausfiltern.xsl"
  # Hinweis: zu prüfen ist vielleicht auch, ob die api URL stimmig ist, siehe BASH-Funktionen:
  # - dieseNetzQuelleApiXmlHtmlSeite
  # - dieseNetzQuelleGroesstmoeglichesBild
  # # # # # 
  ERSTE_SEITENNUMMER=1    # Ganzzahl: die tatsächliche Index-Nummer der Seite
  LETZTE_SEITENNUMMER=564 # Ganzzahl
  # BIB_CODE_NUMER="bsb10112188" # Alexander Kaufmann
  # BIB_CODE_NUMER="bsb10114299" # Mäurer, German: Gedichte und Gedanken eines Deutschen in Paris. 1: Gedichte
  # BIB_CODE_NUMER="bsb11161548" # Chwatal, Franz Xaver: Kinderlieder für Schule und Haus
  # BIB_CODE_NUMER="bsb10148142" # Estienne, Charles: Siben Bücher Von dem Feldbau vnd vollkom[m]ener bestellung
  # BIB_CODE_NUMER="bsb10119000" # Fischart, Johann: Johann Fischart's Geschichtklitterung und aller Praktik Großmutter
  # BIB_CODE_NUMER="bsb10326094" # Zedler Unviersal-Lexicon V-Veq. (1731-1754)
  # BIB_CODE_NUMER="bsb11099107" # Reinöhl, Wilhelm von: Die gute alte Zeit. 1,1: Zur Geschichte hauptsächlich des Stadtlebens
  # BIB_CODE_NUMER="bsb10586073" # Jaekel, Ernst Gottlob: Der germanische Ursprung der lateinischen Sprache und des römischen Volkes
  # BIB_CODE_NUMER="bsb10293479" # 1780, Abercrombie, John: Vollständige Anleitung zur Wartung aller in Europa bekannten Küchengartengewächse
  # BIB_CODE_NUMER="bsb10121032" # 1865, Maria Vinzenz Süß: Salzburgische Volks-Lieder mit ihren Singweisen
  # BIB_CODE_NUMER="bsb11437578" # 1789, Baierische Flora, Band 2
  # BIB_CODE_NUMER="bsb11437577" # 1789, Baierische Flora, Band 1
  # BIB_CODE_NUMER="bsb10761538" # 1867, Weiß - Kinder-Conversationslexicon, Band 1
  # BIB_CODE_NUMER="bsb10761539" # 1867, Weiß - Kinder-Conversationslexicon, Band 2
  # BIB_CODE_NUMER="bsb10761540" # 1867, Weiß - Kinder-Conversationslexicon, Band 3
  # BIB_CODE_NUMER="bsb10576662" # 1607, Petri, Friedrich Karl Wilhelm: Der Teutschen Weissheit
  # BIB_CODE_NUMER="bsb11023737" # 1919, Engel - Die Sprachschöpfer
  # BIB_CODE_NUMER="bsb11223968" # Der teutſchen Sprache Stammbaum und Wortwachs oder Teutſcher Sprachschatz … - Stieler - 1691
  # BIB_CODE_NUMER="bsb10260417" # Vierzig Fragen von der Seelen … - Böhme - 1682
  BIB_CODE_NUMER="bsb10303166" # Flora von Deutschland Schlechtendahl 05
  
  WERK_KURZTITEL="Flora von Deutschland Schlechtendahl 05 - 1845" # kann leer sein ODER kurzer Titel, der dem Dateinamen vorangesetzt wird
  ANWEISUNG_LADE_BILDER_HERUNTER=1     # 0 oder 1
  ANWEISUNG_ERGAENZE_DTD_HTML=1     # 0 oder 1
  ANWEISUNG_TILGE_EINZELDATEIEN_BIBLIOTHEK=1     # 0 oder 1
  ANWEISUNG_TILGE_EINZELDATEIEN_TEXTAUSZUG=1     # 0 oder 1
# ------------------------------------------------
# Ende einstellbarer Variablen
# ------------------------------------------------


# # # # # # # Eigentliches Programm: ab hier nur für Programmierer # # # # # # # # # # # # # #

WERK_KURZTITEL=$(echo "$WERK_KURZTITEL" | xargs) # Leerzeichentilgung vorn und hinten

DTD_HTML=`cat <<DTD
<!DOCTYPE html [
<!ENTITY shy  "&#173;" >
]>
DTD
`

ZIELDATEI_ZUSAMMENGEKLAUBTER_XML_TEXTE=$(
  [ -z "$WERK_KURZTITEL"  ] && \
    echo "Textseiten_${BIB_CODE_NUMER}_allesamt.xml" || \
    echo "${WERK_KURZTITEL}_Textseiten_${BIB_CODE_NUMER}_allesamt.xml"
)


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
  [ -z "${WERK_KURZTITEL// /}" ] && \
    printf "Textauszug_${BIB_CODE_NUMER}_%0${GanzahlStellen}d.html" $dieseNummer || \
    printf "Textauszug_${WERK_KURZTITEL}_${BIB_CODE_NUMER}_%0${GanzahlStellen}d.html" $dieseNummer
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
  [ -z "${WERK_KURZTITEL// /}" ] && \
    printf "Bild_${BIB_CODE_NUMER}_%0${GanzahlStellen}d.jpg" $dieseNummer || \
    printf "Bild_${WERK_KURZTITEL}_${BIB_CODE_NUMER}_%0${GanzahlStellen}d.jpg" $dieseNummer
}

function dieseNetzQuelleApiXmlHtmlSeite () {
  local GanzahlStellen=8 # einstellbar
  # Pflichtparameter: $1 = Index-Nummer
  # Benutzung: dieseNetzQuelleApiXmlHtmlSeite 04 → http…usw.…/4
  # Benutzung: dieseNetzQuelleApiXmlHtmlSeite  4 → http…usw.…/4
  # Abhängigkeit: Variable LETZTE_SEITENNUMMER
  # Abhängigkeit: Variable BIB_CODE_NUMER
  local dieseNummer=`expr $1 + 0`
  #   printf "https://api.digitale-sammlungen.de/ocr/bsb10112188/%d" $dieseNummer
  printf "https://api.digitale-sammlungen.de/ocr/${BIB_CODE_NUMER}/%d" $dieseNummer
}

function dieseNetzQuelleGroesstmoeglichesBild () {
  # Pflichtparameter: $1 = Index-Nummer
  local GanzahlStellen=5 # einstellbar
  # Benutzung: dieseNetzQuelleGroesstmoeglichesBild 04 → http…usw.…00000004.tif.original.jpg o.ä
  # Benutzung: dieseNetzQuelleGroesstmoeglichesBild  4 → http…usw.…00000004.tif.original.jpg o.ä.
  # Abhängigkeit: Variable LETZTE_SEITENNUMMER
  # Abhängigkeit: Variable BIB_CODE_NUMER
  local dieseNummer=`expr $1 + 0`

  # https://api.digitale-sammlungen.de/iiif/image/v2/bsb10114299_00117/full/full/0/default.jpg
  printf "https://api.digitale-sammlungen.de/iiif/image/v2/${BIB_CODE_NUMER}_%0${GanzahlStellen}d/full/full/0/default.jpg" $dieseNummer
  
}

# ------------------------------------------------
# Ausgabe bevor Programm beginnt
# ------------------------------------------------
echo -e "\033[0;32m########################################################################\033[0m"
echo -e "\033[0;32m#            Speichern und Herunterladen vom MDZ                        \033[0m"
echo -e "\033[0;32m# (Münchner DigitalisierungsZentrum: https://www.digitale-sammlungen.de)\033[0m"
echo -e "\033[0;32m########################################################################\033[0m"

if [[ $ANWEISUNG_LADE_BILDER_HERUNTER -gt 0 ]];then
echo -e "\033[0;32m# Bilddateien und XML-Texterkennungsseiten herunterladen und XML Textauszug erstellen …\033[0m"
else
echo -e "\033[0;32m# Nur XML-Texterkennungsseiten herunterladen und XML Textauszug erstellen …\033[0m"
fi 
if [[ $ANWEISUNG_TILGE_EINZELDATEIEN_TEXTAUSZUG -gt 0 ]];then
echo -e "\033[0;32m# Nacharbeiten: Bereinige schlußendlich einzelseitige Textauszug-Dateien …\033[0m"
else
echo -e "\033[0;32m# Nacharbeiten: Einzelseitige Textauszug-Dateien \033[0;31mbleiben\033[0;32m im Verzeichnis liegen …\033[0m"
fi 
if [[ $ANWEISUNG_TILGE_EINZELDATEIEN_BIBLIOTHEK -gt 0 ]];then
echo -e "\033[0;32m# Nacharbeiten: Bereinige schlußendlich einzelseitige Texterkennung-Bibliothek-Dateien …\033[0m"
else
echo -e "\033[0;32m# Nacharbeiten: Einzelseitige Texterkennung-Bibliothek-Dateien \033[0;31mbleiben\033[0;32m im Verzeichnis liegen …\033[0m"
fi 

echo -e "\033[0;32m# Jetzt \033[0m${ERSTE_SEITENNUMMER} bis ${LETZTE_SEITENNUMMER}\033[0;32m Seitennummern mit Bibliothek-Code \033[0m${BIB_CODE_NUMER}\033[0;32m herunterladen und Text in \033[0m${ZIELDATEI_ZUSAMMENGEKLAUBTER_XML_TEXTE}\033[0;32m zusammenfügen?\033[0m"
if [[ -e "${ZIELDATEI_ZUSAMMENGEKLAUBTER_XML_TEXTE}" ]];then
echo -e "\033[0;32m# (vorhandene Datei ${ZIELDATEI_ZUSAMMENGEKLAUBTER_XML_TEXTE} wird \033[0;31müberschrieben\033[0;32m)\033[0m"
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

for diese_nummernseite in `seq --equal-width $ERSTE_SEITENNUMMER  $LETZTE_SEITENNUMMER`; do  
  # # # # # # # # # # # # # # # # # 
  if [[ $ANWEISUNG_LADE_BILDER_HERUNTER -gt 0 ]];then
    echo -en "# $diese_nummernseite von $LETZTE_SEITENNUMMER: $(dieseBilddatei $diese_nummernseite) herunterladen …"; 
    if [[ -e "$(dieseBilddatei $diese_nummernseite)" ]]; then
      if [[ $( find . -maxdepth 1 -empty -name "$(dieseBilddatei $diese_nummernseite)" ) ]]; then
        echo -en "$(dieseBilddatei $diese_nummernseite) (überschreibe leere Bilddatei) …"; 
        wget --quiet "$( dieseNetzQuelleGroesstmoeglichesBild $diese_nummernseite )"  --output-document="$(dieseBilddatei $diese_nummernseite)" ;
      else
        echo -en "$(dieseBilddatei $diese_nummernseite) (überspringe, vorhandenes Bild) …"; 
      fi
    else
      wget --quiet "$( dieseNetzQuelleGroesstmoeglichesBild $diese_nummernseite )"  --output-document="$(dieseBilddatei $diese_nummernseite)" ;
    fi
    echo -en "\n"
  fi
  # # # # # # # # # # # # # # # # #  
  echo -en "# $diese_nummernseite von $LETZTE_SEITENNUMMER: $( dieseXmlBibliotheksportalDatei $diese_nummernseite ) herunterladen …"; 
  if [[ -e "$( dieseXmlBibliotheksportalDatei $diese_nummernseite )" ]]; then
    if [[ $( find . -maxdepth 1 -empty -name "$( dieseXmlBibliotheksportalDatei $diese_nummernseite )" ) ]]; then
    echo -en "$( dieseXmlBibliotheksportalDatei $diese_nummernseite ) (überschreibe leere Bibliotheksdatei) …"; 
    wget --quiet `dieseNetzQuelleApiXmlHtmlSeite $diese_nummernseite`  --output-document="$( dieseXmlBibliotheksportalDatei $diese_nummernseite )";
    else
    echo -en "$( dieseXmlBibliotheksportalDatei $diese_nummernseite ) (überspringe, vorhandene Bibliotheksdatei) …"; 
    fi
  else
    wget --quiet `dieseNetzQuelleApiXmlHtmlSeite $diese_nummernseite`  --output-document="$( dieseXmlBibliotheksportalDatei $diese_nummernseite )";
  fi
  if [[ $ANWEISUNG_ERGAENZE_DTD_HTML -gt 0 ]];then
    if [[ $(cat "$(dieseXmlBibliotheksportalDatei $diese_nummernseite)" | tr -d '\n' | grep -ci '^<html') -eq 1 ]];then 
      echo -en ', füge DTD Deklaration voran …' ;
      echo "$DTD_HTML" > Zwischenablage.html && cat "$(dieseXmlBibliotheksportalDatei $diese_nummernseite)" >> Zwischenablage.html && mv Zwischenablage.html "$(dieseXmlBibliotheksportalDatei $diese_nummernseite)"
    fi
  fi    
  echo -en "\n"
done

# ------------------------------------------------
# Texterkennung vermittels XSLT herauslesen und Einzeldokumente schreiben und Gesamtdokument erstellen
# ------------------------------------------------
for diese_nummernseite in `seq --equal-width $ERSTE_SEITENNUMMER  $LETZTE_SEITENNUMMER`; do
  if [[ ` expr $diese_nummernseite + 0 ` -eq `expr $ERSTE_SEITENNUMMER + 0 ` ]];then 
    echo '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' > "$ZIELDATEI_ZUSAMMENGEKLAUBTER_XML_TEXTE"; 
  fi

  echo -en "# $diese_nummernseite von $LETZTE_SEITENNUMMER: $( dieseXmlBibliotheksportalDatei $diese_nummernseite ) => $( dieseTexterkennungsXmlDatei $diese_nummernseite ) übertragen … ";
  
  if [[ $( find . -maxdepth 1 -empty -name "$( dieseXmlBibliotheksportalDatei $diese_nummernseite )" ) ]]; then
    echo -e "\n\e[31m# Fehler:\e[0m Datei „$( dieseXmlBibliotheksportalDatei $diese_nummernseite )“ ist leer. Kann keine Textdaten auslesen (überspringe diesen Schritt)";
  else
    # nice -n 19 java -jar $SAXON_JAR_DATEI_PFAD  -xsl:"$XSL_STIL_DATEI" -s:"$( dieseXmlBibliotheksportalDatei $diese_nummernseite )" -o:` dieseTexterkennungsXmlDatei $diese_nummernseite `;
    nice -n 19 java -jar $SAXON_JAR_DATEI_PFAD  -warnings:fatal -xsl:"$XSL_STIL_DATEI" -s:"$(dieseXmlBibliotheksportalDatei $diese_nummernseite)" -o:"$(dieseTexterkennungsXmlDatei $diese_nummernseite)";
    echo -en "und befülle $ZIELDATEI_ZUSAMMENGEKLAUBTER_XML_TEXTE …\n"
    echo '<!--' "Seite $diese_nummernseite -->"            >> "$ZIELDATEI_ZUSAMMENGEKLAUBTER_XML_TEXTE";
    if [[ -e "$( dieseTexterkennungsXmlDatei $diese_nummernseite )" ]];then
      cat "$( dieseTexterkennungsXmlDatei $diese_nummernseite )" >> "$ZIELDATEI_ZUSAMMENGEKLAUBTER_XML_TEXTE";
    else
      echo -e "\e[31m# Fehler:\e[0m# Datei $( dieseTexterkennungsXmlDatei $diese_nummernseite ) fehlt (überspringe und schreibe Notiz hinein) …"
      echo "<!-- Fehlende Datei $( dieseTexterkennungsXmlDatei $diese_nummernseite ) -->" >> "$ZIELDATEI_ZUSAMMENGEKLAUBTER_XML_TEXTE";
    fi
  fi

done
  


# ------------------------------------------------
# Textumwandlung von XML in reinen Text
# ------------------------------------------------
if command -v pandoc &> /dev/null
then
  if [[ -e "${ZIELDATEI_ZUSAMMENGEKLAUBTER_XML_TEXTE}" ]] ||  [[ $( find . -maxdepth 1 -empty -name "${ZIELDATEI_ZUSAMMENGEKLAUBTER_XML_TEXTE}" ) ]]; then
    echo "# Verarbeitung: erstelle Textdatei (XML -> TXT, Programm pandoc) ${ZIELDATEI_ZUSAMMENGEKLAUBTER_XML_TEXTE}.txt …"
    echo "# Verarbeitung: füge <br/> zwischenzeitlich ein vor jeder </Zeile>, damit Zeilenumbrüche in Textdatei erscheinen, sonst würde pandoc fließende Absätze ausformen …"
    sed -r 's@</Zeile>$@<br/></Zeile>@;'  "${ZIELDATEI_ZUSAMMENGEKLAUBTER_XML_TEXTE}" | pandoc -f html -t plain > "${ZIELDATEI_ZUSAMMENGEKLAUBTER_XML_TEXTE}.txt"
    echo "# Ergebnis siehe  XML-Datei: ${ZIELDATEI_ZUSAMMENGEKLAUBTER_XML_TEXTE}"
    echo "# Ergebnis siehe Text-Datei: ${ZIELDATEI_ZUSAMMENGEKLAUBTER_XML_TEXTE}.txt"
  else
    echo -e "\e[31m# Fehler:\e[0m XML-Datei für den Textauszug ${ZIELDATEI_ZUSAMMENGEKLAUBTER_XML_TEXTE} konnte nicht erstellt werden (vielleicht gibt es Netzwerkprobleme oder andere Fehler) …"
  fi
else
  if [[ -e "${ZIELDATEI_ZUSAMMENGEKLAUBTER_XML_TEXTE}" ]] ||  [[ $( find . -maxdepth 1 -empty -name "${ZIELDATEI_ZUSAMMENGEKLAUBTER_XML_TEXTE}" ) ]]; then
    echo "# Ergebnis siehe  XML-Datei: ${ZIELDATEI_ZUSAMMENGEKLAUBTER_XML_TEXTE}"
  else
    echo -e "\e[31m# Fehler:\e[0m XML-Datei für den Textauszug ${ZIELDATEI_ZUSAMMENGEKLAUBTER_XML_TEXTE} konnte nicht erstellt werden (vielleicht gibt es Netzwerkprobleme oder andere Fehler) …"
  fi
fi

echo -e "\033[0;32m# ----------------------------------\033[0m"
echo -e "\033[0;32m# Ende: folgende Dateien bleiben noch übrig (könnten später vielleicht glöscht werden) …\033[0m"
suchfilter_bibo=`echo "$(dieseXmlBibliotheksportalDatei $LETZTE_SEITENNUMMER)" | sed -r 's@_[0-9]+.html@_*.html@' `
if [[ $ANWEISUNG_TILGE_EINZELDATEIEN_BIBLIOTHEK -gt 0 ]];then
  echo -e "# Lösche Einzel-Dateien \033[0;37m$suchfilter_bibo\033[0m …"
  find . -name "$suchfilter_bibo" -type f -exec rm '{}' +
else
  find . -name "$suchfilter_bibo" -type f -exec ls '{}' + \
    | sed -r 's@_[0-9]+.html@_*.html@' | uniq -c | sed 's@^@# Siehe auch Dateien:@'
fi

suchfilter_texterkennung=`echo "$( dieseTexterkennungsXmlDatei $LETZTE_SEITENNUMMER )" | sed -r 's@_[0-9]+.html@_*.html@' `
if [[ $ANWEISUNG_TILGE_EINZELDATEIEN_TEXTAUSZUG -gt 0 ]];then
  echo -e "# Lösche Einzel-Dateien \033[0;37m$suchfilter_texterkennung\033[0m …"
  find . -name "$suchfilter_texterkennung" -type f -exec rm '{}' +
else
  find . -name "$suchfilter_texterkennung" -type f -exec ls '{}' + \
    | sed -r 's@_[0-9]+.html@_*.html@' | uniq -c | sed 's@^@# Siehe auch Textauszug-Dateien:@'
fi

if [[ $ANWEISUNG_LADE_BILDER_HERUNTER -gt 0 ]];then
suchfilter_bilder=`echo "$(dieseBilddatei $LETZTE_SEITENNUMMER)" | sed -r 's@_[0-9]+.jpg@_*.jpg@' `
  find . -name "$suchfilter_bilder" -type f -exec ls '{}' + \
    | sed -r 's@_[0-9]+.jpg@_*.jpg@' | uniq -c | sed 's@^@# Siehe auch Bild-Dateien:@'
fi
if [[ $ANWEISUNG_ERGAENZE_DTD_HTML -gt 0 ]];then
  if [[ -e Zwischenablage.html ]]; then rm Zwischenablage.html; fi
fi

echo -e "\033[0;32m# Fertig.\033[0m"
echo -e "\033[0;32m# ---------------------------------------------------------------------\033[0m"
