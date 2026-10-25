#!/bin/bash
: "${PHP85_WORK:?set PHP85_WORK to the work directory}"
# run_build85.sh - on the build host: porneste (sau reutilizeaza) containerul php85build si ruleaza build85.sh
set -o pipefail
mkdir -p ${PHP85_WORK}/opt ${PHP85_WORK}/stamps ${PHP85_WORK}/out
if ! podman container exists php85build; then
  podman run -d --name php85build -v ${PHP85_WORK}:/work -v ${PHP85_WORK}/opt:/opt/php85 docker.io/library/centos:7 sleep infinity || { echo "FAIL: podman run"; exit 1; }
fi
podman exec php85build bash /work/build/build85.sh
