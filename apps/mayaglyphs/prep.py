# Downloads and prepares glyph data in a format that can be pasted into a starlark app.

import base64
import io
import requests
import zipfile

import sys

from PIL import Image

# Many thanks to Rafael C Alvarado and the Mayan Epigraphic Database Project
# http://www2.iath.virginia.edu/med/
TEXT_URL = "http://www2.iath.virginia.edu/med/download/pvalues.zip"
TEXT_PATH = "docs/htdocs/med/GLYPH_~1/by_value.txt"
IMAGE_URL = "http://www2.iath.virginia.edu/med/download/glyphs.zip"

MAX_WIDTH = 62
MAX_HEIGHT = 30
PRONUNCIATION = 'pronunciation'
SRC = 'src'

glyphs = {}

def fix_orthography(c):
    # Catalog departed from generally accepted orthography in order
    # to force one ascii character per phoneme.
    # http://www2.iath.virginia.edu/med/glyph_catalog.html#anchor_3
    if c == 'c':
        return "ch"
    if c == 'z':
        return "tz"
    if c == 's':
        return "z"
    return c

# Get the text index
resp = requests.get(TEXT_URL)
b = io.BytesIO(resp.content)
with zipfile.ZipFile(b) as zip:
    with zip.open(TEXT_PATH) as file:
        for line in file.read().splitlines()[1:]:
            id, pronunciation = [w.strip('"') for w in line.decode('UTF-8').split(',')]
            if id not in glyphs:
                glyphs[id] = {PRONUNCIATION: set()}
            if pronunciation == 'UND':
                continue
            pronunciation = ''.join([fix_orthography(c) for c in pronunciation])
            glyphs[id][PRONUNCIATION].add(pronunciation)

# Get the images and process them for display on Tidbyt.
resp = requests.get(IMAGE_URL)
b = io.BytesIO(resp.content)
with zipfile.ZipFile(b) as zip:
    for name in zip.namelist():
        key = name[:4] + '.' + name[4:6]

        # There are a handful. They seem to be variants of other glyphs.
        if key not in glyphs:
            print('Got image but no pronunciation:', key, file=sys.stderr)
            continue

        with zip.open(name) as file:
            img = Image.open(file)
            
            # Invert black and white
            img.putpalette(img.getpalette()[::-1])
            img = img.convert('RGB')
            
            # Crop and resize
            img = img.crop(img.getbbox())
            zoom = min(MAX_WIDTH / img.width, MAX_HEIGHT / img.height)
            w = int(zoom * img.width)
            h = int(zoom * img.height)
            img = img.resize((w, h))

            f = io.BytesIO(b'')
            img.save(f, format='png')
            glyphs[key][SRC] = base64.b64encode(f.getvalue()).decode('UTF-8')

# Output results as a dict we can paste into a starlark script.
print('{')
for k, v in glyphs.items():
    if SRC not in v:
        print('Got pronunciation but no image:', k, file=sys.stderr)
        continue

    print(f'  "{k}": ' + '{')
    print(f'    "{PRONUNCIATION}": {sorted(v[PRONUNCIATION])},')
    print(f'    "{SRC}": "{v[SRC]}"')
    print('  },')
print('}')