#!/usr/bin/env bash
#
# Prepare the build host for Android 17 ruan builds.
#
#   ./server_bootstrap.sh --dry-run     report what would be freed, delete nothing
#   ./server_bootstrap.sh --yes         clean the disk and install everything
#
# Cleaning is destructive by design - you asked for a full disk clean. The
# script only removes build trees and caches. It never touches ~/.ssh, and it
# never removes anything it does not recognise as a build tree.

set -uo pipefail

DRY_RUN=1
[[ "${1:-}" == "--yes" ]] && DRY_RUN=0

ANDROID_ROOT="${ANDROID_ROOT:-$HOME/android}"
ROM_DIR="$ANDROID_ROOT/rom"

say() { printf '\n\033[1m== %s\033[0m\n' "$*"; }
human() { du -sh "$1" 2>/dev/null | cut -f1; }
free_gb() { df --output=avail -BG / | tail -1 | tr -dc '0-9'; }

say "Target"
echo "  user      : $(id -un)@$(hostname)"
echo "  cpu       : $(nproc) cores"
echo "  ram       : $(free -g | awk '/^Mem:/{print $2"G"}')"
echo "  root disk : $(df -h / | awk 'NR==2{print $2" total, "$4" free ("$5" used)"}')"
echo "  android   : $ANDROID_ROOT"

# ---------------------------------------------------------------- disk audit
say "Disk audit"
echo "  free: $(free_gb)G"

TREES=()
while IFS= read -r d; do TREES+=("$d"); done < <(
    find "$HOME" -maxdepth 4 -type d -name .repo -printf '%h\n' 2>/dev/null | sort -u
)

if ((${#TREES[@]})); then
    echo "  Build trees:"
    for t in "${TREES[@]}"; do printf '    %-48s %s\n' "$t" "$(human "$t")"; done
else
    echo "  Build trees: none"
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
    [[ -e "$c" ]] && printf '    %-48s %s\n' "$c" "$(human "$c")"
done

# Anything else large that is obviously not source.
echo "  Other large directories:"
for d in "$HOME"/*; do
    [[ -d "$d" ]] || continue
    case "$(basename "$d")" in
        .ccache|.cache|android|.ssh|.config|.local) continue ;;
    esac
    sz=$(du -sm "$d" 2>/dev/null | cut -f1)
    (( sz > 2048 )) && printf '    %-48s %s\n' "$d" "$(human "$d")"
done

# ---------------------------------------------------------------- cleaning
say "Clean"

if ((DRY_RUN)); then
    echo "  DRY RUN - nothing deleted. Would remove:"
    for t in "${TREES[@]}"; do echo "    - $t"; done
    for c in "${CACHES[@]}"; do [[ -e "$c" ]] && echo "    - $c"; done
    echo
    echo "  ~/.ccache is kept - rebuilding it costs hours."
    echo "  Re-run with --yes to apply."
else
    for t in "${TREES[@]}"; do
        echo "  removing tree $t ($(human "$t"))"
        rm -rf "$t"
    done
    for c in "${CACHES[@]}"; do
        [[ -e "$c" ]] && { echo "  removing cache $c"; rm -rf "$c"; }
    done
    if command -v docker >/dev/null 2>&1; then
        docker system prune -af --volumes >/dev/null 2>&1 && echo "  pruned docker"
    fi
    # Old logs are cheap to lose and accumulate across builds.
    [[ -d "$ANDROID_ROOT/artifacts" ]] && find "$ANDROID_ROOT/artifacts" -name '*.log' -mtime +7 -delete 2>/dev/null
    echo "  free after: $(free_gb)G"
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
    openjdk-21-jdk-headless unzip fontconfig device-tree-compiler dosfstools \
    mtools e2fsprogs libncurses5-dev libncursesw5-dev

say "Install repo"
mkdir -p "$HOME/bin"
[[ -x "$HOME/bin/repo" ]] || {
    curl -fsSL https://storage.googleapis.com/git-repo-downloads/repo -o "$HOME/bin/repo"
    chmod +x "$HOME/bin/repo"
}
grep -q 'HOME/bin' "$HOME/.profile" 2>/dev/null || echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.profile"
export PATH="$HOME/bin:$PATH"
echo "  repo: $(repo --version 2>/dev/null | head -1 || echo installed)"

say "Configure git"
git config --global color.ui auto
[[ -z "$(git config --global user.name)"  ]] && git config --global user.name  "Aditya Kumar"
[[ -z "$(git config --global user.email)" ]] && git config --global user.email "adityarohilla2023@gmail.com"
echo "  $(git config --global user.name) <$(git config --global user.email)>"

say "Configure ccache"
mkdir -p "$HOME/.ccache"
ccache -M 50G >/dev/null 2>&1 && echo "  max size 50G"
grep -q 'CCACHE_DIR' "$HOME/.profile" 2>/dev/null || {
    echo 'export USE_CCACHE=1'               >> "$HOME/.profile"
    echo 'export CCACHE_DIR="$HOME/.ccache"' >> "$HOME/.profile"
    echo 'export CCACHE_EXEC=/usr/bin/ccache' >> "$HOME/.profile"
}

say "Ready"
echo "  free disk : $(free_gb)G"
echo "  next      : ./build_rom.sh infinityx"
