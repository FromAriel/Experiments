#!/usr/bin/env bash
# setup_script.sh — reproducible CI setup for Godot-mono + .NET + GDToolkit
set -euo pipefail

###############################################################################
# Config – tweak via env-vars (all have sensible defaults)
###############################################################################
GODOT_VERSION="${GODOT_VERSION:-4.4.1}"
GODOT_CHANNEL="${GODOT_CHANNEL:-stable}"
DOTNET_SDK_MAJOR="${DOTNET_SDK_MAJOR:-8.0}"

GODOT_DIR="/opt/godot-mono/${GODOT_VERSION}"
GODOT_BIN="${GODOT_DIR}/Godot_v${GODOT_VERSION}-${GODOT_CHANNEL}_mono_linux.x86_64"
ONLINE_DOCS_URL="https://docs.godotengine.org/en/stable/"

###############################################################################
# Helpers
###############################################################################
retry() {                      # retry <count> <cmd …>
  local n=$1 d=2 a=1; shift
  while true; do "$@" && break || {
    (( a++ > n )) && return 1
    echo "↻  retry $((a-1))/$n: $*" >&2; sleep $d
  }; done
}

# ── robust lookup that NEVER exits the script ────────────────────────────────
pick_icu() {
  ( set +e +o pipefail
    apt-cache --names-only search '^libicu[0-9]\+$' 2>/dev/null \
      | grep -v -- -dbg      \
      | awk '{print $1}'     \
      | sort -V | tail -1
  )
}

pick_asound() {
  ( set +e +o pipefail
    apt-cache --names-only search '^libasound2' 2>/dev/null \
      | awk '{print $1}' | sort -V | head -1
  )
}

godot_import_pass() {
  echo "🔄  Godot import pass (warming cache)…"
  [[ -f project.godot ]] || { echo "ℹ️  No project.godot – skip."; return; }
  grep -q '^main_scene=' project.godot || { echo "ℹ️  No main_scene – skip."; return; }

  if ls ./*.sln 1>/dev/null 2>&1; then
    for SLN in ./*.sln; do
      echo "🔨  Building .NET: $SLN"
      retry 3 dotnet build --configuration Release "$SLN"
    done
  fi

  local log; log=$(mktemp /tmp/godot_import.XXXX.log)
  retry 3 godot --headless --editor --import --quit --quiet --path . 2>&1 | tee "$log"

  local ignore='(RebuildClassCache\.gd|Static function "get_singleton"|Static function "idle_frame"|Function "get_tree")'
  if grep -E 'SCRIPT ERROR|ERROR:' "$log" | grep -Ev "$ignore" -q; then
    echo "❌  Godot import errors:"
    grep -E 'SCRIPT ERROR|ERROR:' "$log" | grep -Ev "$ignore" -n | head -20
    exit 1
  fi
}

###############################################################################
# 1. Base OS packages
###############################################################################
echo '🔄  apt update …'; retry 5 apt-get update -y -qq
echo '📦  Installing basics …'
retry 5 apt-get install -y -qq unzip wget curl git python3 python3-pip \
  ca-certificates gnupg lsb-release software-properties-common \
  binutils util-linux bsdextrautils xxd less w3m lynx elinks links html2text vim-common

###############################################################################
# 2. Runtime libraries Godot needs
###############################################################################
RUNTIME_PKGS=(
  "$(pick_icu)"                                         # ICU
  libvulkan1 mesa-vulkan-drivers libgl1 libglu1-mesa     # GL / Vulkan
  libxi6 libxrandr2 libxinerama1 libxcursor1 libx11-6    # X11
  "$(pick_asound)" libpulse0                            # Audio
)

echo '📦  Ensuring Godot runtime libraries …'
for p in "${RUNTIME_PKGS[@]}"; do
  [[ -z "$p" ]] && continue      # skip blank entries
  if apt-cache show "$p" >/dev/null 2>&1; then
    retry 3 apt-get install -y -qq "$p"
  else
    echo "⚠️  Package $p not found – skipping."
  fi
done

###############################################################################
# 3. .NET SDK (install only if absent)
###############################################################################
if ! command -v dotnet >/dev/null; then
  echo "⬇️  Installing .NET SDK ${DOTNET_SDK_MAJOR} …"
  retry 3 add-apt-repository -y ppa:dotnet/backports
  retry 5 apt-get update -y -qq
  retry 5 apt-get install -y -qq "dotnet-sdk-${DOTNET_SDK_MAJOR}"
fi

###############################################################################
# 4. Godot-mono (download & link if not cached)
###############################################################################
if [[ ! -x "$GODOT_BIN" ]]; then
  echo "⬇️  Fetching Godot-mono ${GODOT_VERSION}-${GODOT_CHANNEL} …"
  tmp=$(mktemp -d)
  zip="Godot_v${GODOT_VERSION}-${GODOT_CHANNEL}_mono_linux_x86_64.zip"
  url="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-${GODOT_CHANNEL}/${zip}"
  retry 5 wget -q --show-progress -O "$tmp/$zip" "$url"
  unzip -q "$tmp/$zip" -d "$tmp"
  install -d "$GODOT_DIR"
  mv "$tmp"/Godot_v${GODOT_VERSION}-${GODOT_CHANNEL}_mono_linux_x86_64/* "$GODOT_DIR/"
  ln -sf "$GODOT_BIN" /usr/local/bin/godot && chmod +x /usr/local/bin/godot
  rm -rf "$tmp"
  echo "✔️  Godot-mono installed → $(command -v godot)"
fi

###############################################################################
# 5. GDToolkit & pre-commit
###############################################################################
echo '🐍  Installing GDToolkit & pre-commit …'
retry 5 pip3 install --no-cache-dir --upgrade 'gdtoolkit==4.*' 'pre-commit>=4.2,<5'
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo '🔧  Installing pre-commit hooks …'
  retry 3 pre-commit install --install-hooks
fi

###############################################################################
# 6. Sanity check & warm import cache
###############################################################################
for t in git curl wget unzip python3 pip3 gdformat gdlint dotnet godot; do
  command -v "$t" >/dev/null || { echo "❌  $t missing"; exit 1; }
done

echo -e '\n✅  Base setup complete!'
echo " • Godot-mono: $(command -v godot)"
echo " • .NET SDK:   $(command -v dotnet)"
echo " • Docs:       ${ONLINE_DOCS_URL}"

echo -e '\n🔍  Scanning for Godot projects …'
find . -type f -name project.godot -print0 | while IFS= read -r -d '' proj; do
  dir=$(dirname "$proj")
  echo "🚀  Import pass for $dir"
  ( cd "$dir" && godot_import_pass )
done

echo '✅  Done.'
