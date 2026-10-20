#!/bin/bash
set -euo pipefail

version="${1:?usage: packaging/deb/build.sh VERSION OUTPUT_DIR}"
output="${2:?usage: packaging/deb/build.sh VERSION OUTPUT_DIR [SOURCE_DIR]}"
repo="${3:-$(cd "$(dirname "$0")/../.." && pwd)}"
repo="$(cd "$repo" && pwd)"
root="$(mktemp -d)"
trap 'rm -rf "$root"' EXIT
pkg="$root/deadband"
share="$pkg/usr/share/deadband"

install -d "$share" "$pkg/usr/bin" "$pkg/usr/lib/udev/rules.d"
install -m 0644 "$repo"/*.py "$share/"
rm -f "$share/smoke_test.py"
cp -a "$repo/vendors" "$repo/qml" "$share/"
install -d "$share/assets"
install -m 0644 "$repo"/assets/{icon.png,icon-48.png,icon-64.png,icon-128.png,glyph-pad.png,glyph-pad-dark.png} "$share/assets/"
install -m 0644 "$repo/70-gamesir.rules" "$share/"
install -D -m 0644 "$repo/packaging/udev/70-deadband-g502x.rules" "$share/packaging/udev/70-deadband-g502x.rules"
install -m 0644 "$repo/70-gamesir.rules" "$pkg/usr/lib/udev/rules.d/70-gamesir.rules"
install -m 0644 "$repo/packaging/udev/70-deadband-g502x.rules" "$pkg/usr/lib/udev/rules.d/70-deadband-g502x.rules"
install -D -m 0644 "$repo/packaging/deadband.desktop" "$pkg/usr/share/applications/deadband.desktop"
for size in 48 64 128; do
    install -D -m 0644 "$repo/assets/icon-${size}.png" "$pkg/usr/share/icons/hicolor/${size}x${size}/apps/deadband.png"
done
install -D -m 0644 "$repo/assets/icon.png" "$pkg/usr/share/icons/hicolor/256x256/apps/deadband.png"
install -D -m 0644 "$repo/LICENSE" "$pkg/usr/share/doc/deadband/copyright"
cat > "$pkg/usr/bin/deadband" <<'EOF'
#!/usr/bin/python3
import runpy
import sys
sys.path.insert(0, '/usr/share/deadband')
runpy.run_path('/usr/share/deadband/deadband.py', run_name='__main__')
EOF
chmod 0755 "$pkg/usr/bin/deadband"
install -Dm 0644 "$repo/completions/bash/deadband" \
    "$pkg/usr/share/bash-completion/completions/deadband"
install -Dm 0644 "$repo/completions/zsh/_deadband" \
    "$pkg/usr/share/zsh/site-functions/_deadband"
install -Dm 0644 "$repo/completions/fish/deadband.fish" \
    "$pkg/usr/share/fish/vendor_completions.d/deadband.fish"

install -d "$pkg/DEBIAN"
sed "s/@VERSION@/$version/" "$repo/packaging/deb/control.in" > "$pkg/DEBIAN/control"
install -m 0755 "$repo/packaging/deb/postinst" "$pkg/DEBIAN/postinst"
mkdir -p "$output"
dpkg-deb --root-owner-group --build "$pkg" "$output/deadband_${version}_all.deb"
