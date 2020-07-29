FROM rocker/r-ubuntu:20.04

MAINTAINER "Diego Valle-Jones"

RUN apt-get update && apt-get install -y gnupg2 software-properties-common

ARG UNAME=hoyodesmog
ARG UID=1000
ARG GID=1000
ARG NODE_VERSION=12.18.3

RUN groupadd -g $GID -o $UNAME
RUN useradd -m -u $UID -g $GID -o -s /bin/bash $UNAME

RUN apt-get update && \
        apt-get install -y \
        bash \
        netcat \
        parallel \
        lynx \
        curl \
        libxml2-dev \
        libgdal-dev \
        libproj-dev \
        libssl-dev \
        r-recommended \
        r-cran-rjava \
        r-cran-tidyr \
        r-cran-devtools \
        r-cran-dplyr \
        r-cran-stringr \
        r-cran-ggplot2 \
        r-cran-gstat \
        r-cran-sf \
        r-cran-readr \
        r-cran-lubridate \
        r-cran-rvest \
        r-cran-readxl


## make sure Java can be found in rApache and other daemons not looking in R ldpaths
RUN echo "/usr/lib/jvm/java-8-oracle/jre/lib/amd64/server/" > /etc/ld.so.conf.d/rJava.conf
RUN /sbin/ldconfig

RUN install2.r -r http://cran.rstudio.com -e --skipinstalled \
        XML \
        caTools \
        chron \
        devtools \
        dplyr \
        ggmap \
        gstat \
        jsonlite \
        lubridate \
        mailR \
        methods \
        sp \
        stringr \
        tidyr \
        viridis \
        zoo \
        phylin

RUN installGithub.r diegovalle/aire.zmvm
RUN mkdir -p /hoyodesmog && chown hoyodesmog:hoyodesmog /hoyodesmog

# Install cron
RUN apt-get update && apt-get -y install cron

# Create backup-cron-cron file in the cron.d directory
RUN echo "*/1 * * * * . /hoyodesmog/.env && bash /var/www/hoyodesmog.diegovalle.net/R/run-heatmap.sh  > /proc/1/fd/1 2>/proc/1/fd/2"  > /etc/cron.d/hoyo-cron
# Give execution rights on the cron job
RUN chmod 0644 /etc/cron.d/hoyo-cron

# Apply cron job
RUN crontab /etc/cron.d/hoyo-cron
# Create the log file to be able to run tail
RUN touch /var/log/cron.log

#USER $UNAME

# Install nodejs
ENV NVM_DIR=/hoyodesmog/.nvm
RUN mkdir -p $NVM_DIR
RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh | bash
RUN . "$NVM_DIR/nvm.sh" && nvm install ${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm use v${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm alias default v${NODE_VERSION}
ENV PATH="$NVM_DIR/versions/node/v${NODE_VERSION}/bin/:${PATH}"
RUN npm i -g firebase-tools

COPY R /var/www/hoyodesmog.diegovalle.net/R
COPY web /var/www/hoyodesmog.diegovalle.net/web
COPY webserver.sh /hoyodesmog
WORKDIR /var/www/hoyodesmog.diegovalle.net/R

CMD export > /hoyodesmog/.env && cron -f
#watch -n60 ./run-heatmap.sh
