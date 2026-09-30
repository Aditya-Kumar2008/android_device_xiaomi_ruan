#!/usr/bin/env bash
#
# Prepare the build server for Android 17 ruan builds.
#
#   ./server_bootstrap.sh --dry-run     report what would be freed, delete nothing
#   ./server_bootstrap.sh --yes         clean the disk and install everything
#
# Cleaning is destructive by design: the user asked for a full disk clean. The
# script only ever removes build artefacts and caches, never ~/.ssh or keys.

set -uo pipefail

DRY_RUN=1
[[ "${1:-}" == "--yes" ]] && DRY_RUN=0

ANDROID_ROOT="${ANDROID_ROOT:-$HOME/android}"
ROM_DIR="$ANDROID_ROOT/rom"

say() { printf '\n\033[1m== %s\033[0m\n' "$*"; }

human() { du -sh "$1" 2>/dev/null | cut -f1; }

say "Target"
echo "  user      : $(id -un)@$(hostname)"
echo "  cpu       : $(nproc) cores"
echo "  ram       : $(free -g | awk '/^Mem:/{print $2"G"}')"
echo "  root disk : $(df -h / | awk 'NR==2{print $2" total, "$4" free ("$5" used)"}')"
echo "  android   : $ANDROID_ROOT"

# ---------------------------------------------------------------- disk audit
say "Disk audit"

# Candidate build trees: any directory holding a .repo or an out/ dir.
TREES=()
while IFS= read -r d; do TREES+=("$d"); done < <(
    find "$HOME" -maxdepth 4 -type d -name .repo -printf '%h\n' 2>/dev/null | sort -u
)

if ((${#TREES[@]})); then
    echo "  Existing repo trees:"
    for t in "${TREES[@]}"; do
        printf '    %-52s %s\n' "$t" "$(human "$t")"
    done
else
    echo "  Existing repo trees: none"
fi

CACHES=(
    "$HOME/.ccache"
    "$HOME/.cache/repo"
    "$HOME/.repoconfig"
    "$HOME/.cache/bazel"
    "$HOME/.gradle/caches"
)
echo "  Caches:"
for c in "${CACHES[@]}"; do
    [[ -e "$c" ]] && printf '    %-52s %s\n' "$c" "$(human "$c")"
done

# ---------------------------------------------------------------- cleaning
say "Clean"

if ((DRY_RUN)); then
    echo "  DRY RUN - nothing deleted."
    echo "  Would remove:"
    for t in "${TREES[@]}"; do
        echo "    - $t            (source tree, out/, .repo)"
    done
    for c in "${CACHES[@]}"; do
        [[ -e "$c" ]] && echo "    - $c"
    done
    echo
    echo "  Re-run with --yes to apply."
else
    for t in "${TREES[@]}"; do
        echo "  removing tree $t"
        rm -rf "$t"
    done
    for c in "${CACHES[@]}"; do
        [[ -e "$c" ]] && { echo "  removing cache $c"; rm -rf "$c"; }
    done
    # Stale docker layers from any earlier container-based builds.
    if command -v docker >/dev/null 2>&1; then
        echo "  pruning docker"
        docker system prune -af --volumes >/dev/null 2>&1 || true
    fi
    echo "  free after clean: $(df -h / | awk 'NR==2{print $4}')"
fi

((DRY_RUN)) && { say "Done (dry run)"; exit 0; }

# ---------------------------------------------------------------- packages
say "Install build dependencies"

export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -qq
sudo apt-get install -y -qq \
    bc bison build-essential ccache curl flex g++-multilib gcc-multilib git \
    gnupg gperf imagemagick lib32readline-dev lib32z1-dev libelf-dev \
    liblz4-tool libsdl1.2-dev libssl-dev libxml2 libxml2-utils lzop pngcrush \
    rsync schedtool squashfs-tools xsltproc zip zlib1g-dev python3 python3-pip \
    openjdk-21-jdk-headless unzip fontconfig \
    libncurses5 libncurses5-dev libncursesw5-dev \
    device-tree-compiler dosfstools mtools e2fsprogs

# The AOSP tree expects these names even when the host has newer ones.
sudo apt-get install -y -qq libncurses5 2>/dev/null || true

say "Install repo tool"
mkdir -p "$HOME/bin"
if [[ ! -x "$HOME/bin/repo" ]]; then
    curl -fsSL https://storage.googleapis.com/git-repo-downloads/repo -o "$HOME/bin/repo"
    chmod +x "$HOME/bin/repo"
fi
grep -q 'HOME/bin' "$HOME/.profile" 2>/dev/null || \
    echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.profile"
export PATH="$HOME/bin:$PATH"
echo "  repo: $(repo --version 2>/dev/null | head -1 || echo installed)"

say "Configure git"
git config --global user.name  "$(git config --global user.name  || echo openhands)"
git config --global user.email "$(git config --global user.email || echo openhands@all-hands.dev)"
git config --global color.ui auto

# ---------------------------------------------------------------- ccache
say "Configure ccache"
mkdir -p "$HOME/.ccache"
ccache -M 50G >/dev/null 2>&1 && echo "  ccache max size: 50G"
# ccache only helps if it is in the default PATH for non-interactive shells.
grep -q 'CCACHE_DIR' "$HOME/.profile" 2>/dev/null || {
    echo 'export USE_CCACHE=1'          >> "$HOME/.profile"
    echo 'export CCACHE_DIR="$HOME/.ccache"' >> "$HOME/.profile"
    echo 'export CCACHE_EXEC=/usr/bin/ccache' >> "$HOME/.profile"
}

say "Ready"
echo "  free disk : $(df -h / | awk 'NR==2{print $4}')"
echo "  next      : $ROM_DIR setup, then ./build_rom.sh infinityx"
