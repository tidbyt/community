# Downloads and prepares hieroglyph data in a format that can be pasted into a starlark app.

import base64
import io
import re
import requests
import tarfile

import sys

from bs4 import BeautifulSoup
from PIL import Image

# Many thanks to the WikiHiero project https://www.mediawiki.org/wiki/Extension:WikiHiero
# Sources are released under the GNU Public License and images under the GNU Free Documentation Licence.

TAR_URL = 'https://extdist.wmflabs.org/dist/extensions/wikihiero-REL1_41-4184502.tar.gz'
TABLES_FILE = 'wikihiero/data/tables.php'
SIGN_LIST_URL = 'https://en.wikipedia.org/wiki/List_of_Egyptian_hieroglyphs'

MAX_WIDTH = 62
MAX_HEIGHT = 30

DESCRIPTION = 'description'
PRONUNCIATION = 'pronunciation'
SRC = 'src'

glyphs = {}

resp = requests.get(TAR_URL)
b = io.BytesIO(resp.content)
with tarfile.open(fileobj=b, mode='r:gz') as tar:
    # Images
    for member in tar.getmembers():
        match = re.search(r'wikihiero/img/hiero_(?P<key>(?:[A-Z]|Aa)\d\d?)\.png', member.name)
        if not match:
            continue
        key = match.group('key')
        if key not in glyphs:
            glyphs[key] = {}
        
        buf = tar.extractfile(member)

        # Invert colour (but not transparency)
        img = Image.open(buf).convert('LA')
        l = img.getchannel('L')
        a = img.getchannel('A')

        l, a = img.split()
        l = l.point(lambda p: 255 - p)
        img = Image.merge(img.mode, (l, a))

        # Flatten image for display on black background
        flat_img = Image.new("RGBA", img.size, (0, 0, 0, 255))
        flat_img.paste(img, mask=a)
        img = flat_img.convert('L')

        # Crop and resize
        if img.height > MAX_HEIGHT or img.width > MAX_WIDTH:
            zoom = min(MAX_WIDTH / img.width, MAX_HEIGHT / img.height)
            w = int(zoom * img.width)
            h = int(zoom * img.height)
            img = img.resize((w, h))

        f = io.BytesIO()
        img.save(f, format='png')
        glyphs[key][SRC] = base64.b64encode(f.getvalue()).decode('UTF-8')

    # Pronunciations
    tables = tar.getmember(TABLES_FILE)
    buf = tar.extractfile(tables)
    php = buf.read().decode('UTF-8')

    start = php.find('$wh_phonemes')
    end = php.find(']', start)
    for line in php[start:end].splitlines():
        parts = [p.strip() for p in line.strip().split('=>')]
        if len(parts) != 2:
            continue
        pronunciation, key = parts
        pronunciation = pronunciation.strip('"')
        key = key.split(',')[0].strip('"')
        
        if key not in glyphs:
            continue
        glyphs[key][PRONUNCIATION] = pronunciation

resp = requests.get(SIGN_LIST_URL)
soup = BeautifulSoup(resp.text, features="html.parser")
for key in glyphs:
    row = soup.find(id=key)
    if not row:
        continue
    desc = row.parent.find_all('td')[2].text.strip().strip('"').lower()
    if not desc:
        continue
    glyphs[key][DESCRIPTION] = desc

# Output results as a dict we can paste into a starlark script.
print('{')
for k, v in glyphs.items():
    if SRC not in v:
        print('Got pronunciation but no image:', k, file=sys.stderr)
        continue

    print(f'  "{k}": ' + '{')
    if DESCRIPTION in v:
        print(f'    "{DESCRIPTION}": "{v[DESCRIPTION]}",')
    if PRONUNCIATION in v:
        print(f'    "{PRONUNCIATION}": "{v[PRONUNCIATION]}",')
    print(f'    "{SRC}": "{v[SRC]}"')
    print('  },')
print('}')