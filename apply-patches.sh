#!/usr/bin/env bash
# Apply the ruan platform patches to the synced source tree.
#
# The device tree is checked out at device/xiaomi/ruan; each patch under
# patches/<repo>/ targets a platform repo at <repo>. Run this after `repo sync`
# and before building.
set -u

DEVICE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Walk up to the source tree root (the directory that holds .repo).
TOP="$DEVICE_DIR"
while [ "$TOP" != "/" ] && [ ! -d "$TOP/.repo" ]; do
    TOP="$(dirname "$TOP")"
done

if [ ! -d "$TOP/.repo" ]; then
    echo "error: could not find the Android source root above $DEVICE_DIR" >&2
    exit 1
fi

for patch in $(find "$DEVICE_DIR/patches" -name '*.patch' | sort); do
    repo="$(echo "$patch" | sed -e "s|$DEVICE_DIR/patches/||" -e 's|/[^/]*\.patch$||')"
    target="$TOP/$repo"
    if [ ! -d "$target" ]; then
        echo "skip   $repo (not in the tree)"
        continue
    fi
    if git -C "$target" apply --reverse --check "$patch" 2>/dev/null; then
        echo "skip   $repo/$(basename "$patch") (already applied)"
    elif git -C "$target" apply "$patch"; then
        echo "apply  $repo/$(basename "$patch")"
    else
        echo "FAIL   $repo/$(basename "$patch")" >&2
    fi
done
