#!/bin/bash
# build85.sh - ruleaza IN container centos:7: PHP 8.5.12 + dependinte in /opt/php85 (relocabil, rpath).
# Montari: /work = ${PHP85_WORK} (src/, out/, stamps/), /opt/php85 = ${PHP85_WORK}/opt
# Reluabil: fiecare pas are stamp in /work/stamps; sterge stamp-ul ca sa refaci pasul.
set -eEo pipefail
trap 'echo "FAIL la linia $LINENO: $BASH_COMMAND"' ERR
ST=/work/stamps; SRC=/work/src; B=/build; D=/opt/php85/deps; P=/opt/php85
mkdir -p $ST $B $D /work/out
step() { n=$1; shift; if [ -f $ST/$n ]; then echo "SKIP $n"; return 0; fi; echo "=== $n $(date +%T)"; "$@"; touch $ST/$n; }

yum_base() {
  sed -i 's|^mirrorlist=|#mirrorlist=|; s|^#\?baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|' /etc/yum.repos.d/CentOS-*.repo
  sed -i 's|\$releasever|7.9.2009|g' /etc/yum.repos.d/CentOS-*.repo
  yum -y -q install epel-release yum-utils
  sed -i 's|^metalink=.*|#&|; s|^#\?baseurl=.*|baseurl=https://archives.fedoraproject.org/pub/archive/epel/7/$basearch/|' /etc/yum.repos.d/epel.repo
  cat > /etc/yum.repos.d/sclo-vault.repo <<'EOT'
[sclo-rh-vault]
name=SCLo rh (vault)
baseurl=http://vault.centos.org/7.9.2009/sclo/x86_64/rh/
gpgcheck=0
enabled=1
EOT
  yum -y -q install devtoolset-11-gcc devtoolset-11-gcc-c++ devtoolset-11-binutils devtoolset-11-libstdc++-devel
  yum -y -q install make cmake3 xz bzip2 patch autoconf automake libtool bison re2c pkgconfig perl-core which file flex diffutils tar gzip \
    libpng-devel libjpeg-turbo-devel freetype-devel libwebp-devel bzip2-devel gmp-devel readline-devel libtidy-devel \
    libffi-devel systemd-devel libtool-ltdl-devel gettext
  ln -sf /usr/bin/cmake3 /usr/local/bin/cmake
  id apache >/dev/null 2>&1 || useradd -r -s /sbin/nologin apache
}
step yum_base yum_base
source /opt/rh/devtoolset-11/enable
echo "gcc: $(gcc --version | head -1)"
export PATH=$D/bin:/usr/local/bin:$PATH
export PKG_CONFIG_PATH=$D/lib/pkgconfig:$D/lib64/pkgconfig
export LD_LIBRARY_PATH=$D/lib
export CPPFLAGS="-I$D/include"
export LDFLAGS="-L$D/lib -Wl,--disable-new-dtags -Wl,-rpath,$D/lib"
export CFLAGS="-O2 -g0" CXXFLAGS="-O2 -g0"
J=-j4

unpack() { # <arhiva> <dir rezultat in $B>
  local d="${B:?}/${2:?}"
  rm -rf "${d:?}"; mkdir -p "${B:?}"; tar -C "$B" -xf "$SRC/$1"; test -d "$d"
}
b_zlib()   { unpack zlib-1.3.1.tar.gz zlib-1.3.1; cd $B/zlib-1.3.1; ./configure --prefix=$D; make $J; make install; }
b_openssl(){ unpack openssl-3.5.9.tar.gz openssl-3.5.9; cd $B/openssl-3.5.9; ./Configure linux-x86_64 --prefix=$D --openssldir=$D/ssl --libdir=lib shared no-tests; make $J; make install_sw install_ssldirs; test -f $D/ssl/openssl.cnf; }
b_libxml2(){ unpack libxml2-2.14.6.tar.xz libxml2-2.14.6; cd $B/libxml2-2.14.6; ./configure --prefix=$D --without-python --with-zlib=$D --without-lzma --without-icu --with-legacy --disable-static; make $J; make install; }
b_libxslt(){ unpack libxslt-1.1.43.tar.xz libxslt-1.1.43; cd $B/libxslt-1.1.43; ./configure --prefix=$D --with-libxml-prefix=$D --without-python --without-crypto --disable-static; make $J; make install; }
b_curl()   { unpack curl-8.23.0.tar.gz curl-8.23.0; cd $B/curl-8.23.0; ./configure --prefix=$D --with-openssl=$D --with-zlib=$D --without-libpsl --disable-ldap --disable-ldaps --without-libidn2 --without-nghttp2 --without-brotli --without-zstd --with-ca-bundle=/etc/pki/tls/certs/ca-bundle.crt --disable-static; make $J; make install; }
b_icu()    { unpack icu4c-79.1-sources.tgz icu; cd $B/icu/source; ./runConfigureICU Linux --prefix=$D --disable-tests --disable-samples --disable-static --enable-shared; make $J; make install; }
b_pg()     { unpack postgresql-17.11.tar.bz2 postgresql-17.11; cd $B/postgresql-17.11; ./configure --prefix=$D --with-openssl --without-readline --without-zlib --without-icu
             make -C src/backend generated-headers; make -C src/common $J; make -C src/port $J; make -C src/interfaces/libpq $J
             make -C src/interfaces/libpq install; make -C src/include install; make -C src/bin/pg_config install; make -C src/common install; make -C src/port install; test -x $D/bin/pg_config; }
b_onig()   { unpack onig-6.9.10.tar.gz onig-6.9.10; cd $B/onig-6.9.10; ./configure --prefix=$D --disable-static; make $J; make install; }
b_libzip() { unpack libzip-1.12.1.tar.gz libzip-1.12.1; mkdir -p $B/libzip-1.12.1/bld; cd $B/libzip-1.12.1/bld
             cmake -DCMAKE_INSTALL_PREFIX=$D -DCMAKE_INSTALL_LIBDIR=lib -DZLIB_ROOT=$D -DOPENSSL_ROOT_DIR=$D -DENABLE_GNUTLS=OFF -DENABLE_MBEDTLS=OFF -DENABLE_LZMA=OFF -DENABLE_ZSTD=OFF \
               -DBUILD_TOOLS=OFF -DBUILD_REGRESS=OFF -DBUILD_EXAMPLES=OFF -DBUILD_DOC=OFF -DBUILD_SHARED_LIBS=ON -DCMAKE_SHARED_LINKER_FLAGS="$LDFLAGS" ..
             make $J; make install; }
b_sodium() { unpack libsodium-1.0.20.tar.gz libsodium-1.0.20; cd $B/libsodium-1.0.20; ./configure --prefix=$D --disable-static; make $J; make install; }
b_sqlite() { unpack sqlite-autoconf-3540100.tar.gz sqlite-autoconf-3540100; cd $B/sqlite-autoconf-3540100; ./configure --prefix=$D --disable-static; make $J; make install; }
step sqlite b_sqlite
step zlib b_zlib; step openssl b_openssl; step libxml2 b_libxml2; step libxslt b_libxslt; step curl b_curl
step icu b_icu; step pg b_pg; step onig b_onig; step libzip b_libzip; step sodium b_sodium

b_php() {
  export CFLAGS="-O2 -g0 -D__NO_STRING_INLINES"  # glibc 2.17: macro strncmp rompe ZEND_STRL in ext/ffi
  unpack php-8.5.12.tar.xz php-8.5.12; cd $B/php-8.5.12
  ./configure --prefix=$P --with-config-file-path=$P/etc --with-config-file-scan-dir=$P/etc/php.d \
   --enable-fpm --with-fpm-user=apache --with-fpm-group=apache --with-fpm-systemd \
   --with-openssl --with-zlib --with-libxml --enable-filter --enable-session --enable-pcntl --with-pear --with-libdir=lib64 \
   --with-curl=shared --with-xsl=shared --with-pgsql=shared,$D --with-pdo-pgsql=shared,$D --with-mysqli=shared,mysqlnd --enable-mysqlnd=shared \
   --with-pdo-mysql=shared,mysqlnd --enable-pdo=shared --with-pdo-sqlite=shared --with-sqlite3=shared --enable-mbstring=shared --with-zip=shared \
   --enable-gd=shared --with-jpeg --with-freetype --with-webp --enable-intl=shared --enable-soap=shared --with-tidy=shared --with-gmp=shared \
   --with-bz2=shared --with-sodium=shared --enable-bcmath=shared --enable-calendar=shared --enable-exif=shared --enable-sockets=shared \
   --enable-sysvmsg=shared --enable-sysvsem=shared --enable-sysvshm=shared --enable-shmop=shared --with-gettext=shared --with-readline=shared \
   --with-iconv=shared --with-ffi=shared --enable-ctype=shared --enable-fileinfo=shared --enable-tokenizer=shared --enable-xml=shared \
   --enable-xmlreader=shared --enable-xmlwriter=shared --enable-simplexml=shared --enable-dom=shared --enable-phar=shared --enable-posix=shared \
   --enable-ftp=shared --with-apxs2=/opt/httpd24/bin/apxs > /work/out/configure.log 2>&1 || { tail -30 /work/out/configure.log; exit 1; }
  tail -15 /work/out/configure.log
  make $J
  make install
  mv /opt/httpd24/modules/libphp.so /opt/httpd24/modules/libphp85.so; sed -i "/php_module/d" /opt/httpd24/conf/httpd.conf; mkdir -p /opt/httpd24/conf/extra
}
H=/opt/httpd24; S_PKG=$PKG_CONFIG_PATH; S_LD=$LD_LIBRARY_PATH; S_CPP=$CPPFLAGS; S_LDF=$LDFLAGS; S_PATH=$PATH
henv() { export PKG_CONFIG_PATH=$H/lib/pkgconfig LD_LIBRARY_PATH=$H/lib CPPFLAGS="-I$H/include" LDFLAGS="-L$H/lib -Wl,--disable-new-dtags -Wl,-rpath,$H/lib" PATH=$H/bin:$PATH; }
b_h24pre() { LD_LIBRARY_PATH= yum -y -q install pcre2-devel expat-devel brotli-devel; mkdir -p /work/opt_httpd24; [ -e $H ] || ln -s /work/opt_httpd24 $H; }
b_h24ssl() { henv; unpack openssl-3.5.9.tar.gz openssl-3.5.9; cd $B/openssl-3.5.9; ./Configure linux-x86_64 --prefix=$H --openssldir=$H/ssl --libdir=lib shared no-tests; make $J; make install_sw install_ssldirs; test -f $H/ssl/openssl.cnf; }
b_h24apr() { henv; unpack apr-1.7.6.tar.bz2 apr-1.7.6; cd $B/apr-1.7.6; ./configure --prefix=$H; make $J; make install; }
b_h24apu() { henv; unpack apr-util-1.6.5.tar.bz2 apr-util-1.6.5; cd $B/apr-util-1.6.5; ./configure --prefix=$H --with-apr=$H --with-openssl=$H --with-crypto --with-expat=/usr; make $J; make install; }
b_h24ng()  { henv; unpack nghttp2-1.70.0.tar.xz nghttp2-1.70.0; cd $B/nghttp2-1.70.0; ./configure --prefix=$H --enable-lib-only --disable-static; make $J; make install; }
b_h24httpd() { henv; unpack httpd-2.4.69.tar.bz2 httpd-2.4.69; cd $B/httpd-2.4.69
  ./configure --prefix=$H --with-apr=$H/bin/apr-1-config --with-apr-util=$H/bin/apu-1-config --with-ssl=$H --with-nghttp2=$H --with-pcre=/usr/bin/pcre2-config \
   --enable-mods-shared=reallyall --enable-mpms-shared=all --enable-ssl --enable-http2 --enable-proxy --enable-proxy-http --enable-proxy-fcgi --enable-proxy-wstunnel \
   --enable-proxy-balancer --enable-rewrite --enable-headers --enable-deflate --enable-brotli --with-brotli=/usr --enable-expires --enable-remoteip --enable-systemd \
   --with-mpm=prefork --sysconfdir=$H/conf --localstatedir=$H/var > /work/out/httpd_configure.log 2>&1 || { tail -30 /work/out/httpd_configure.log; exit 1; }
  make $J; make install
  sed -i -E 's|^LoadModule mpm_event_module|#LoadModule mpm_event_module|; s|^#LoadModule mpm_prefork_module|LoadModule mpm_prefork_module|; s|^Listen 80$|Listen 80|; s|^User daemon|User apache|; s|^Group daemon|Group apache|' $H/conf/httpd.conf
  grep -E "^LoadModule mpm|^User|^Group" $H/conf/httpd.conf; $H/bin/httpd -v; $H/bin/httpd -M 2>&1 | grep -E "ssl|http2|proxy_http|proxy_connect|brotli|md_|systemd" || true; }
step h24pre b_h24pre; step h24ssl b_h24ssl; step h24apr b_h24apr; step h24apu b_h24apu; step h24ng b_h24ng; step h24httpd b_h24httpd
PKG_CONFIG_PATH=$S_PKG; LD_LIBRARY_PATH=$S_LD; CPPFLAGS=$S_CPP; LDFLAGS=$S_LDF; PATH=$S_PATH; export PKG_CONFIG_PATH LD_LIBRARY_PATH CPPFLAGS LDFLAGS PATH
step php b_php

b_config() {
  mkdir -p $P/etc/php.d $P/etc/php-fpm.d
  cp $B/php-8.5.12/php.ini-production $P/etc/php.ini
  sed -i 's|^;\?openssl.cafile=.*|openssl.cafile=/etc/pki/tls/certs/ca-bundle.crt|; s|^;\?curl.cainfo =.*|curl.cainfo = /etc/pki/tls/certs/ca-bundle.crt|' $P/etc/php.ini
  grep -E '^(openssl.cafile|curl.cainfo)' $P/etc/php.ini
  ED=$(ls -d $P/lib/php/extensions/no-debug-non-zts-*); echo "extdir=$ED"; ls $ED
  rm -f $P/etc/php.d/*.ini
  [ -f $ED/opcache.so ] && echo 'zend_extension=opcache' > $P/etc/php.d/10-opcache.ini
  for so in $ED/*.so; do e=$(basename $so .so); case $e in opcache|imap|imagick) continue;; esac
    case $e in mysqlnd|pdo|dom|xml) pr=20;; mysqli|pdo_mysql|pdo_pgsql|pdo_sqlite|xmlreader|xmlwriter|xsl|simplexml) pr=30;; *) pr=20;; esac
    echo "extension=$e" > $P/etc/php.d/$pr-$e.ini
  done
  ls $P/etc/php.d
  cp $P/etc/php-fpm.conf.default $P/etc/php-fpm.conf
  cp $P/etc/php-fpm.d/www.conf.default $P/etc/php-fpm.d/www.conf
  sed -i -E 's|^;?listen = .*|listen = /run/php85-fpm/www.sock|; s|^;?listen.owner = .*|listen.owner = apache|; s|^;?listen.group = .*|listen.group = apache|; s|^;?listen.mode = .*|listen.mode = 0660|; s|^user = .*|user = apache|; s|^group = .*|group = apache|' $P/etc/php-fpm.d/www.conf
  grep -E '^(listen|user|group)' $P/etc/php-fpm.d/www.conf
}
step config b_config

b_pecl() {
  LD_LIBRARY_PATH= yum -y -q install ImageMagick-devel libc-client-devel krb5-devel
  export PATH=$P/bin:$PATH
  for e in imap imagick; do
    mkdir -p "${B:?}/pecl_$e"; tar -C "$B/pecl_$e" -xzf $SRC/$e.tgz
  done
  cd $B/pecl_imap/imap-*; phpize; ./configure --with-php-config=$P/bin/php-config --with-imap=/usr --with-imap-ssl=/usr --with-libdir=lib64 --with-kerberos=/usr; make $J; make install
  echo 'extension=imap.so' > $P/etc/php.d/40-imap.ini
  cd $B/pecl_imagick/imagick-*; phpize; ./configure --with-php-config=$P/bin/php-config; make $J; make install
  echo 'extension=imagick.so' > $P/etc/php.d/40-imagick.ini
  mkdir -p "${B:?}/pecl_dbase"; tar -C "$B/pecl_dbase" -xzf $SRC/dbase.tgz
  cd $B/pecl_dbase/dbase-*; phpize; ./configure --with-php-config=$P/bin/php-config; make $J; make install
  echo 'extension=dbase' > $P/etc/php.d/40-dbase.ini
}
step pecl b_pecl

b_strip() {
  find $P -name '*.a' -path '*deps*' -delete
  rm -rf "${D:?}/share/man" "${D:?}/share/doc" "${D:?}/share/info"
  find $P \( -name '*.so*' -o -path '*/bin/*' -o -path '*/sbin/*' \) -type f -exec sh -c 'file "$1" | grep -q ELF && strip --strip-unneeded "$1" 2>/dev/null' _ {} \; || true
}
step strip b_strip

echo "=== TESTE $(date +%T)"
export PATH=$P/bin:$P/sbin:$PATH
unset LD_LIBRARY_PATH
php -v | head -2
php -m > /work/out/php_m.txt
for m in bcmath bz2 calendar ctype curl date dom exif fileinfo filter ftp gd gettext gmp iconv imagick imap intl json libxml mbstring mysqli mysqlnd openssl pcntl PDO pdo_mysql pdo_pgsql pdo_sqlite pgsql Phar posix readline session shmop SimpleXML soap sockets sodium SPL sqlite3 sysvmsg sysvsem sysvshm tidy tokenizer xml xmlreader xmlwriter xsl "Zend OPcache" zip zlib; do grep -qix "$m" /work/out/php_m.txt || echo "LIPSA EXT: $m"; done
echo "--- ldd"
ldd $P/bin/php $P/sbin/php-fpm $P/lib/php/extensions/*/*.so | grep -E "not found" || echo "nimic not found"
ldd $P/bin/php | grep -E "/opt/php85"
php -r 'var_dump(OPENSSL_VERSION_TEXT, curl_version()["version"], LIBXML_DOTTED_VERSION, INTL_ICU_VERSION, PGSQL_LIBPQ_VERSION);'
php -r 'echo substr(file_get_contents("https://www.php.net/"),0,200),"\n";'
php -i | grep -E "^(session.upload_progress.enabled|max_multipart_body_parts)" || echo "WARN: ini lipsa"
php-fpm -t
php -r 'var_dump(function_exists("dbase_open")); new PDO("sqlite::memory:"); echo "pdo ok
";'
echo "--- mod_php"
cp /work/specs/php85.conf.example /opt/httpd24/conf/extra/php85.conf.example
ldd /opt/httpd24/modules/libphp85.so | grep -E "not found|/opt/" || true
mkdir -p /tmp/www /tmp/hl; printf "%s" '<?php echo PHP_VERSION," ",php_sapi_name(); apache_note("userID","test"); echo apache_note("userID");' > /tmp/www/index.php
cat > /tmp/hl/httpd.conf <<'EOT'
ServerRoot "/opt/httpd24"
Listen 8085
PidFile /tmp/hl/httpd.pid
ErrorLog /tmp/hl/error_log
User apache
Group apache
ServerName localhost
LoadModule mpm_prefork_module /opt/httpd24/modules/mod_mpm_prefork.so
LoadModule authz_core_module /opt/httpd24/modules/mod_authz_core.so
LoadModule dir_module /opt/httpd24/modules/mod_dir.so
LoadModule mime_module /opt/httpd24/modules/mod_mime.so
LoadModule unixd_module /opt/httpd24/modules/mod_unixd.so
LoadModule php_module /opt/httpd24/modules/libphp85.so
TypesConfig /opt/httpd24/conf/mime.types
DocumentRoot /tmp/www
<Directory /tmp/www>
Require all granted
</Directory>
<FilesMatch \.php$>
SetHandler application/x-httpd-php
</FilesMatch>
DirectoryIndex index.php
EOT
chmod -R a+rX /tmp/www /tmp/hl; chmod 777 /tmp/hl
/opt/httpd24/bin/httpd -f /tmp/hl/httpd.conf; sleep 3
echo "APACHE_RESULT: $(curl -s localhost:8085/index.php)"
kill $(cat /tmp/hl/httpd.pid) || true
/opt/httpd24/bin/httpd -f /tmp/hl/httpd.conf -M 2>&1 | grep -E "php" ; /opt/httpd24/bin/httpd -M 2>&1 | grep -E "ssl|http2|proxy|brotli"
ldd /opt/httpd24/bin/httpd /opt/httpd24/modules/libphp85.so | grep -E "not found|/opt/" || true ; true
echo "TESTE_OK"
