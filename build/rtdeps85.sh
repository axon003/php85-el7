#!/bin/bash
# rtdeps85.sh - in container: pachetele EL7 de care depind binarele (in afara /opt)
for f in /opt/php85/bin/php /opt/php85/sbin/php-fpm /opt/php85/lib/php/extensions/*/*.so /opt/httpd24/modules/libphp85.so /opt/httpd24/bin/httpd /opt/httpd24/modules/*.so; do
  echo "## $f" >&2
  ldd $f 2>/dev/null | grep "=>" | grep -v "/opt/" | awk '{print $3}'
done | sort -u | xargs rpm -qf --qf '%{NAME}\n' | sort -u
