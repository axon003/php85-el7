#!/bin/bash
: "${PHP85_WORK:?set PHP85_WORK to the work directory}"
# test85_runtime.sh - on the build host: testeaza tarball-ul si RPM-urile pe centos:7 CURAT (fara devel).
#   bash test85_runtime.sh tar   -> tarball + pachete runtime minime
#   bash test85_runtime.sh rpm   -> yum localinstall (base+libs, apoi toate)
set -o pipefail
MODE=${1:-tar}
cat > ${PHP85_WORK}/build/_inner_$MODE.sh <<'EOT'
set -eo pipefail
MODE=$1
sed -i 's|^mirrorlist=|#mirrorlist=|; s|^#\?baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|' /etc/yum.repos.d/CentOS-*.repo
sed -i 's|\$releasever|7.9.2009|g' /etc/yum.repos.d/CentOS-*.repo
yum -y -q install epel-release >/dev/null
sed -i 's|^metalink=.*|#&|; s|^#\?baseurl=.*|baseurl=https://archives.fedoraproject.org/pub/archive/epel/7/$basearch/|' /etc/yum.repos.d/epel.repo
O=/work/out
if [ "$MODE" = tar ]; then
  # lista runtime (din ldd) - aceeasi cu Requires din RPM
  yum -y -q install glibc readline bzip2-libs libffi libpng libjpeg-turbo freetype libwebp gmp libtidy ImageMagick libc-client systemd-libs pcre2 expat brotli libuuid libtool-ltdl ca-certificates >/dev/null 2>&1 || yum -y install glibc readline bzip2-libs libffi libpng libjpeg-turbo freetype libwebp gmp libtidy ImageMagick libc-client systemd-libs pcre2 expat brotli libuuid libtool-ltdl ca-certificates
  tar -C / -xzf $O/php85-8.5.12-el7.tar.gz
  tar -C / -xzf $O/httpd24-2.4.69-el7.tar.gz
  id apache >/dev/null 2>&1 || useradd -r -s /sbin/nologin apache
else
  cd $O/rpms
  yum -y -q localinstall php85-el7-8.5.12-1.el7.x86_64.rpm php85-el7-libs-*.rpm
  echo "=== SOLO base+libs"; /usr/bin/php85 -v | head -1; /usr/bin/php85 -m | tr '\n' ' '; echo
  yum -y -q localinstall *.rpm
fi
P=/opt/php85/bin/php
$P -v | head -2
echo "--- php -m"; $P -m | tr '\n' ' '; echo
$P -m > /tmp/m.txt
for m in bcmath bz2 calendar ctype curl date dom exif fileinfo filter ftp gd gettext gmp iconv imagick imap intl json libxml mbstring mysqli mysqlnd openssl pcntl PDO pdo_mysql pdo_pgsql pdo_sqlite pgsql Phar posix readline session shmop SimpleXML soap sockets sodium SPL sqlite3 sysvmsg sysvsem sysvshm tidy tokenizer xml xmlreader xmlwriter xsl "Zend OPcache" zip zlib dbase; do grep -qix "$m" /tmp/m.txt || echo "LIPSA EXT: $m"; done
ldd /opt/php85/bin/php /opt/php85/sbin/php-fpm /opt/php85/lib/php/extensions/*/*.so /opt/httpd24/bin/httpd /opt/httpd24/modules/libphp85.so | grep "not found" || echo "ldd: nimic not found"
$P -r 'echo substr(file_get_contents("https://www.php.net/"),0,60),"\n"; var_dump(function_exists("dbase_open")); $i=new Imagick(); echo "imagick ", Imagick::getVersion()["versionString"],"\n"; echo "imap ", function_exists("imap_open")?"ok":"NO","\n";'
/opt/php85/sbin/php-fpm -t
# FPM pe TCP 9085
mkdir -p /tmp/www /var/log/php85-fpm; echo '<?php phpinfo();' > /tmp/www/info.php; chmod -R a+rX /tmp/www
sed 's|^listen = .*|listen = 127.0.0.1:9085|' /opt/php85/etc/php-fpm.d/www.conf > /tmp/www.conf
printf '[global]\nerror_log=/tmp/fpm.log\ndaemonize=yes\npid=/tmp/fpm.pid\ninclude=/tmp/www.conf\n' > /tmp/fpm.conf
/opt/php85/sbin/php-fpm -y /tmp/fpm.conf; sleep 2
yum -y -q install fcgi >/dev/null 2>&1 && echo "FPM_CGI: $(SCRIPT_FILENAME=/tmp/www/info.php REQUEST_METHOD=GET cgi-fcgi -bind -connect 127.0.0.1:9085 2>&1 | grep -c 'PHP Version')" || echo "(fcgi indisponibil; doar fpm -t + pornire)"
kill $(cat /tmp/fpm.pid) && echo "FPM stop OK"
# Apache 2.4.69 + mod_php
printf '%s' '<?php echo PHP_VERSION," ",php_sapi_name(); apache_note("userID","test"); echo apache_note("userID");' > /tmp/www/index.php
mkdir -p /tmp/hl; chmod 777 /tmp/hl
cat > /tmp/hl/httpd.conf <<'EOC'
ServerRoot "/opt/httpd24"
Listen 8085
PidFile /tmp/hl/httpd.pid
ErrorLog /tmp/hl/error_log
User apache
Group apache
ServerName localhost
LoadModule mpm_prefork_module modules/mod_mpm_prefork.so
LoadModule authz_core_module modules/mod_authz_core.so
LoadModule dir_module modules/mod_dir.so
LoadModule mime_module modules/mod_mime.so
LoadModule unixd_module modules/mod_unixd.so
LoadModule php_module modules/libphp85.so
TypesConfig conf/mime.types
DocumentRoot /tmp/www
<Directory /tmp/www>
Require all granted
</Directory>
<FilesMatch \.php$>
SetHandler application/x-httpd-php
</FilesMatch>
DirectoryIndex index.php
EOC
/opt/httpd24/bin/httpd -v | head -1
/opt/httpd24/bin/httpd -f /tmp/hl/httpd.conf; sleep 3
echo "APACHE_RESULT: $(curl -s localhost:8085/index.php)"
/opt/httpd24/bin/httpd -f /tmp/hl/httpd.conf -M 2>&1 | grep -E "php"
kill $(cat /tmp/hl/httpd.pid); true
ls /opt/httpd24/modules | grep -E "ssl|http2|proxy_http|proxy_connect|brotli" | tr "
" " "; echo
if [ "$MODE" = rpm ]; then
  for f in $O/rpms/*.rpm; do echo "## $(basename $f)"; rpm -qpR $f | grep -v rpmlib | sort -u | tr '\n' ';'; echo; echo "files: $(rpm -qpl $f | wc -l)"; done
fi
echo "TEST_${MODE}_OK"
EOT
podman run --rm -v ${PHP85_WORK}:/work docker.io/library/centos:7 bash /work/build/_inner_$MODE.sh $MODE
