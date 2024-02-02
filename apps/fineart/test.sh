# validate that no images are too big

echo "## TESTING CAPTION=FALSE"
for i in {0..65}; do
    size=$(pixlet render fine_art.star index=$i && du -k fine_art.webp | cut -f1)

    if (($size > 192)); then
        echo "- Image at $i is too big: $size"
    fi
done

echo "## TESTING CAPTION=TRUE"
for i in {0..65}; do
    size=$(pixlet render fine_art.star caption=true index=$i && du -k fine_art.webp | cut -f1)

    if (($size > 192)); then
        echo "- Image at $i is too big: $size"
    fi
done
