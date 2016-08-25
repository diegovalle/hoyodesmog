#!/bin/bash
set -e
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout domain-selfsigned.key -out cert-selfsigned.crt -subj "/C=US/ST=PA/L=Collegeville/O=hoyodesmog.diegovalle.net/OU=/CN=hoyodesmog.diegovalle.net"
wget -O - https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem > intermediate.pem
cat cert-selfsigned.crt  intermediate.pem > chained.pem

