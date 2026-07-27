#!/bin/bash
# Detect changes in BrosTrend's upstream aic8800-dkms.deb so upstream fixes
# (e.g. security patches) are not missed. Compares the deb's version and
# payload checksums against the committed baseline in upstream/SHA256SUMS.
#
# Usage:
#   ./check-upstream.sh            # exit 1 + diff if upstream changed
#   ./check-upstream.sh --update   # regenerate the baseline after review
set -euo pipefail

url=https://linux.brostrend.com/aic8800-dkms.deb
repo=$(cd "$(dirname "$0")" && pwd)
baseline=$repo/upstream/SHA256SUMS

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

curl -fsSL "$url" -o "$work/upstream.deb"
cd "$work"
ar x upstream.deb
mkdir payload control
tar -xf data.tar.* -C payload
tar -xf control.tar.* -C control
{
    grep ^Version: control/control
    (cd payload && find . -type f -print0 | LC_ALL=C sort -z | xargs -0 sha256sum)
} > current

if [ "${1-}" = --update ]; then
    mkdir -p "$(dirname "$baseline")"
    cp current "$baseline"
    echo "baseline updated: $(grep ^Version: "$baseline")"
elif diff -u "$baseline" current; then
    echo "OK: upstream unchanged ($(grep ^Version: current))"
else
    echo "UPSTREAM CHANGED — review the diff above for security fixes," >&2
    echo "port anything relevant, then refresh with: $0 --update" >&2
    exit 1
fi
