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

if [ -d $DIR ]
then
    cd $DIR
fi

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

        echo "output from program:"
        Rscript $SCRIPT

        printf "\n\n"

        mv -f $NEWFILE $OLDFILE
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
