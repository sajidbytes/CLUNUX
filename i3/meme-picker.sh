#!/usr/bin/env bash
SRC="$HOME/Pictures/Memes"
CACHE="$HOME/.cache/memes"
THEME="$HOME/.config/rofi/theme.rasi"
W="$HOME/.cache/wal/colors.json"

mkdir -p "$SRC" "$CACHE"

COLORS="* {
  bg: $(jq -r .special.background "$W");
  fg: $(jq -r .special.foreground "$W");
  border: $(jq -r .colors.color4 "$W");
  selectedbg: $(jq -r .colors.color4 "$W");
  accent: $(jq -r .colors.color2 "$W");
}"

GRID="
window { width: 900px; }
mainbox { children: [ listview ]; }
listview { columns: 5; lines: 3; fixed-columns: true; flow: horizontal; spacing: 10px; scrollbar: false; }
element { orientation: vertical; padding: 6px; }
element-icon { size: 9em; horizontal-align: 0.5; }
element-text { enabled: false; }
"

# Build thumbnails only for new images
find "$SRC" -maxdepth 1 -type f \
  \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.gif' \) -print0 |
while IFS= read -r -d '' f; do
  [ -f "$CACHE/$(basename "$f").png" ] || printf '%s\0' "$f"
done |
xargs -0 -r -P"$(nproc)" -I{} sh -c \
  'magick "$1[0]" -thumbnail 256x256 "$2/$(basename "$1").png"' _ {} "$CACHE"

# Show grid, newest first
choice=$(ls -t "$SRC" | while IFS= read -r name; do
  [ -f "$CACHE/$name.png" ] && printf '%s\0icon\x1f%s\n' "$name" "$CACHE/$name.png"

done | rofi -dmenu -normal-window -i -show-icons -theme "$THEME" -theme-str "$COLORS" -theme-str "$GRID" -p meme)
[ -z "$choice" ] && exit 0

# Copy original to clipboard
f="$SRC/$choice"
xclip -selection clipboard -t "$(file -b --mime-type "$f")" -i "$f"
notify-send -t 1200 "Meme copied" "$choice"

#to png
f="$SRC/$choice"
case "${f,,}" in
  *.webp) magick "$f[0]" png:- | xclip -selection clipboard -t image/png ;;
  *)      xclip -selection clipboard -t "$(file -b --mime-type "$f")" -i "$f" ;;
esac
