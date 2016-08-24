domain=hoyodesmog.diegovalle.net

openssl ecparam -genkey -name > account.key
openssl ecparam -genkey -name prime256v1 -noout -out domain.key
openssl req -new -sha256 -key domain.key -subj "/" -reqexts SAN -config <(cat /etc/ssl/openssl.cnf <(printf "[SAN]\nsubjectAltName=DNS:$domain,DNS:www.$domain")) > cert.csr
