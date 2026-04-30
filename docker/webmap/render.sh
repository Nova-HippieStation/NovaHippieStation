#!/bin/sh
# render.sh — Render + tile the HippieStation map on container startup.
#
# This script is the CMD for the webmap-renderer service.  It:
#   1. Checks if tiles already exist in the shared volume (skips if so).
#   2. Runs dmm-tools minimap to render each z-level to a flat PNG.
#   3. Runs tile.py to cut each PNG into a Leaflet XYZ tile pyramid.
#
# To force a full re-render: docker-compose down -v then bring the stack back
# up, or simply remove the webmap_tiles volume.

set -e

TILES_OUT=/tiles/hippiestation
MAPS_TMP=/tmp/maps
SRC=/src

# ── Skip if tiles already exist ───────────────────────────────────────────────
if [ -d "$TILES_OUT" ] && [ "$(ls -A "$TILES_OUT" 2>/dev/null)" ]; then
    echo "[webmap] Tiles already present in $TILES_OUT — skipping render."
    echo "[webmap] Remove the webmap_tiles volume to force regeneration."
    exit 0
fi

# ── Render ────────────────────────────────────────────────────────────────────
echo "[webmap] Rendering map with dmm-tools …"
mkdir -p "$MAPS_TMP"

# dmm-tools minimap v1.11+ removed the --output flag; it always writes PNGs
# to the current working directory.  Use a subshell to cd into MAPS_TMP so
# the PNGs land in the right place without polluting other directories.
(
  cd "$MAPS_TMP"
  dmm-tools minimap \
      "$SRC/hippiestation.dme" \
      "$SRC/_maps/map_files/HippieStation/hippiestation.dmm" \
      2>&1
) || echo "[webmap] Warning: dmm-tools returned non-zero (parse warnings are normal)"

echo "[webmap] Rendered PNGs:"
ls "$MAPS_TMP"/*.png 2>/dev/null || { echo "[webmap] ERROR: No PNGs produced!"; exit 1; }

# ── Tile ──────────────────────────────────────────────────────────────────────
echo "[webmap] Tiling (zoom 0-5) …"
mkdir -p "$TILES_OUT"
python3 /tile.py "$MAPS_TMP" "$TILES_OUT" 0 5

echo "[webmap] All done.  Tiles at $TILES_OUT"
