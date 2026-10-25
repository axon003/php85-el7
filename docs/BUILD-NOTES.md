# Build notes (PHP 8.5.12 + Apache 2.4.69 on EL7)

Build in a `centos:7` container (vault.centos.org 7.9.2009, EPEL archive, devtoolset-11 = gcc 11.2). About 2 h wall-clock including troubleshooting; the actual compile ~45 min.

Scripts: `dl85.sh` (download sources, sha256 checked) -> `run_build85.sh` (container + `build85.sh`, resumable through stamp files) -> `pack85.sh` (strip, tarballs, RPMs) -> `test85_runtime.sh tar|rpm` (clean centos:7). `rtdeps85.sh` lists system packages needed according to `ldd`. `rebuild_rpms.sh` rebuilds only the RPMs from the two tarballs.

## Deviations and problems solved
1. Extensions are SHARED `.so`. Static: core date filter hash json libxml openssl pcre random reflection session spl standard zlib + pcntl. OPcache is built in (no `opcache.so`). ini files: `20-*` base, `30-` mysqli/pdo_*/xmlreader/xmlwriter/xsl/simplexml, `40-` imap imagick dbase.
2. libxslt 1.1.45 needs libxml2 >= 2.15.1, so libxslt 1.1.43 with libxml2 2.14.6 is used (libxml2 built `--with-legacy` so the system ImageMagick keeps working).
3. zlib 1.3.1 comes from GitHub (madler/zlib); ICU 79.1 has a different tarball name (`icu4c-79.1-sources.tgz`).
4. The system SQLite 3.7.17 is too old for pdo_sqlite in 8.5, so SQLite 3.54.1 is bundled in `/opt/php85/deps`.
5. glibc 2.17 + gcc 11: the `strncmp` macro from string2.h breaks `ZEND_STRL` in ext/ffi, so PHP is compiled with `CFLAGS=-D__NO_STRING_INLINES`.
6. `LD_LIBRARY_PATH=/opt/*/lib` during the build breaks yum (pycurl); yum is run with an empty `LD_LIBRARY_PATH`.
7. pecl imap: EL7 libc-client needs `--with-libdir=lib64 --with-kerberos=/usr` and `krb5-devel`. libssl.so.10 (c-client) and libssl.so.3 (PHP) coexist.
8. `mod_md` is not built (needs jansson and libcurl-devel). Built: mod_ssl, mod_http2, mod_brotli, mod_proxy_http/connect/wstunnel/balancer/fcgi, mod_rewrite, mod_remoteip, mod_systemd. `--logfiledir/--runtimedir` do not exist in httpd 2.4.69 configure: logs go to `/opt/httpd24/logs`. MPMs are shared; httpd.conf activates prefork; `User/Group apache`.
9. `cp -a` on a symlinked /opt/httpd24 copied the link; use a real directory before rpmbuild.
10. `--with-fpm-systemd` works (systemd-devel 219).

## Tests
Clean centos:7 (tarball with runtime packages, and RPMs via `yum localinstall`): `php -v` 8.5.12; `php -m` complete; `ldd` shows no "not found"; HTTPS `file_get_contents` OK; `dbase_open` exists; `PDO sqlite::memory:` OK; Imagick works; `php-fpm -t` OK and FPM answers phpinfo through cgi-fcgi; httpd24 with mod_php reports 8.5.12. `max_multipart_body_parts` and `session.upload_progress.enabled` are present (CVE-2026-109618 fix included).

## Requires per package
- httpd24-el7: glibc pcre2 expat brotli libuuid libtool-ltdl systemd-libs ca-certificates (+ shadow-utils, systemd)
- php85-el7: php85-el7-libs = V-R, glibc, readline, bzip2-libs, libffi, ca-certificates; libs: glibc ca-certificates
- fpm: php85-el7, systemd, systemd-libs; gd: libpng libjpeg-turbo freetype libwebp; gmp: gmp; tidy: libtidy; pecl-imap: libc-client; pecl-imagick: ImageMagick; mod_php: httpd24-el7
- mysqlnd, pgsql: php85-el7-pdo; soap: php85-el7-xml; others: php85-el7 = V-R. `-devel`: phpize, php-config, headers, pkgconfig.
- All packages use `AutoReqProv: no`.

## Sizes
php85 installed ~157 MB (ICU data ~30 MB); tarball 46 MB; RPMs 46 MB total.
