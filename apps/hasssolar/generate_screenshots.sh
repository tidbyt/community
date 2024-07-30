#!/bin/bash
pixlet render hass_solar.star -m 100 -o output.webp show_char=true show_prod=true show_cons=true
magick output.webp -coalesce null: preview-mask.png -compose CopyOpacity -layers composite frame_%d.png
for f in frame*.png; do
    magick $f -scale 10% -background black -alpha remove -alpha off $f
done
rm output.webp
if [[ -x /Applications/ImageOptim.app/Contents/MacOS/ImageOptim ]]; then
    /Applications/ImageOptim.app/Contents/MacOS/ImageOptim frame_*.png
fi
