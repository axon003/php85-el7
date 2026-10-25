#!/bin/bash
: "${PHP85_WORK:?set PHP85_WORK to the work directory}"
# rebuild_rpms.sh <workdir>: workdir must contain out/*.tar.gz and specs/*.spec; result in <workdir>/out/rpms2
set -e
W=${1:?workdir}
podman run --rm -v "$W":/work docker.io/library/centos:7 bash /work/build/rebuild_inner.sh
