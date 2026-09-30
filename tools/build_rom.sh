#!/usr/bin/env bash
#
# Sync and build one Android 17 ROM for the Redmi Pad Pro 5G (ruan).
#
#   ./build_rom.sh infinityx
#   ./build_rom.sh crdroid
#   ./build_rom.sh infinityx --sync-only
#
# Builds exactly one ROM per invocation so the two ROMs never contend for CPU
# or disk. Artifacts are uploaded to two independent hosts on success.

set -uo pipefail

ROM="${1:-}"
MODE="${2:-build}"
[[ -z "$ROM" ]] && { echo "usage: $0 {infinityx|crdroid} [--sync-only]"; exit 2; }

ANDROID_ROOT="${ANDROID_ROOT:-$HOME/android}"
JOBS="${JOBS:-$(nproc)}"

case "$ROM" in
    infinityx)
        MANIFEST_URL="https://github.com/ProjectInfinity-X/manifest"
        MANIFEST_BRANCH="17"
        LOCAL_MANIFEST="$ANDROID_ROOT/local_manifests/ruan_infinityx.xml"
        ;;
    crdroid)
        MANIFEST_URL="https://github.com/crdroidandroid/android"
        MANIFEST_BRANCH="17.0"
        LOCAL_MANIFEST="$ANDROID_ROOT/local_manifests/ruan_crdroid.xml"
        ;;
    *) echo "unknown rom: $ROM"; exit 2 ;;
esac

ROM_DIR="$ANDROID_ROOT/$ROM"
LOG="$ANDROID_ROOT/${ROM}-$(date +%Y%m%d-%H%M).log"

say() { printf '\n\033[1m== %s\033[0m\n' "$*"; }

export USE_CCACHE=1
export CCACHE_DIR="$HOME/.ccache"
export CCACHE_EXEC=/usr/bin/ccache
export PATH="$HOME/bin:$PATH"
export LC_ALL=C

mkdir -p "$ANDROID_ROOT"

say "ROM        : $ROM"
echo "  manifest : $MANIFEST_URL  ($MANIFEST_BRANCH)"
echo "  tree     : $ROM_DIR"
echo "  jobs     : $JOBS"
echo "  log      : $LOG"

# ---------------------------------------------------------------- disk guard
FREE_GB=$(df --output=avail -BG / | tail -1 | tr -dc '0-9')
echo "  free     : ${FREE_GB}G"
if (( FREE_GB < 250 )); then
    echo "ERROR: need at least 250G free, have ${FREE_GB}G. Run server_bootstrap.sh --yes first."
    exit 1
fi

# ---------------------------------------------------------------- sync
say "Sync"

if [[ ! -d "$ROM_DIR/.repo" ]]; then
    mkdir -p "$ROM_DIR"
    ( cd "$ROM_DIR" && repo init -u "$MANIFEST_URL" -b "$MANIFEST_BRANCH" --git-lfs )
fi

mkdir -p "$ROM_DIR/.repo/local_manifests"
cp "$LOCAL_MANIFEST" "$ROM_DIR/.repo/local_manifests/ruan.xml"

( cd "$ROM_DIR" && repo sync -c -j"$JOBS" --force-sync --no-clone-bundle --no-tags ) || {
    echo "ERROR: repo sync failed"; exit 1;
}

[[ "$MODE" == "--sync-only" ]] && { say "Sync only - done"; exit 0; }

# ---------------------------------------------------------------- build
say "Build"

# ruan's product makefile is lineage_ruan.mk on both ROMs.
TARGET="lineage_ruan"

( cd "$ROM_DIR" && \
  source build/envsetup.sh && \
  lunch "${TARGET}-userdebug" && \
  mka bacon -j"$JOBS" ) 2>&1 | tee "$LOG"

STATUS=${PIPESTATUS[0]}
if (( STATUS != 0 )); then
    say "BUILD FAILED (exit $STATUS)"
    echo "Last errors:"
    grep -nE "error:|FAILED:|ninja: build stopped|undefined reference" "$LOG" | tail -30
    exit "$STATUS"
fi

# ---------------------------------------------------------------- artifacts
OUT="$ROM_DIR/out/target/product/ruan"
say "Artifacts in $OUT"
ls -lh "$OUT"/*.zip "$OUT"/boot.img "$OUT"/recovery.img 2>/dev/null

ZIP=$(ls -t "$OUT"/*.zip 2>/dev/null | head -1)
if [[ -z "$ZIP" ]]; then
    echo "ERROR: no flashable zip produced"; exit 1
fi
echo "  zip: $ZIP  ($(du -h "$ZIP" | cut -f1))"

# ---------------------------------------------------------------- upload
say "Upload"

upload_pixeldrain() {
    curl -fsS --max-time 3600 -T "$ZIP" \
        "https://pixeldrain.com/api/file/$(basename "$ZIP")" \
        | python3 -c 'import json,sys;print("https://pixeldrain.com/u/"+json.load(sys.stdin)["id"])'
}

upload_0x0() {
    curl -fsS --max-time 3600 -F "file=@$ZIP" -F "expires=72" https://0x0.st
}

upload_bashupload() {
    curl -fsS --max-time 3600 -T "$ZIP" https://bashupload.com/"$(basename "$ZIP")" \
        | grep -oE 'https://[^ ]+download[^ ]*' | head -1
}

LINKS=()
for fn in upload_pixeldrain upload_0x0 upload_bashupload; do
    [[ ${#LINKS[@]} -ge 2 ]] && break
    name="${fn#upload_}"
    printf '  %-12s ' "$name"
    if url=$($fn 2>/dev/null) && [[ -n "$url" ]]; then
        echo "$url"
        LINKS+=("$name: $url")
    else
        echo "failed"
    fi
done

say "Result"
if (( ${#LINKS[@]} >= 2 )); then
    echo "  $ROM built and uploaded to ${#LINKS[@]} services:"
    for l in "${LINKS[@]}"; do echo "    $l"; done
else
    echo "  $ROM built, but only ${#LINKS[@]} upload(s) succeeded."
    echo "  Zip is at: $ZIP - upload manually before starting the next ROM."
fi
