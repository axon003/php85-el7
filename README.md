# php85-el7

PHP **8.5.12** and Apache httpd **2.4.69** RPMs for **CentOS / RHEL 7** (EOL, x86_64).

CentOS 7 is end-of-life and no distribution or third-party repository ships PHP 8.4 or newer for it. These packages are built in a clean `centos:7` container (devtoolset-11 / gcc 11) and are fully self-contained under `/opt`: modern dependencies (OpenSSL 3.5, curl, libxml2, ICU, libpq 17, SQLite, ...) are bundled with an RPATH, so nothing in the system libraries is replaced and the stock PHP/httpd of the host can stay in place.

## Install

```sh
curl -o /etc/yum.repos.d/php85-el7.repo https://axon003.github.io/php85-el7/php85-el7.repo
yum install php85-el7 php85-el7-fpm php85-el7-pgsql php85-el7-mbstring php85-el7-gd
php85 -v
```

Packages and repository metadata are signed. Key fingerprint:

```
4C5E 6EDC ECDA 8615 5F50  118E 970F BAE2 3B43 E584
```
(`RPM-GPG-KEY-php85-el7` in this repository; also served at the `gpgkey` URL of the .repo file.)

Direct downloads and checksums are on the [releases page](https://github.com/axon003/php85-el7/releases). The yum metadata lives on GitHub Pages and points to the release assets.

## Layout

| Item | Path |
|---|---|
| PHP prefix | `/opt/php85` (CLI: `/usr/bin/php85`, FPM: `/opt/php85/sbin/php-fpm`) |
| ini / extensions | `/opt/php85/etc/php.ini`, `/opt/php85/etc/php.d/` |
| FPM | systemd unit `php85-fpm`, socket `/run/php85-fpm/www.sock` |
| Apache | `/opt/httpd24` (unit `httpd24`), `mod_php` = `/opt/httpd24/modules/libphp85.so` |

`php85-el7-mod_php` is built against the bundled Apache 2.4.69 (`httpd24-el7`, prefork MPM). It cannot be loaded into the stock httpd 2.4.6 of CentOS 7. `/opt/httpd24/conf/extra/php85.conf.example` shows the `LoadModule` / `FilesMatch` lines. For the system httpd use PHP-FPM through `mod_proxy_fcgi` instead.

## Packages

Core: `php85-el7`, `-libs`, `-fpm`, `-devel`, `-mod_php`; Apache: `httpd24-el7`, `httpd24-el7-devel`.
Shared extensions: `bcmath gd gmp intl mbstring mysqlnd pdo pgsql process soap sodium tidy xml zip`.
PECL: `pecl-imap`, `pecl-imagick`, **`pecl-dbase`**.

OPcache is compiled into the PHP binary (as in PHP 8.5), so there is no separate opcache package.

**Bonus: dbase.** The PECL `dbase` extension (7.1.1) builds and runs on PHP 8.5, which is handy for reading and writing legacy DBF files. Install `php85-el7-pecl-dbase`.

## Bundled versions

OpenSSL 3.5.9, curl 8.23.0, libxml2 2.14.6, libxslt 1.1.43, ICU 79.1, PostgreSQL libpq 17.11, SQLite 3.54.1, oniguruma 6.9.10, libzip 1.12.1, libsodium 1.0.20, zlib 1.3.1; httpd: APR 1.7.6, APR-util 1.6.5, nghttp2 1.70.0, OpenSSL 3.5.9 (separate copy).

Runtime packages still needed from CentOS/EPEL are pulled in by yum (readline, bzip2-libs, libffi, libpng, libjpeg-turbo, freetype, libwebp, gmp, libtidy, libc-client, ImageMagick, pcre2, expat, brotli, ...). A few come from EPEL. Note that mirrorlist.centos.org is gone: point the base repos at `vault.centos.org` (7.9.2009) first.

## Limitations

- x86_64 EL7 only. Tested on a clean `centos:7` container; not tested on real RHEL 7, Oracle Linux or Amazon Linux 2.
- No HTTP/2 with prefork + `mod_php` (HTTP/2 needs the event MPM, i.e. FPM).
- `mod_md` is not built.
- SELinux has not been verified; no file contexts are provided for the `/opt` paths.
- Unofficial community build, no support. Security updates only by rebuilding; bundled libraries are pinned at the versions above.

## Rebuild

Scripts are in [`build/`](build/), RPM specs in [`specs/`](specs/), notes in [`docs/BUILD-NOTES.md`](docs/BUILD-NOTES.md).
Set `PHP85_WORK` to a work directory that contains `specs/`, `build/` (copies from this repository) and empty `src/`, `out/`, then run:
`build/dl85.sh` (download sources), `build/run_build85.sh` (container build), `build/pack85.sh` (tarballs and RPMs, run inside the container), `build/test85_runtime.sh tar|rpm`.
Requires podman and the `centos:7` image.

## License

Scripts and specs: MIT. Packaged software keeps its own licenses (PHP License 3.01, Apache-2.0, ...), see [LICENSE](LICENSE).
