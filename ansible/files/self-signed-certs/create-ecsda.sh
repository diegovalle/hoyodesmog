domain=hoyodesmog.diegovalle.net

openssl genrsa  2048 > account.key
openssl ecparam -genkey -name prime256v1 -noout -out domain.key

#for a single domain
openssl req -new -sha256 -key domain.key -subj "/CN="$domain"" > cert.csr

#openssl req -new -sha256 -key domain.key -subj "/" -reqexts SAN -config <(cat /etc/ssl/openssl.cnf <(printf "[SAN]\nsubjectAltName=DNS:$domain,DNS:www.$domain")) > cert.csr

openssl x509 -req -sha256 -days 365 -in cert.csr -signkey domain.key -out cert.crt
openssl x509 -in cert.crt -out chained.pem -outform PEM
