#!/bin/sh

CORE_DST="box_bll/bin/clash"
CORE_TMP="clash_core.gz"

MIHOMO_API="https://api.github.com/repos/MetaCubeX/mihomo/releases/latest"
MIHOMO_BASE="https://github.com/MetaCubeX/mihomo/releases/download"
MIHOMO_NAME="mihomo-android-arm64-v8"

latest_version=$(curl -fsSL \
    --retry 5 \
    --retry-delay 5 \
    -H "Authorization: token $GITHUB_TOKEN" \
    "$MIHOMO_API" \
    | grep '"tag_name":' | head -n 1 \
    | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/')

if [ -z "$latest_version" ]; then
    echo "Failed to get latest mihomo version"
    exit 1
fi

echo "Latest mihomo version: $latest_version"

download_url="${MIHOMO_BASE}/${latest_version}/${MIHOMO_NAME}-${latest_version}.gz"

echo "Downloading mihomo core..."
curl -fL --retry 5 --retry-delay 5 "$download_url" -o "$CORE_TMP"

if [ ! -s "$CORE_TMP" ]; then
    echo "Core download failed or file is empty"
    exit 1
fi

gunzip -c "$CORE_TMP" > "$CORE_DST"

rm -f "$CORE_TMP"

APK_DIR="app/version/com.surfing.tile"
TILE_DST="SurfingTile/system/app/com.surfing.tile"
TILE_PROP="SurfingTile/module.prop"

latest_apk=$(ls "$APK_DIR"/Tile_*_release.apk 2>/dev/null | sort -V | tail -n 1)

apk_filename=$(basename "$latest_apk")

tile_version=$(echo "$apk_filename" | sed -E 's/^Tile_([0-9.]+)_release\.apk$/\1/')

cp -f "$latest_apk" "$TILE_DST/com.surfing.tile.apk"

sed -i "s/^version=.*/version=v$tile_version/" "$TILE_PROP"

WEB_APK_DIR="app/version/com.android64bit.web"
WEB_DST="webroot"

latest_web_apk=$(ls "$WEB_APK_DIR"/Web_*_release.apk 2>/dev/null | sort -V | tail -n 1)

apk_web_filename=$(basename "$latest_web_apk")

cp -f "$latest_web_apk" "$WEB_DST/com.android64bit.web.apk"

version=$(grep '^version=' module.prop | awk -F '=' '{print $2}' | sed 's/ (.*//')
short_hash=${SHORT_HASH:-$(git rev-parse --short=7 HEAD)}

if [ "$isAlpha" = true ]; then
    new_version="${version} (alpha-${short_hash})"
    filename="Surfing_alpha_${short_hash}.zip"
else
    new_version="${version} (release-${short_hash})"
    filename="Surfing_${version}_release.zip"
fi

sed -i "s/^version=.*/version=${new_version}/" module.prop

cd SurfingTile || exit 1
zip -r -o -X ../SurfingTile.zip ./*
cd ..

zip -r -o -X "$filename" ./ \
    -x 'SurfingTile/*' \
    -x 'app/*' \
    -x '.git/*' \
    -x '.github/*' \
    -x 'folder/*' \
    -x 'build.sh' \
    -x 'Surfing.json'