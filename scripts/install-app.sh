#!/usr/bin/env bash

set -euo pipefail
shopt -s nullglob

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
app_name="MarkdownViewer"
build_config="${BUILD_CONFIG:-release}"
install_dir="${1:-${INSTALL_DIR:-$HOME/Applications}}"
app_path="$install_dir/$app_name.app"

cd "$repo_root"

echo "Generating app icon..."
swift scripts/generate-icon.swift >/dev/null

echo "Building $app_name ($build_config)..."
swift build -c "$build_config"

bin_path="$(swift build -c "$build_config" --show-bin-path)"
binary_path="$bin_path/$app_name"

if [[ ! -x "$binary_path" ]]; then
  echo "Expected executable not found: $binary_path" >&2
  exit 1
fi

echo "Installing to $app_path"
mkdir -p "$install_dir"
rm -rf "$app_path"
mkdir -p "$app_path/Contents/MacOS" "$app_path/Contents/Resources"

cp "$repo_root/Packaging/Info.plist" "$app_path/Contents/Info.plist"
cp "$repo_root/Packaging/AppIcon.icns" "$app_path/Contents/Resources/AppIcon.icns"
ditto "$binary_path" "$app_path/Contents/MacOS/$app_name"

for bundle_path in "$bin_path"/*.bundle; do
  bundle_name="$(basename "$bundle_path")"
  ditto "$bundle_path" "$app_path/Contents/Resources/$bundle_name"

  # SwiftPM resource bundles look under Bundle.main.bundleURL first.
  ln -sfn "Contents/Resources/$bundle_name" "$app_path/$bundle_name"
done

echo "Installed: $app_path"
echo "Run with: open \"$app_path\""
echo "Note: the app is intentionally left unsigned for local use."
