#!/bin/bash
# pack85.sh - in container php85build, dupa build85.sh: strip httpd24, tarball-uri, RPM-uri
set -eEo pipefail
trap 'echo "FAIL la linia $LINENO: $BASH_COMMAND"' ERR
O=/work/out
yum -y -q install rpm-build systemd >/dev/null
if [ -L /opt/httpd24 ]; then rm /opt/httpd24; mv /work/opt_httpd24 /opt/httpd24; fi
find /opt/httpd24 -type f \( -name '*.so*' -o -path '*/bin/*' -o -path '*/sbin/*' \) -exec sh -c 'file "$1" | grep -q ELF && strip --strip-unneeded "$1" 2>/dev/null; true' _ {} \;
rm -rf /opt/httpd24/manual
cp /work/specs/php85.conf.example /opt/httpd24/conf/extra/php85.conf.example
cd /
tar -C / -czf $O/php85-8.5.12-el7.tar.gz opt/php85
tar -czf $O/httpd24-2.4.69-el7.tar.gz --transform 's,^\./,opt/httpd24/,' -C /opt/httpd24 .
(cd $O && md5sum php85-8.5.12-el7.tar.gz > php85-8.5.12-el7.tar.gz.md5 && md5sum httpd24-2.4.69-el7.tar.gz > httpd24-2.4.69-el7.tar.gz.md5)
T=/build/rpmbuild
rm -rf "${T:?}"; mkdir -p $T/SPECS $T/SOURCES $T/BUILD $T/RPMS $T/SRPMS
for s in httpd24-el7 php85-el7; do
  cp /work/specs/$s.spec $T/SPECS/
  rpmbuild --define "_topdir $T" --define "dist .el7" -bb $T/SPECS/$s.spec > $O/rpmbuild_$s.log 2>&1 || { tail -30 $O/rpmbuild_$s.log; exit 1; }
done
mkdir -p $O/rpms
find $T/RPMS -name '*.rpm' -exec cp {} $O/rpms/ \;
(cd $O/rpms && md5sum *.rpm > MD5SUMS)
ls -la $O/rpms $O/*.tar.gz
echo PACK_OK
