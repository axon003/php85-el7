#!/bin/bash
: "${PHP85_WORK:?set PHP85_WORK to the work directory}"
# run on the build host: descarca sursele in ${PHP85_WORK}/src
set -o pipefail
cd ${PHP85_WORK}/src || exit 1
g() { f=$(basename "$1"); [ -s "$f" ] || curl -fsSL --retry 3 -o "$f" "$1" || { echo "FAIL: download $1"; exit 1; }; echo "ok $f"; }
g https://github.com/madler/zlib/releases/download/v1.3.1/zlib-1.3.1.tar.gz
g https://github.com/openssl/openssl/releases/download/openssl-3.5.9/openssl-3.5.9.tar.gz
g https://curl.se/download/curl-8.23.0.tar.gz
g https://github.com/unicode-org/icu/releases/download/release-79.1/icu4c-79.1-sources.tgz
g https://ftp.postgresql.org/pub/source/v17.11/postgresql-17.11.tar.bz2
g https://github.com/kkos/oniguruma/releases/download/v6.9.10/onig-6.9.10.tar.gz
g https://libzip.org/download/libzip-1.12.1.tar.gz
g https://download.libsodium.org/libsodium/releases/libsodium-1.0.20.tar.gz
g https://www.php.net/distributions/php-8.5.12.tar.xz
for d in 2.14 ; do
 x=$(curl -fsSL https://download.gnome.org/sources/libxml2/$d/ | grep -o 'libxml2-[0-9.]*\.tar\.xz' | sort -uV | tail -1); echo "libxml2 $x"; g https://download.gnome.org/sources/libxml2/$d/$x
done
x=$(curl -fsSL https://download.gnome.org/sources/libxslt/1.1/ | grep -o 'libxslt-[0-9.]*\.tar\.xz' | sort -uV | tail -1); echo "libxslt $x"; g https://download.gnome.org/sources/libxslt/1.1/$x
echo "a1dc... check php sha"; echo "08bc2eba2a588654ade1357174aa646b761556c862dda0678345ee29ed481209  php-8.5.12.tar.xz" | sha256sum -c - || { echo "FAIL: php sha"; exit 1; }
ls -la
g2() { [ -s "$2" ] || curl -fsSL --retry 3 -o "$2" "$1" || { echo "FAIL: download $1"; exit 1; }; echo "ok $2"; }
cd ${PHP85_WORK}/src
g2 https://pecl.php.net/get/imap imap.tgz
g2 https://pecl.php.net/get/imagick imagick.tgz
g2 https://pecl.php.net/get/dbase dbase.tgz
g2 https://sqlite.org/2026/sqlite-autoconf-3540100.tar.gz sqlite-autoconf-3540100.tar.gz
