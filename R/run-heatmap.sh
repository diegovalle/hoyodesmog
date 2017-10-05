#!/bin/bash
set -e # stop the script on errors
set -u # unset variables are an error
set -o pipefail # piping a failed process into a successful one is an arror
export LANG="en_US.UTF-8"; export LC_CTYPE="en_US.UTF-8";
export TZ="America/Mexico_City"
DIR=/var/www/hoyodesmog.diegovalle.net/R
# Set these variables
LOCKFILE=/tmp/heatmap.lock
OLDFILE=timestamps/heatmap_aire_old.html
NEWFILE=timestamps/heatmap_aire_new.html
SCRIPT=run-heatmap.R

: "${HEATMAP_HEALTHCHECK:?Need to set HEATMAP_HEALTCHECK non-empty}"
: "${NETLIFYAPIKEY:?Need to set NETLIFYAPIKEY non-empty}"

if [ -d $DIR ]
then
    cd $DIR
fi

clean_html_table() {
    lynx -dump -width 1000 "$1" | \
        sed -e '/^.*Promedios horarios/ d' | \
        sed -e 's/^[ ]*//g' | \
        sed -e '/^$/d' | \
        sed -e 's/\s\{1,\}/,/g' | \
        sed -e 's/nr/NA/g' | \
        head -n -1
}

download_data() {
    month=$(date +"%m")
    year=$(date +"%Y")
    parametro=$1
    tipo=$2
    FILENAME=$3
    URL="http://www.aire.cdmx.gob.mx/estadisticas-consultas/concentraciones/respuesta.php?qtipo="
    if [ "$(date +"%d")" -lt 9 ]; then
        month_before="$(date -d 'last month' +'%m')"
        year_before="$(date -d 'last month' +'%Y')"
        clean_html_table "$URL$tipo&parametro=$parametro&anio=$year_before&qmes=$month_before" > "$FILENAME"
        # Remove first line with column names since we are appending
        clean_html_table "$URL$tipo&parametro=$parametro&anio=$year&qmes=$month" | tail -n +2 >> "$FILENAME"
    else
        clean_html_table "$URL$tipo&parametro=$parametro&anio=$year&qmes=$month" > "$FILENAME"
    fi
}

main() {
    if [ ! -f $OLDFILE ]
    then
        echo "creating $OLDFILE"
        echo "no data" > $OLDFILE
    fi

    curl -L -s http://www.aire.cdmx.gob.mx/ultima-hora-reporte.php 2>&1 | grep -A1 textohora  > $NEWFILE
    oldfile_md5=$(md5sum $OLDFILE | awk '{ print $1 }')
    newfile_md5=$(md5sum $NEWFILE | awk '{ print $1 }')

    if [ "$oldfile_md5" = "$newfile_md5" ]
    then
        printf "$(TZ="America/Mexico_City" date +'%Y-%m-%d %H %Z') %s and %s have the same content\n" $OLDFILE $NEWFILE
    else
        printf "\n\n%s and %s have DIFFERENT content\n" $OLDFILE $NEWFILE
        echo "date right now: $(TZ="America/Mexico_City" date +'%Y-%m-%d %H %Z')"

        # Download data from aire.cdmx.gob.mx with lynx because of problems
        # doing it from R
        download_data "pm10" "HORARIOS" "data/pm10.csv"
        download_data "o3" "HORARIOS" "data/o3.csv"
        download_data "co" "HORARIOS" "data/co.csv"
        download_data "no2" "HORARIOS" "data/no2.csv"
        download_data "so2" "HORARIOS" "data/so2.csv"

        download_data "pm2" "HORARIOS" "data/pm2.csv"
        download_data "nox" "HORARIOS" "data/nox.csv"
        download_data "wsp" "HORARIOS" "data/wsp.csv"
        download_data "wdr" "HORARIOS" "data/wdr.csv"
        download_data "tmp" "HORARIOS" "data/tmp.csv"


        echo "output from program:"
        Rscript $SCRIPT

        printf "\n\n"

        mv -f $NEWFILE $OLDFILE
        if [ "$CI" != "true" ]; then
            ./netlifyctl -A "$NETLIFYAPIKEY" deploy
            curl -fsS --retry 3 "$HEATMAP_HEALTHCHECK" > /dev/null
        fi
        echo "Waiting for the the hour"
        read min sec <<<$(date +'%M %S')
        sleep $(( 3600 - 10#$min*60 - 10#$sec ))
    fi
}

(
    # Wait for lock on /tmp/pollution.lock (fd 200)
    flock -n 200
    # Do stuff
    main
    #since this script is called from cron, and cron has a minimum
    #interval of 1 min run it again after 30s
    sleep 30
    main
) 200>$LOCKFILE
