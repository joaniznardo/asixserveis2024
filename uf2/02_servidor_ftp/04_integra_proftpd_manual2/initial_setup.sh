#!/bin/bash
# certificats
mkdir ./certs
curl https://traefik.me/privkey.pem -o ./certs/demo.traefik.me.key
curl https://traefik.me/cert.pem -o ./certs/demo.traefik.me.crt
openssl req -new -newkey rsa:4096 -days 365  -nodes -x509 -keyout ./certs/proftpd.key -out ./certs/proftpd.crt -subj '/C=SP/ST=Testing/L=Barcelona/O=ITIC/CN=proftp.traefik.me'
# directoris comptes virtuals
mkdir -p ./data/ftp/test01
mkdir -p ./data/ftp/test02
# configuració proftpd
mkdir ./proftpd-config

tee ./proftpd-config/tls.conf << EOF
<IfModule mod_tls.c>
TLSEngine                               on
TLSLog                                  /var/log/proftpd/tls.log
TLSProtocol                             SSLv23
TLSRSACertificateFile                   /etc/ssl/certs/proftpd.crt
TLSRSACertificateKeyFile                /etc/ssl/private/proftpd.key
TLSVerifyClient                         off
TLSRequired                             on
TLSRenegotiate                          required off
</IfModule>
EOF

tee ./proftpd-config/comptes-virtuals << EOF
### --
##  -- fitxer de configuracio (virtual_users.conf a /etc/proftpd/conf.d )
### --
# no permetre que els comptes retrocedesquen ("pugen") en l'arbre de directoris
DefaultRoot ~
RequireValidShell off

# fitxer associat per als comptes virtuals
AuthUserFile /etc/proftpd/ftpd.passwd
# no crearem grups per compartir info entre els comptes virtuals
## AuthGroupFile /etc/proftpd/ftpd.group

# Sols permetre l'acces amb comptes virtuals 
AuthOrder mod_auth_file.c 
# si vulguerem que tambe els comptes del sistema ho feren...
## AuthOrder mod_auth_file.c mod_auth_unix.c
EOF

# configuració apache
mkdir ./apache-config

tee ./apache-config/doble-web.conf << EOF
<VirtualHost *:443>
    ServerName proftpd-https.traefik.me
    DocumentRoot /var/www/html/https
    
    SSLEngine on
    SSLCertificateFile /etc/apache2/ssl/demo.traefik.me.crt
    SSLCertificateKeyFile /etc/apache2/ssl/demo.traefik.me.key
    
    #Protocols h2 http/1.1
    Protocols h2 
    
    <Directory /var/www/html/https>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>

<VirtualHost *:80>
    ServerName proftpd-http.traefik.me
    DocumentRoot /var/www/html/http
    #Protocols h2c http/1.1
    Protocols h2c 
    
    <Directory /var/www/html/http>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF
