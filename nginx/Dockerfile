FROM nginx:1.27.0

# App Domain
ARG DOMAIN="localhost"

# Country Name (2 letter code)
ARG C="BR"

# State or Province Name (full name)
ARG ST="Santa Catarina"

# Locality Name (eg, city)
ARG L="Imbituba"

# Organization Name (eg, company)
ARG O="Freelancer S.A."

# Cert Domain
ARG CN="${DOMAIN}"

# Nginx certs folder
ARG CERTS_FOLDER="/etc/nginx/certs"

RUN mkdir ${CERTS_FOLDER}

RUN openssl genpkey -algorithm RSA -out ${CERTS_FOLDER}/${DOMAIN}.key

RUN openssl req -new -key ${CERTS_FOLDER}/${DOMAIN}.key \
    -out ${CERTS_FOLDER}/${DOMAIN}.csr \
    -subj "/C=${C}/ST=${ST}/L=${L}/O=${O}/CN=${CN}"

RUN openssl x509 -req -days 365 -in ${CERTS_FOLDER}/${DOMAIN}.csr \
    -signkey ${CERTS_FOLDER}/${DOMAIN}.key \
    -out ${CERTS_FOLDER}/${DOMAIN}.crt
