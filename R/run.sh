#!/bin/bash
set -e # stop the script on errors
set -u # unset variables are an error
set -o pipefail # piping a failed process into a successful one is an arror
export LANG="en_US.UTF-8"; export LC_CTYPE="en_US.UTF-8";
export TZ="America/Mexico_City"
cd /var/www/hoyodesmog.diegovalle.net/R

main() {
    if [ ! -f aire_old.html ]
    then
        echo "creating aire_old.html"
        echo "no data" > aire_old.html
    fi

    curl http://www.aire.df.gob.mx/ultima-hora-reporte.php 2>&1 | grep -A1 textohora  > aire_new.html
    file_old=$(md5sum aire_old.html | awk '{ print $1 }')
    file_new=$(md5sum aire_new.html | awk '{ print $1 }')

    if [ "$file_old" = "$file_new" ]
    then
        echo "Files have the same content"
    else
        echo "Files have DIFFERENT same content"
        for i in timestamp*; do
            if [ "$(head -c 15 "$i")" != "$(date '+["%Y-%m-%d %H')" ]
            then
                head -c 15 "$i"
                date '+["%Y-%m-%d %H'
                Rscript run-all.R
            fi
        done
        mv -f aire_new.html aire_old.html
    fi
}

(
                  # Wait for lock on /tmp/pollution.lock (fd 200)
                  flock -n 200

                  # Do stuff
                  main

) 200>/tmp/pollution.lock
