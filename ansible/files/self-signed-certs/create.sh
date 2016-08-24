#!/bin/bash
set -e
openssl genrsa -des3 -passout pass:x -out domain.pass.key 2048
openssl rsa -passin pass:x -in domain.pass.key -out domain.key
rm domain.pass.key
openssl req -new -key domain.key -out cert.csr -subj "/C=US/ST=PA/L=Collegeville/O=aa.com/OU=/CN=aa.com"
openssl x509 -req -sha256 -days 365 -in cert.csr -signkey domain.key -out cert.crt
openssl x509 -in cert.crt -out chained.pem -outform PEM
cp /etc/nginx/ssl/hoyodesmog.diegovalle.net/
