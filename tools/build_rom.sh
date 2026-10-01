#!/usr/bin/env bash
#
# Build one Android 17 ROM for the Redmi Pad Pro 5G (ruan).
#
#   ./build_rom.sh space          report free space and what is using it
#   ./build_rom.sh clean          free space, delete every build tree
#   ./build_rom.sh infinityx      free space, sync, build, upload
#   ./build_rom.sh crdroid        free space, sync, build, upload
#
# One ROM at a time. Each build removes the previous ROM's tree before it
# starts, so the two never share the disk. A ROM only counts as finished
# once it has uploaded to two independent hosts.

set -uo pipefail

CMD="${1:-}"
[[ -z "$CMD" ]] && { echo "usage: $0 {space|clean|infinityx|crdroid}"; exit 2; }

ANDROID_ROOT="${ANDROID_ROOT:-$HOME/android}"
ARTIFACTS="$ANDROID_ROOT/artifacts"
JOBS="${JOBS:-$(nproc)}"
MIN_FREE_GB=250

ROM_INFINITYX="infinityx"
ROM_CRDROID="crdroid"

say() { printf '\n\033[1m== %s\033[0m\n' "$*"; }
free_gb() { df --output=avail -BG / | tail -1 | tr -dc '0-9'; }

clean_tree() {
    local d="$1"
    [[ -d "$d" ]] || return 0
    echo "  removing $d ($(du -sh "$d" 2>/dev/null | cut -f1))"
    rm -rf "$d"
}

clean_caches() {
    for c in "$HOME/.cache/repo" "$HOME/.repoconfig" "$HOME/.cache/bazel"; do
        [[ -e "$c" ]] && { echo "  removing $c"; rm -rf "$c"; }
    done
    # ccache is deliberately kept: rebuilding from scratch costs hours.
    [[ -d "$HOME/.ccache" ]] && echo "  keeping $HOME/.ccache ($(du -sh "$HOME/.ccache" | cut -f1))"
}

# ------------------------------------------------------------------ space
if [[ "$CMD" == "space" ]]; then
    say "Space"
    df -h / | awk 'NR==1 || NR==2'
    echo
    for d in "$ANDROID_ROOT"/*; do
        [[ -d "$d" ]] && printf '  %-40s %s\n' "$(basename "$d")" "$(du -sh "$d" 2>/dev/null | cut -f1)"
    done
    [[ -d "$HOME/.ccache" ]] && printf '  %-40s %s\n' ".ccache" "$(du -sh "$HOME/.ccache" | cut -f1)"
    exit 0
fi

# ------------------------------------------------------------------ clean
if [[ "$CMD" == "clean" ]]; then
    say "Clean"
    echo "  free before: $(free_gb)G"
    for d in "$ANDROID_ROOT"/*/; do
        [[ -d "$d" ]] || continue
        # Only delete directories that are actually build trees.
        [[ -d "$d/.repo" || -d "$d/out" || -d "$d/.git" ]] && clean_tree "${d%/}"
    done
    clean_caches
    if command -v docker >/dev/null 2>&1; then
        docker system prune -af --volumes >/dev/null 2>&1 && echo "  pruned docker"
    fi
    say "Done"
    echo "  free after: $(free_gb)G"
    exit 0
fi

# ------------------------------------------------------------------ build
case "$CMD" in
    infinityx)
        MANIFEST_URL="https://github.com/ProjectInfinity-X/manifest"
        MANIFEST_BRANCH="17"
        LOCAL_MANIFEST="$ANDROID_ROOT/local_manifests/ruan_infinityx.xml"
        OTHER="$ANDROID_ROOT/$ROM_CRDROID"
        ;;
    crdroid)
        MANIFEST_URL="https://github.com/crdroidandroid/android"
        MANIFEST_BRANCH="17.0"
        LOCAL_MANIFEST="$ANDROID_ROOT/local_manifests/ruan_crdroid.xml"
        OTHER="$ANDROID_ROOT/$ROM_INFINITYX"
        ;;
    *) echo "unknown command: $CMD"; exit 2 ;;
esac

ROM_DIR="$ANDROID_ROOT/$CMD"
LOG="$ARTIFACTS/${CMD}-$(date +%Y%m%d-%H%M).log"

export USE_CCACHE=1
export CCACHE_DIR="$HOME/.ccache"
export CCACHE_EXEC=/usr/bin/ccache
export PATH="$HOME/bin:$PATH"
export LC_ALL=C

mkdir -p "$ANDROID_ROOT" "$ARTIFACTS"

say "Build $CMD"
echo "  manifest : $MANIFEST_URL ($MANIFEST_BRANCH)"
echo "  tree     : $ROM_DIR"
echo "  jobs     : $JOBS"
echo "  free     : $(free_gb)G"

# Free the other ROM first. The previous ROM has already been uploaded by the
# time this runs, so its tree is dead weight.
if [[ -d "$OTHER" ]]; then
    say "Freeing space (previous ROM: $(basename "$OTHER"))"
    clean_tree "$OTHER"
    echo "  free now : $(free_gb)G"
fi

if (( $(free_gb) < MIN_FREE_GB )); then
    say "Not enough space"
    echo "  need ${MIN_FREE_GB}G, have $(free_gb)G. Run: $0 clean"
    exit 1
fi

# ------------------------------------------------------------------ sync
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

# ------------------------------------------------------------------ build
say "Build"
( cd "$ROM_DIR" && \
  source build/envsetup.sh && \
  lunch lineage_ruan-userdebug && \
  mka bacon -j"$JOBS" ) 2>&1 | tee "$LOG"

STATUS=${PIPESTATUS[0]}
if (( STATUS != 0 )); then
    say "BUILD FAILED (exit $STATUS)"
    grep -nE "error:|FAILED:|ninja: build stopped|undefined reference" "$LOG" | tail -30
    exit "$STATUS"
fi

# ------------------------------------------------------------------ collect
OUT="$ROM_DIR/out/target/product/ruan"
ZIP=$(ls -t "$OUT"/*.zip 2>/dev/null | head -1)
[[ -z "$ZIP" ]] && { echo "ERROR: no flashable zip produced"; exit 1; }

say "Artifact"
echo "  $(basename "$ZIP")  ($(du -h "$ZIP" | cut -f1))"
# Keep the zip and images outside the tree so a later clean cannot lose them.
mkdir -p "$ARTIFACTS/$CMD"
cp "$ZIP" "$ARTIFACTS/$CMD/"
for img in boot.img recovery.img dtbo.img vbmeta.img; do
    [[ -f "$OUT/$img" ]] && cp "$OUT/$img" "$ARTIFACTS/$CMD/"
done
ZIP="$ARTIFACTS/$CMD/$(basename "$ZIP")"
echo "  saved to $ARTIFACTS/$CMD/"

# ------------------------------------------------------------------ upload
say "Upload"
LINKS=()

u_pixeldrain() {
    curl -fsS --max-time 3600 -T "$ZIP" \
        "https://pixeldrain.com/api/file/$(basename "$ZIP")" \
        | python3 -c 'import json,sys;print("https://pixeldrain.com/u/"+json.load(sys.stdin)["id"])'
}
u_0x0() {
    curl -fsS --max-time 3600 -F "file=@$ZIP" -F "expires=72" https://0x0.st
}
u_bashupload() {
    curl -fsS --max-time 3600 -T "$ZIP" https://bashupload.com/"$(basename "$ZIP")" \
        | grep -oE 'https://[^ ]+download[^ ]*' | head -1
}

for fn in u_pixeldrain u_0x0 u_bashupload; do
    (( ${#LINKS[@]} >= 2 )) && break
    printf '  %-12s ' "${fn#u_}"
    if url=$($fn 2>/dev/null) && [[ -n "$url" ]]; then echo "$url"; LINKS+=("${fn#u_}: $url")
    else echo "failed"; fi
done

say "Result"
if (( ${#LINKS[@]} >= 2 )); then
    echo "  $CMD built and uploaded to ${#LINKS[@]} services:"
    for l in "${LINKS[@]}"; do echo "    $l"; done
    echo
    echo "  Zip kept at: $ZIP"
    NEXT=$([[ "$CMD" == infinityx ]] && echo crdroid || echo infinityx)
    echo "  Next: $0 clean && $0 $NEXT"
else
    echo "  $CMD built, only ${#LINKS[@]} upload(s) succeeded."
    echo "  Upload manually before starting the next ROM. Zip: $ZIP"
    exit 1
fi
