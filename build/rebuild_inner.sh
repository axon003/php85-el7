#!/bin/bash
# runs inside centos:7: rebuild RPMs from the release tarballs
set -e
sed -i "s|^mirrorlist=|#mirrorlist=|; s|^#\?baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|" /etc/yum.repos.d/CentOS-*.repo
sed -i "s|\$releasever|7.9.2009|g" /etc/yum.repos.d/CentOS-*.repo
yum -y -q install rpm-build systemd file >/dev/null
id apache >/dev/null 2>&1 || useradd -r -s /sbin/nologin apache
tar -C / -xzf /work/out/php85-8.5.12-el7.tar.gz
tar -C / -xzf /work/out/httpd24-2.4.69-el7.tar.gz
T=/tmp/rpmbuild; mkdir -p $T/SPECS $T/SOURCES $T/BUILD $T/RPMS $T/SRPMS
for s in httpd24-el7 php85-el7; do
  cp /work/specs/$s.spec $T/SPECS/
  rpmbuild --define "_topdir $T" --define "dist .el7" -bb $T/SPECS/$s.spec > /work/out/rpmbuild_$s.log 2>&1 || { tail -30 /work/out/rpmbuild_$s.log; exit 1; }
done
mkdir -p /work/out/rpms2; find $T/RPMS -name "*.rpm" -exec cp {} /work/out/rpms2/ \;
