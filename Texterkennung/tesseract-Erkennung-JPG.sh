#/bin/bash
# # # # # # # # # # # # # # 
# Beschreibung: Einfache Texterkennung (mittels Programmpakte Tesseract) von JPG Bilddateien
# # # # # # # # # # # # # # 
# Abhängigkeit: tesseract (eigentliche Texterkennung + Sprachenpakete)
# Abhängigkeit: dateutils (Zeitberechnung)
# Abhängigkeit: sed (für Textschnippsel)
# Abhängigkeit: nice (Rechnerleistung ausgleichen: als Hintergrundprozess befehligen)

# # # Tesseract Hilfe
  # Handbucheintrag aus tesseract (man tesseract), die Sprachen-Codes:
  # afr (Afrikaans) amh (Amharic) ara (Arabic) asm (Assamese) aze (Azerbaijani) 
  # aze_cyrl (Azerbaijani - Cyrilic) bel (Belarusian) ben (Bengali) bod (Tibetan) 
  # bos (Bosnian) bul (Bulgarian) cat (Catalan; Valencian) ceb (Cebuano) ces (Czech) 
  # chi_sim (Chinese - Simplified) chi_tra (Chinese - Traditional) chr (Cherokee) 
  # cym (Welsh) dan (Danish) dan_frak (Danish - Fraktur) deu (German) 
  # deu_frak (German - Fraktur) dzo (Dzongkha) ell (Greek, Modern (1453-)) eng (English) 
  # enm (English, Middle (1100-1500)) epo (Esperanto) equ (Math / equation detection 
  # module) est (Estonian) eus (Basque) fas (Persian) fin (Finnish) fra (French) 
  # frk (Frankish) frm (French, Middle (ca.1400-1600)) gle (Irish) glg (Galician) 
  # grc (Greek, Ancient (to 1453)) guj (Gujarati) hat (Haitian; Haitian Creole) 
  # heb (Hebrew) hin (Hindi) hrv (Croatian) hun (Hungarian) iku (Inuktitut) 
  # ind (Indonesian) isl (Icelandic) ita (Italian) ita_old (Italian - Old) 
  # jav (Javanese) jpn (Japanese) kan (Kannada) kat (Georgian) kat_old (Georgian - Old) 
  # kaz (Kazakh) khm (Central Khmer) kir (Kirghiz; Kyrgyz) kor (Korean) 
  # kur (Kurdish) lao (Lao) lat (Latin) lav (Latvian) lit (Lithuanian) mal (Malayalam) 
  # mar (Marathi) mkd (Macedonian) mlt (Maltese) msa (Malay) mya (Burmese) 
  # nep (Nepali) nld (Dutch; Flemish) nor (Norwegian) ori (Oriya) osd (Orientation and 
  # script detection module) pan (Panjabi; Punjabi) pol (Polish) por (Portuguese) 
  # pus (Pushto; Pashto) ron (Romanian; Moldavian; Moldovan) rus (Russian) 
  # san (Sanskrit) sin (Sinhala; Sinhalese) slk (Slovak) slk_frak (Slovak - Fraktur) 
  # slv (Slovenian) spa (Spanish; Castilian) spa_old (Spanish; Castilian - Old) 
  # sqi (Albanian) srp (Serbian) srp_latn (Serbian - Latin) swa (Swahili) swe (Swedish) 
  # syr (Syriac) tam (Tamil) tel (Telugu) tgk (Tajik) tgl (Tagalog) tha (Thai) 
  # tir (Tigrinya) tur (Turkish) uig (Uighur; Uyghur) ukr (Ukrainian) urd (Urdu) 
  # uzb (Uzbek) uzb_cyrl (Uzbek - Cyrilic) vie (Vietnamese) yid (Yiddish)
  
# # # Einstellbare Variablen
# lang="eng"
# lang="eng+enm+lat"
# lang="eng+bos+lat"
# lang="deu"
# lang="deu+lat"
# lang="deu+lat+deu-frak+eng"
# lang="deu+grc+lat"
# lang="deu+grc+ell+lat"
# lang="deu_frak+ell+lat"
# lang="lat"
# lang="deu-frak+lat"
lang="deu-frak+deu+lat"

# such_muster_filter="Seite * - Heracleum IMG_20200916"
such_muster_filter="Bild"

resize=0 # derzeit keine Funktion 
  # (Idee mit Hilfe ImageMagick convert kleine Bilder in ausgeklügelter Weise vergrößern zur Hilfenahme von Fred’s IM Scripts vielleicht)

# # # # # # # # # # Einstellbare Variablen (Ende)

pwd=`pwd`
cd "${pwd}"

dateien=`find . -maxdepth 1 -iname "${such_muster_filter}*.jpg" -type f | sort --ignore-case --version-sort`
dateien_txt=`find . -maxdepth 1 -iname "${such_muster_filter}*~${lang}.txt" -type f | sort --ignore-case --version-sort`
n_dateien=`find . -maxdepth 1 -iname "${such_muster_filter}*.jpg" -type f | sort --ignore-case --version-sort | wc -l`
n_dateien_txt=`find . -maxdepth 1 -iname "${such_muster_filter}*~${lang}.txt" -type f | sort --ignore-case --version-sort | wc -l`
i_datei=1

zeitdifferenz_fuer_n_taetigkeiten () {
  # zeitdifferenz_fuer_n_taetigkeiten starttime nowtime ntotaljobs nowjobsdone
  # zeitdifferenz_fuer_n_taetigkeiten --testen
  # zeitdifferenz_fuer_n_taetigkeiten "2021-12-06 16:47:29" "2021-12-09 13:38:08" 696926 611613
  local hiesziges_kommando_datediff
  
  while [[ "$#" -gt 0 ]]
  do
    case $1 in
      -t|--testen)
        if ! command -v datediff &> /dev/null &&  ! command -v dateutils.ddiff &> /dev/null
        then
          echo -e "\e[31m# Fehler: Weder Kommando datediff oder dateutils.ddiff wurde gefunden. Bitte installiere es über die Software-Systemverwaltung (vielleicht Paket dateutils).\e[0m"
          exit
        else
          return 0 # return [Zahl] und verlasse gesamte Funktion zeitdifferenz_fuer_n_taetigkeiten
        fi
      ;;
      *)
      break
      ;;
    esac
  done
  
  if ! command -v datediff &> /dev/null
  then
    # echo "Command dateutils.ddiff found"
    hiesziges_kommando_datediff="dateutils.ddiff"
  elif ! command -v dateutils.ddiff &> /dev/null
    then
      # echo "Command datediff found"
      hiesziges_kommando_datediff="datediff"
  fi

  # START estimate time to do 
  local hier_unixsekunden_begonnen=$(date --date="$1" '+%s')
  local hier_unixsekunden_jetzt=$(date --date="$2" '+%s')
  local hier_taetigkeit_gesamt=$(expr $3 + 0)
  local hier_taetigkeit_zaehler=$(expr $4 + 0)
  local hier_zeitdifferenz_unixsekunden=$(( hier_unixsekunden_jetzt - hier_unixsekunden_begonnen ))
  local hier_n_taetigkeiten_zutun=$(( hier_taetigkeit_gesamt - hier_taetigkeit_zaehler ))
  
  echo -e "\033[2m# Testmodus: gesamt $hier_taetigkeit_gesamt ; Zähler $hier_taetigkeit_zaehler\033[0m"
  if [[ $hier_taetigkeit_gesamt -eq $hier_taetigkeit_zaehler ]];then # done
    hier_unixsekunden_zutun=0
    soweit_fertig=`$hiesziges_kommando_datediff "@$hier_unixsekunden_begonnen" "@$hier_unixsekunden_jetzt" -f "alle $hier_taetigkeit_zaehler fertig, Dauer %dd %0HStd:%0MMin:%0SSek"`
    soweit_geschaetzt="nichts mehr zu tun"
  else
    hier_unixsekunden_zutun=$(( hier_zeitdifferenz_unixsekunden * hier_n_taetigkeiten_zutun / hier_taetigkeit_zaehler ))
    soweit_fertig=`$hiesziges_kommando_datediff "@$hier_unixsekunden_begonnen" "@$hier_unixsekunden_jetzt" -f "$hier_taetigkeit_zaehler soweit fertig %dTag(e) %0HStd:%0MMin:%0SSek"`
    soweit_geschaetzt=`$hiesziges_kommando_datediff "@0" "@$hier_unixsekunden_zutun" -f "$hier_n_taetigkeiten_zutun zu tun, geschätztes Ende %dTag(e) %H0Std:%0MMin:%0SSek"`
  fi
  echo -e "\033[0;32m# von $hier_taetigkeit_gesamt $soweit_fertig; $soweit_geschaetzt\033[0m"
  # END estimate time to do 
}
zeitdifferenz_fuer_n_taetigkeiten --testen

echo -e "\033[0;32m##########################\033[0m"
if ! [[ -z ${such_muster_filter// /} ]];then 
  echo -e "\033[0;32m# Suchmuster: ${such_muster_filter}*.jpg\033[0m"
fi
if [[ $n_dateien_txt -gt 0 ]];then
  echo -e "\033[0;32m# Fortsetzen für $(( $n_dateien - $n_dateien_txt )) aus ${n_dateien} Dateien Text ($lang, resize:$resize) erkennen lassen?\033[0m"
else
  echo -e "\033[0;32m# Für ${n_dateien} Dateien Text ($lang, resize:$resize) erkennen lassen?\033[0m"
fi
echo -en "\033[0;32m# (ja/nein)\033[0m "

read janein
if [[ -z ${janein// /} ]];then janein="nein"; fi
case $janein in
  [jJ]|[jJ][aA])
    echo "Weiter ..."
  ;;
  [nN]|[nN][eE][iI][nN])
    echo "Stop";
    exit 1
  ;;
  *) 
    if [[ -z ${janein// /} ]];then
      echo -e "\033[0;32m# Stop\033[0m"
    else
      echo "Falsche Eingabe „${janein}“ (Stop)"
    fi
    exit 1
  ;;
esac

# thisDateTimeEstimatedEnd=0
# dateStart=$(date +"%s")
# thisDateTime=$(date +"%s")
zeit_beginn=$(date --rfc-3339=seconds)
config_datei="config_table-detect-in-tesseract.txt"

IFS=$'\n' # überschreibe for-Trenner → Zeilenumbruch
for datei in `echo -en "${dateien}"`;do
  # echo -e "\033[0;32m##########################\033[0m"
  prozent_geschafft=`echo "scale=3;(${i_datei}/${n_dateien})*100" | bc | sed 's@\.@,@'`
  if [[ -e "${datei%.*}~${lang}.txt" ]];then
    printf "\033[0;32m# Text schon erkannt ($lang) bei '%s' %04d von %04d (%0.1f%%)…\033[0m\n" "${datei}"  $i_datei $n_dateien $prozent_geschafft
  else
    printf "\033[0;32m# Text erkennen ($lang) bei '%s' %04d von %04d (%0.1f%%)…\033[0m\n" "${datei}"  $i_datei $n_dateien $prozent_geschafft 
    
    if [[ -f "${config_datei}" ]];then
      echo "Verwende ${config_datei} ..."
      nice -n 19 tesseract "${datei%.*}.jpg" "${datei%.*}~${lang}" -l "$lang" "${config_datei}"
    else 
      nice -n 19 tesseract "${datei%.*}.jpg" "${datei%.*}~${lang}" -l "$lang" 
    fi
  fi
  zeitdifferenz_fuer_n_taetigkeiten $zeit_beginn $(date --rfc-3339=seconds) $n_dateien $i_datei
  i_datei=$(( i_datei + 1 ))
  
done # Schleifenende

IFS=$' \n\t' # alten for-Trenner zurück
