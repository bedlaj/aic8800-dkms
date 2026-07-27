#!/bin/bash
# Detect new upstream aic8800 releases so upstream fixes (e.g. security
# patches) are not missed.
#
# Upstream is BrosTrend's driver repo, github.com/brostrend/linux.brostrend.com,
# served as-is at linux.brostrend.com via GitHub Pages. In that repo,
# `aic8800-dkms.deb` is a one-line text pointer naming the current versioned
# deb in the apt pool (pool/main/a/aic8800/aic8800-dkms_<version>_all.deb).
# We pin, in upstream/SHA256SUMS:
#   Release: the pool path the pointer names (= release identity)
#   Commit:  last upstream commit touching the pointer (their release commit)
#   Deb:     sha256 of the versioned deb itself
#   Version: from the deb's control file
#   plus sha256 of every payload file (driver source + firmware).
#
# Usage:
#   ./check-upstream.sh            # exit 1 + diff if upstream changed
#   ./check-upstream.sh --update   # regenerate the baseline after review
set -euo pipefail

gh_repo=brostrend/linux.brostrend.com
site=https://linux.brostrend.com
self=$(cd "$(dirname "$0")" && pwd)
baseline=$self/upstream/SHA256SUMS

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cd "$work"

release=$(curl -fsSL "https://raw.githubusercontent.com/$gh_repo/main/aic8800-dkms.deb")
case $release in
    pool/*aic8800*.deb) ;;
    *) echo "unexpected pointer content: $release" >&2; exit 2 ;;
esac
# Prefer gh (authenticated; unauthenticated api.github.com is rate-limited
# per IP, which bites on shared CI runners), fall back to curl + jq.
if command -v gh >/dev/null 2>&1; then
    commit=$(gh api "repos/$gh_repo/commits?path=aic8800-dkms.deb&per_page=1" \
        --jq '.[0].sha')
else
    commit=$(curl -fsSL "https://api.github.com/repos/$gh_repo/commits?path=aic8800-dkms.deb&per_page=1" \
        | jq -r '.[0].sha')
fi

curl -fsSL "$site/$release" -o upstream.deb
ar x upstream.deb
mkdir payload control
tar -xf data.tar.* -C payload
tar -xf control.tar.* -C control
{
    echo "Release: $release"
    echo "Commit: $commit"
    echo "Deb: $(sha256sum upstream.deb | cut -d' ' -f1)"
    grep ^Version: control/control
    (cd payload && find . -type f -print0 | LC_ALL=C sort -z | xargs -0 sha256sum)
} > current

if [ "${1-}" = --update ]; then
    mkdir -p "$(dirname "$baseline")"
    cp current "$baseline"
    echo "baseline updated: $release ($commit)"
elif diff -u "$baseline" current; then
    echo "OK: upstream unchanged ($release)"
else
    echo "UPSTREAM CHANGED — review the diff above for security fixes:" >&2
    echo "  https://github.com/$gh_repo/commits/main/aic8800-dkms.deb" >&2
    echo "port anything relevant, then refresh with: $0 --update" >&2
    exit 1
fi
