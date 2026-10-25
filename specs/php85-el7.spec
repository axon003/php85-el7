%global debug_package %{nil}
%global __os_install_post %{nil}
%global __arch_install_post %{nil}
%global _unpackaged_files_terminate_build 0
%global _binaries_in_noarch_packages_terminate_build 0
%global pfx /opt/php85
%global extdir /opt/php85/lib/php/extensions/no-debug-non-zts-*

Name:           php85-el7
Version:        8.5.12
Release:        1%{?dist}
Summary:        PHP 8.5 (CLI+FPM+extensions) for EL7, self-contained in /opt/php85
License:        PHP-3.01 and OpenSSL and MIT and others
URL:            https://github.com/axon003
AutoReqProv:    no
Requires:       %{name}-libs = %{version}-%{release}
Requires:       glibc, readline, bzip2-libs, libffi, ca-certificates
Requires(pre):  shadow-utils

%description
PHP 8.5.12 built for CentOS/RHEL 7 (EOL), installed under /opt/php85 and fully
self-contained: newer dependencies live in /opt/php85/deps (php85-el7-libs):
OpenSSL 3.5.9, zlib 1.3.1, libxml2 2.14.6, libxslt 1.1.43, curl 8.23.0,
ICU 79.1, libpq (PostgreSQL 17.11), oniguruma 6.9.10, libzip 1.12.1,
libsodium 1.0.20. Extensions are shared modules split into sub-packages.
Base package: CLI, CGI, phar, pear and the "common" extensions (bz2 calendar
ctype curl exif fileinfo ftp gettext iconv phar tokenizer sockets readline ffi).
Symlink /usr/bin/php85 -> /opt/php85/bin/php.

%package libs
Summary:        Private libraries for PHP 8.5 in /opt/php85/deps
AutoReqProv:    no
Requires:       glibc, ca-certificates
%description libs
OpenSSL 3.5.9, zlib 1.3.1, libxml2 2.14.6, libxslt 1.1.43, curl 8.23.0,
ICU 79.1, libpq 17.11, oniguruma 6.9.10, libzip 1.12.1, libsodium 1.0.20,
installed privately under /opt/php85/deps (found through rpath).

%package fpm
Summary:        PHP 8.5 FastCGI Process Manager
AutoReqProv:    no
Requires:       %{name} = %{version}-%{release}
Requires:       systemd, systemd-libs
Requires(post): systemd
Requires(preun): systemd
Requires(postun): systemd
%description fpm
php-fpm for PHP 8.5 (/opt/php85/sbin/php-fpm) and a generic systemd unit php85-fpm.service.

%package devel
Summary:        Headers, phpize and php-config for PHP 8.5 (pecl builds)
AutoReqProv:    no
Requires:       %{name} = %{version}-%{release}
%description devel
Development files: include/, phpize, php-config, build/, deps headers, pkg-config files, static libs.

%package bcmath
Summary:        bcmath extension for PHP 8.5
AutoReqProv:    no
Requires:       %{name} = %{version}-%{release}
%description bcmath
bcmath extension.

%package gd
Summary:        gd extension for PHP 8.5
AutoReqProv:    no
Requires:       %{name} = %{version}-%{release}
Requires:       libpng, libjpeg-turbo, freetype, libwebp
%description gd
gd extension (jpeg, png, freetype, webp).

%package gmp
Summary:        gmp extension for PHP 8.5
AutoReqProv:    no
Requires:       %{name} = %{version}-%{release}
Requires:       gmp
%description gmp
gmp extension.

%package intl
Summary:        intl extension for PHP 8.5 (ICU 79.1 from -libs)
AutoReqProv:    no
Requires:       %{name} = %{version}-%{release}
%description intl
intl extension.

%package mbstring
Summary:        mbstring extension for PHP 8.5
AutoReqProv:    no
Requires:       %{name} = %{version}-%{release}
%description mbstring
mbstring extension (oniguruma 6.9.10 from -libs).

%package pdo
Summary:        pdo, pdo_sqlite and sqlite3 extensions for PHP 8.5
AutoReqProv:    no
Requires:       %{name} = %{version}-%{release}
%description pdo
pdo, pdo_sqlite, sqlite3.

%package mysqlnd
Summary:        mysqlnd, mysqli and pdo_mysql extensions for PHP 8.5
AutoReqProv:    no
Requires:       %{name} = %{version}-%{release}
Requires:       %{name}-pdo = %{version}-%{release}
%description mysqlnd
mysqlnd, mysqli, pdo_mysql.

%package pgsql
Summary:        pgsql and pdo_pgsql extensions for PHP 8.5 (libpq 17 from -libs)
AutoReqProv:    no
Requires:       %{name} = %{version}-%{release}
Requires:       %{name}-pdo = %{version}-%{release}
%description pgsql
pgsql, pdo_pgsql.

%package process
Summary:        posix, shmop, sysvmsg, sysvsem, sysvshm extensions for PHP 8.5
AutoReqProv:    no
Requires:       %{name} = %{version}-%{release}
%description process
posix, shmop, sysvmsg, sysvsem, sysvshm.

%package soap
Summary:        soap extension for PHP 8.5
AutoReqProv:    no
Requires:       %{name} = %{version}-%{release}
Requires:       %{name}-xml = %{version}-%{release}
%description soap
soap extension.

%package sodium
Summary:        sodium extension for PHP 8.5 (libsodium from -libs)
AutoReqProv:    no
Requires:       %{name} = %{version}-%{release}
%description sodium
sodium extension.

%package tidy
Summary:        tidy extension for PHP 8.5
AutoReqProv:    no
Requires:       %{name} = %{version}-%{release}
Requires:       libtidy
%description tidy
tidy extension.

%package xml
Summary:        dom, xml, xmlreader, xmlwriter, xsl, simplexml extensions for PHP 8.5
AutoReqProv:    no
Requires:       %{name} = %{version}-%{release}
%description xml
dom, xml, xmlreader, xmlwriter, xsl, simplexml (libxml2 2.14.6 / libxslt from -libs).

%package zip
Summary:        zip extension for PHP 8.5
AutoReqProv:    no
Requires:       %{name} = %{version}-%{release}
%description zip
zip extension (libzip 1.12.1 from -libs).

%package pecl-imap
Summary:        imap PECL extension for PHP 8.5
AutoReqProv:    no
Requires:       %{name} = %{version}-%{release}
Requires:       libc-client
%description pecl-imap
imap extension (UW c-client).

%package pecl-imagick
Summary:        imagick PECL extension for PHP 8.5
AutoReqProv:    no
Requires:       %{name} = %{version}-%{release}
Requires:       ImageMagick
%description pecl-imagick
imagick extension (ImageMagick 6 from EL7).

%package pecl-dbase
Summary:        dbase PECL extension for PHP 8.5
AutoReqProv:    no
Requires:       %{name} = %{version}-%{release}
%description pecl-dbase
dbase (dBase/DBF) extension, PECL dbase 7.1.1.

%package mod_php
Summary:        Apache httpd 2.4 module (mod_php) for PHP 8.5
AutoReqProv:    no
Requires:       %{name} = %{version}-%{release}
Requires:       httpd24-el7
%description mod_php
libphp85.so for httpd24-el7 (Apache 2.4.69 in /opt/httpd24, prefork). Not enabled automatically:
see /opt/httpd24/conf/extra/php85.conf.example.

%prep
%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}/opt %{buildroot}/usr/bin %{buildroot}/usr/lib/systemd/system %{buildroot}/var/log/php85-fpm
cp -a /opt/php85 %{buildroot}/opt/
mkdir -p %{buildroot}/opt/php85/var/session
ln -s /opt/php85/bin/php %{buildroot}/usr/bin/php85
mkdir -p %{buildroot}/opt/httpd24/modules %{buildroot}/opt/httpd24/conf/extra
cp -a /opt/httpd24/modules/libphp85.so %{buildroot}/opt/httpd24/modules/
cp -a /opt/httpd24/conf/extra/php85.conf.example %{buildroot}/opt/httpd24/conf/extra/
cat > %{buildroot}/usr/lib/systemd/system/php85-fpm.service <<'EOT'
[Unit]
Description=PHP 8.5 FastCGI Process Manager
After=network.target

[Service]
Type=simple
ExecStart=/opt/php85/sbin/php-fpm --nodaemonize -y /opt/php85/etc/php-fpm.conf
ExecReload=/bin/kill -USR2 $MAINPID
RuntimeDirectory=php85-fpm
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOT

%pre
getent group apache >/dev/null || groupadd -r apache
getent passwd apache >/dev/null || useradd -r -g apache -d /var/www -s /sbin/nologin apache
exit 0

%post fpm
%systemd_post php85-fpm.service
%preun fpm
%systemd_preun php85-fpm.service
%postun fpm
%systemd_postun_with_restart php85-fpm.service

# ---------------- files ----------------
%files
%defattr(-,root,root,-)
/opt/php85
/usr/bin/php85
%config(noreplace) /opt/php85/etc/php.ini
%exclude /opt/php85/deps
%exclude /opt/php85/include
%exclude /opt/php85/bin/phpize
%exclude /opt/php85/bin/php-config
%exclude /opt/php85/lib/php/build
%exclude /opt/php85/sbin
%exclude /opt/php85/etc/php-fpm.conf*
%exclude /opt/php85/etc/php-fpm.d
%exclude /opt/php85/php/php/fpm
%exclude /opt/php85/var/session
%exclude %{extdir}/bcmath.so
%exclude %{extdir}/gd.so
%exclude %{extdir}/gmp.so
%exclude %{extdir}/intl.so
%exclude %{extdir}/mbstring.so
%exclude %{extdir}/pdo.so
%exclude %{extdir}/pdo_sqlite.so
%exclude %{extdir}/sqlite3.so
%exclude %{extdir}/mysqlnd.so
%exclude %{extdir}/mysqli.so
%exclude %{extdir}/pdo_mysql.so
%exclude %{extdir}/pgsql.so
%exclude %{extdir}/pdo_pgsql.so
%exclude %{extdir}/posix.so
%exclude %{extdir}/shmop.so
%exclude %{extdir}/sysvmsg.so
%exclude %{extdir}/sysvsem.so
%exclude %{extdir}/sysvshm.so
%exclude %{extdir}/soap.so
%exclude %{extdir}/sodium.so
%exclude %{extdir}/tidy.so
%exclude %{extdir}/dom.so
%exclude %{extdir}/xml.so
%exclude %{extdir}/xmlreader.so
%exclude %{extdir}/xmlwriter.so
%exclude %{extdir}/xsl.so
%exclude %{extdir}/simplexml.so
%exclude %{extdir}/zip.so
%exclude %{extdir}/imap.so
%exclude %{extdir}/imagick.so
%exclude %{extdir}/dbase.so


%exclude /opt/php85/etc/php.d/*-dbase.ini
%exclude /opt/php85/etc/php.d/*-bcmath.ini
%exclude /opt/php85/etc/php.d/*-gd.ini
%exclude /opt/php85/etc/php.d/*-gmp.ini
%exclude /opt/php85/etc/php.d/*-intl.ini
%exclude /opt/php85/etc/php.d/*-mbstring.ini
%exclude /opt/php85/etc/php.d/*-pdo.ini
%exclude /opt/php85/etc/php.d/*-pdo_sqlite.ini
%exclude /opt/php85/etc/php.d/*-sqlite3.ini
%exclude /opt/php85/etc/php.d/*-mysqlnd.ini
%exclude /opt/php85/etc/php.d/*-mysqli.ini
%exclude /opt/php85/etc/php.d/*-pdo_mysql.ini
%exclude /opt/php85/etc/php.d/*-pgsql.ini
%exclude /opt/php85/etc/php.d/*-pdo_pgsql.ini
%exclude /opt/php85/etc/php.d/*-posix.ini
%exclude /opt/php85/etc/php.d/*-shmop.ini
%exclude /opt/php85/etc/php.d/*-sysvmsg.ini
%exclude /opt/php85/etc/php.d/*-sysvsem.ini
%exclude /opt/php85/etc/php.d/*-sysvshm.ini
%exclude /opt/php85/etc/php.d/*-soap.ini
%exclude /opt/php85/etc/php.d/*-sodium.ini
%exclude /opt/php85/etc/php.d/*-tidy.ini
%exclude /opt/php85/etc/php.d/*-dom.ini
%exclude /opt/php85/etc/php.d/*-xml.ini
%exclude /opt/php85/etc/php.d/*-xmlreader.ini
%exclude /opt/php85/etc/php.d/*-xmlwriter.ini
%exclude /opt/php85/etc/php.d/*-xsl.ini
%exclude /opt/php85/etc/php.d/*-simplexml.ini
%exclude /opt/php85/etc/php.d/*-zip.ini
%exclude /opt/php85/etc/php.d/*-imap.ini
%exclude /opt/php85/etc/php.d/*-imagick.ini

%files libs
%defattr(-,root,root,-)
/opt/php85/deps
%dir /opt/php85
%config(noreplace) /opt/php85/deps/ssl/openssl.cnf
%exclude /opt/php85/deps/include
%exclude /opt/php85/deps/lib/pkgconfig
%exclude /opt/php85/deps/lib/cmake
%exclude /opt/php85/deps/lib/*.la

%files fpm
%defattr(-,root,root,-)
/opt/php85/sbin/php-fpm
/opt/php85/sbin
/opt/php85/etc/php-fpm.conf.default
%config(noreplace) /opt/php85/etc/php-fpm.conf
/opt/php85/etc/php-fpm.d
%config(noreplace) /opt/php85/etc/php-fpm.d/www.conf
/opt/php85/php/php/fpm
/usr/lib/systemd/system/php85-fpm.service
%dir %attr(0770,apache,root) /var/log/php85-fpm
%dir %attr(0770,apache,apache) /opt/php85/var/session

%files devel
%defattr(-,root,root,-)
/opt/php85/include
/opt/php85/bin/phpize
/opt/php85/bin/php-config
/opt/php85/lib/php/build
/opt/php85/deps/include
/opt/php85/deps/lib/pkgconfig
/opt/php85/deps/lib/cmake
/opt/php85/deps/lib/*.la

%files bcmath
%{extdir}/bcmath.so
%config(noreplace) /opt/php85/etc/php.d/*-bcmath.ini
%files gd
%{extdir}/gd.so
%config(noreplace) /opt/php85/etc/php.d/*-gd.ini
%files gmp
%{extdir}/gmp.so
%config(noreplace) /opt/php85/etc/php.d/*-gmp.ini
%files intl
%{extdir}/intl.so
%config(noreplace) /opt/php85/etc/php.d/*-intl.ini
%files mbstring
%{extdir}/mbstring.so
%config(noreplace) /opt/php85/etc/php.d/*-mbstring.ini
%files pdo
%{extdir}/pdo.so
%{extdir}/pdo_sqlite.so
%{extdir}/sqlite3.so
%config(noreplace) /opt/php85/etc/php.d/*-pdo.ini
%config(noreplace) /opt/php85/etc/php.d/*-pdo_sqlite.ini
%config(noreplace) /opt/php85/etc/php.d/*-sqlite3.ini
%files mysqlnd
%{extdir}/mysqlnd.so
%{extdir}/mysqli.so
%{extdir}/pdo_mysql.so
%config(noreplace) /opt/php85/etc/php.d/*-mysqlnd.ini
%config(noreplace) /opt/php85/etc/php.d/*-mysqli.ini
%config(noreplace) /opt/php85/etc/php.d/*-pdo_mysql.ini
%files pgsql
%{extdir}/pgsql.so
%{extdir}/pdo_pgsql.so
%config(noreplace) /opt/php85/etc/php.d/*-pgsql.ini
%config(noreplace) /opt/php85/etc/php.d/*-pdo_pgsql.ini
%files process
%{extdir}/posix.so
%{extdir}/shmop.so
%{extdir}/sysvmsg.so
%{extdir}/sysvsem.so
%{extdir}/sysvshm.so
%config(noreplace) /opt/php85/etc/php.d/*-posix.ini
%config(noreplace) /opt/php85/etc/php.d/*-shmop.ini
%config(noreplace) /opt/php85/etc/php.d/*-sysvmsg.ini
%config(noreplace) /opt/php85/etc/php.d/*-sysvsem.ini
%config(noreplace) /opt/php85/etc/php.d/*-sysvshm.ini
%files soap
%{extdir}/soap.so
%config(noreplace) /opt/php85/etc/php.d/*-soap.ini
%files sodium
%{extdir}/sodium.so
%config(noreplace) /opt/php85/etc/php.d/*-sodium.ini
%files tidy
%{extdir}/tidy.so
%config(noreplace) /opt/php85/etc/php.d/*-tidy.ini
%files xml
%{extdir}/dom.so
%{extdir}/xml.so
%{extdir}/xmlreader.so
%{extdir}/xmlwriter.so
%{extdir}/xsl.so
%{extdir}/simplexml.so
%config(noreplace) /opt/php85/etc/php.d/*-dom.ini
%config(noreplace) /opt/php85/etc/php.d/*-xml.ini
%config(noreplace) /opt/php85/etc/php.d/*-xmlreader.ini
%config(noreplace) /opt/php85/etc/php.d/*-xmlwriter.ini
%config(noreplace) /opt/php85/etc/php.d/*-xsl.ini
%config(noreplace) /opt/php85/etc/php.d/*-simplexml.ini
%files zip
%{extdir}/zip.so
%config(noreplace) /opt/php85/etc/php.d/*-zip.ini
%files pecl-imap
%{extdir}/imap.so
%config(noreplace) /opt/php85/etc/php.d/*-imap.ini
%files pecl-imagick
%{extdir}/imagick.so
%config(noreplace) /opt/php85/etc/php.d/*-imagick.ini

%files pecl-dbase
%{extdir}/dbase.so
%config(noreplace) /opt/php85/etc/php.d/*-dbase.ini
%files mod_php
/opt/httpd24/modules/libphp85.so
/opt/httpd24/conf/extra/php85.conf.example

%changelog
* Sun Oct 25 2026 axon003 <axon003@users.noreply.github.com> - 8.5.12-1
- Initial modular build of PHP 8.5.12 for EL7 under /opt/php85
