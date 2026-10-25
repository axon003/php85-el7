%global debug_package %{nil}
%global __os_install_post %{nil}
%global __arch_install_post %{nil}
%global _unpackaged_files_terminate_build 0

Name:           httpd24-el7
Version:        2.4.69
Release:        1%{?dist}
Summary:        Apache httpd 2.4.69 for EL7, self-contained in /opt/httpd24
License:        ASL 2.0 and OpenSSL and MIT
URL:            https://github.com/axon003
AutoReqProv:    no
Requires:       glibc, pcre2, expat, brotli, libuuid, libtool-ltdl, systemd-libs, ca-certificates
Requires(pre):  shadow-utils
Requires(post): systemd
Requires(preun): systemd
Requires(postun): systemd

%description
Apache httpd 2.4.69 (prefork default, event/worker as shared MPMs) with mod_ssl,
mod_http2 (nghttp2 1.70.0), mod_proxy_*, mod_brotli, mod_rewrite, mod_remoteip...
Bundled in /opt/httpd24/lib: OpenSSL 3.5.9, APR 1.7.6, APR-util 1.6.5, nghttp2 1.70.0.
The system httpd 2.4.6 is untouched. Use together with php85-el7-mod_php.

%package devel
Summary:        apxs, headers and build files for httpd24
AutoReqProv:    no
Requires:       %{name} = %{version}-%{release}
%description devel
apxs, include/, build/ and pkg-config files for /opt/httpd24.

%prep
%build
%install
rm -rf %{buildroot}
mkdir -p %{buildroot}/opt %{buildroot}/usr/lib/systemd/system
cp -a /opt/httpd24 %{buildroot}/opt/
mkdir -p %{buildroot}/opt/httpd24/logs %{buildroot}/opt/httpd24/run
rm -f %{buildroot}/opt/httpd24/modules/libphp85.so %{buildroot}/opt/httpd24/conf/extra/php85.conf.example
rm -rf %{buildroot}/opt/httpd24/manual
cat > %{buildroot}/usr/lib/systemd/system/httpd24.service <<'EOT'
[Unit]
Description=Apache HTTP Server 2.4.69 (/opt/httpd24)
After=network.target

[Service]
Type=simple
ExecStart=/opt/httpd24/bin/httpd -DFOREGROUND
ExecReload=/opt/httpd24/bin/httpd -k graceful
KillSignal=SIGWINCH
KillMode=mixed
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOT

%pre
getent group apache >/dev/null || groupadd -r apache
getent passwd apache >/dev/null || useradd -r -g apache -d /var/www -s /sbin/nologin apache
exit 0
%post
%systemd_post httpd24.service
%preun
%systemd_preun httpd24.service
%postun
%systemd_postun_with_restart httpd24.service

%files
%defattr(-,root,root,-)
/opt/httpd24
/usr/lib/systemd/system/httpd24.service
%config(noreplace) /opt/httpd24/conf
%dir %attr(0750,root,apache) /opt/httpd24/logs
%dir /opt/httpd24/run
%exclude /opt/httpd24/include
%exclude /opt/httpd24/build
%exclude /opt/httpd24/bin/apxs
%exclude /opt/httpd24/bin/apr-1-config
%exclude /opt/httpd24/bin/apu-1-config
%exclude /opt/httpd24/lib/pkgconfig
%exclude /opt/httpd24/lib/*.a
%exclude /opt/httpd24/lib/*.la
%exclude /opt/httpd24/lib/*.exp

%files devel
%defattr(-,root,root,-)
/opt/httpd24/include
/opt/httpd24/build
/opt/httpd24/bin/apxs
/opt/httpd24/bin/apr-1-config
/opt/httpd24/bin/apu-1-config
/opt/httpd24/lib/pkgconfig
/opt/httpd24/lib/*.a
/opt/httpd24/lib/*.la
/opt/httpd24/lib/*.exp

%changelog
* Sun Oct 25 2026 axon003 <axon003@users.noreply.github.com> - 2.4.69-1
- Initial build for EL7 under /opt/httpd24
