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
ERROR_FILE=number_of_errors.txt
NETLIFY="$(whereis netlify | sed 's/^.*: //g')"

if [ -d $DIR ]
then
    cd $DIR
fi

: "${HEATMAP_HEALTHCHECK:?Need to set HEATMAP_HEALTCHECK non-empty}"
: "${NETLIFYAPIKEY:?Need to set NETLIFYAPIKEY non-empty}"
# Set CI to false if its unset
: "${CI:=false}"
# File to keep track of failed R executions
if [  ! -e  $ERROR_FILE ]; then printf 0 > $ERROR_FILE; fi

on_exit() {
    exit_code=$?
    if [ $exit_code -ge 1 ]; then
        ERRORS=$(cat $ERROR_FILE)
        ((++ERRORS))
        printf "%d" $ERRORS > $ERROR_FILE
        echo "ERROR $(date)"
    fi
    trap "" EXIT INT TERM
    exit $exit_code
}

clean_html_table() {
    lynx -dump -width 2000 "$1" | \
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
    tipo="HORARIOS"
    FILENAME=airedata/$parametro.csv
    rm -f "$FILENAME"
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

atomic_update() {
    TEMP_LINK=output_link
    CURRENT_DIR=$(pwd)
    TEMP_OUTPUT=output$(date +"%Y%m%d%H%M%S")
    # Atomic operation to change the website data directory
    cp -al output latest/"$TEMP_OUTPUT"
    ln -s "$CURRENT_DIR"/latest/"$TEMP_OUTPUT" $TEMP_LINK && mv -Tf $TEMP_LINK ../web/data
    find latest -mindepth 1 -maxdepth 1 -type d ! -name "$TEMP_OUTPUT" ! -name .gitkeep ! -name "." -exec rm -rf {} +
}

main() {
    if [ ! -f $OLDFILE ]
    then
        echo "creating $OLDFILE"
        echo "no data" > $OLDFILE
    fi

    curl -m 30 -L -s http://www.aire.cdmx.gob.mx/ultima-hora-reporte.php 2>&1 | grep -A1 textohora  > $NEWFILE
    oldfile_md5=$(md5sum $OLDFILE | awk '{ print $1 }')
    newfile_md5=$(md5sum $NEWFILE | awk '{ print $1 }')

    if [ "$oldfile_md5" != "$newfile_md5" ]
    then
        printf "\n\nDIFFERENT content\n"
        echo "Date right before download: $(TZ="America/Mexico_City" date +'%Y-%m-%d %H:%M:%S %Z')"

        # Download data from aire.cdmx.gob.mx with lynx because of problems
        # doing it from R
        ARRAY=( "pm10" "o3" "co" "no2" "so2" "pm2" "nox" "wsp" "wdr" "tmp")
        export -f download_data
        export -f clean_html_table
        parallel -j5 --joblog log-parallel.txt --timeout 240 --delay 1 download_data {} ::: "${ARRAY[@]}"

        echo "Finished aire.cdmx download:  $(TZ="America/Mexico_City" date +'%Y-%m-%d %H:%M:%S %Z')"

        # Make sure we don't enter an endless loop if there was an error
        # when creating the website, if more than 5 continuous errors then
        # sleep for 10 minutes
        trap "on_exit" INT TERM EXIT
        ERRORS=$(cat $ERROR_FILE)
        if [ "$ERRORS" -gt 4 ]; then
            echo "waiting $((600*ERRORS)) minutes because of too many ERRORs in Rscript"
            sleep $((600*ERRORS))
        fi
        echo "output from program:"
        timeout 4m Rscript $SCRIPT

        printf "\n\n"

        atomic_update
        # Don't update website when running in CI
        if [ "$CI" != "true" ]; then
            "$NETLIFY" -t "$NETLIFYAPIKEY" deploy
        fi

        mv -f $NEWFILE $OLDFILE
        # Reset the error count after successful run
        printf 0 > $ERROR_FILE
        curl -fsS --retry 3 "$HEATMAP_HEALTHCHECK" > /dev/null
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
