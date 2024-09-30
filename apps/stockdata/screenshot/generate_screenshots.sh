#!/bin/bash
pixlet render ../stockdata.star -m 100 -o intraday.webp query_type=intraday select_period=1
pixlet render ../stockdata.star -m 100 -o eod.webp query_type=eod select_period=30

for i in *.webp
do
    magick $i -coalesce null: preview-mask.png -compose CopyOpacity -layers composite frame_%d.png
    for f in frame*.png; do
        magick $f -scale 10% -background black -alpha remove -alpha off $f
    done
    rm -f $i
    mv frame_0.png "${i%.webp}.png"
done

if [[ -x /Applications/ImageOptim.app/Contents/MacOS/ImageOptim ]]; then
    /Applications/ImageOptim.app/Contents/MacOS/ImageOptim intraday.png eod.png
fi
