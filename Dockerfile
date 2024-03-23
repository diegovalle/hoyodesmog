# stage 0
FROM pierrezemb/gostatic as builder

# stage 1
FROM rocker/r-ubuntu:22.04
MAINTAINER "Diego Valle-Jones"

RUN apt-get update && apt-get install -y gnupg2 software-properties-common

ARG UNAME=hoyodesmog
ARG UID=1000
ARG GID=1000
ARG NODE_VERSION=18.18.0

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

RUN install2.r -r http://cran.rstudio.com -e --skipinstalled \
                caTools \
        chron \
        devtools \
        dplyr \
        ggmap \
        gstat \
        jsonlite \
        lubridate \
        methods \
        phylin \
        sendmailR \
        sp \
        stringr \
        tidyr \
        viridis \
        zoo \
        XML

RUN installGithub.r diegovalle/aire.zmvm@develop

# Install cron
RUN apt-get update && apt-get -y install cron

# Create backup-cron-cron file in the cron.d directory
RUN echo "*/1 * * * * . /dev/shm/.env && timeout -k 20 5m bash /var/www/hoyodesmog.diegovalle.net/R/run-heatmap.sh  > /proc/1/fd/1 2>/proc/1/fd/2"  > /etc/cron.d/hoyo-cron
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
RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.39.7/install.sh | bash
RUN . "$NVM_DIR/nvm.sh" && nvm install ${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm use v${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm alias default v${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && npm install -g npm@10.4.0
ENV PATH="$NVM_DIR/versions/node/v${NODE_VERSION}/bin/:${PATH}"
RUN npm i -g firebase-tools@13.2.1


COPY R /var/www/hoyodesmog.diegovalle.net/R
COPY web /var/www/hoyodesmog.diegovalle.net/web
WORKDIR /var/www/hoyodesmog.diegovalle.net/R

COPY --from=builder /goStatic /
RUN mkdir -p /srv/http/
RUN echo "<!doctype html><meta charset=utf-8><title>hello</title><body><h1>smog</h1></body>" > /srv/http/index.html

#CMD export > /dev/shm/.env && cron && /goStatic
CMD timeout -k 20 15m bash /var/www/hoyodesmog.diegovalle.net/R/run-heatmap.sh
