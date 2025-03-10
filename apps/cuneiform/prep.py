import base64
import io
import requests

from bs4 import BeautifulSoup
from PIL import Image

SIGN_LIST_URL = 'https://etcsl.orinst.ox.ac.uk/edition2/signlist.php'
BASE_URL = 'https://etcsl.orinst.ox.ac.uk/edition2/'

MAX_WIDTH = 62
MAX_HEIGHT = 30

UNICODE_ESCAPE = 'unicode_escape'
NAME = 'name'
SUMERIAN = 'sumerian_transliterations'
SRC = 'src'

def print_raw_string_list(l):
    return ", ".join(["r'" + i + "'" for i in l])


resp = requests.get(SIGN_LIST_URL)
soup = BeautifulSoup(resp.text, features="html.parser")

signs = []

for row in soup.find_all('table')[2].find_all('tr')[1:]:
    cells = row.find_all('td')
    images = cells[1].find_all('img')
    if len(images) != 1:
        continue

    sign_name = cells[0].text.strip()
    borger = sign_name.find('Borger:')
    if borger != -1:
        sign_name = sign_name[:borger].strip()

    sumerian = sorted([s.strip() for s in cells[2].text.split(', ')])
    
    img_url = BASE_URL + images[0]['src']
    img_resp = requests.get(img_url)
    b = io.BytesIO(img_resp.content)
    img = Image.open(b)
    img = img.point(lambda p: 255 - p)  # invert colours

    if img.height > MAX_HEIGHT or img.width > MAX_WIDTH:
        zoom = min(MAX_WIDTH / img.width, MAX_HEIGHT / img.height)
        w = int(zoom * img.width)
        h = int(zoom * img.height)
        img = img.resize((w, h))

    f = io.BytesIO()
    img.save(f, format='png')
    
    signs.append({
        NAME: sign_name,
        SUMERIAN: sumerian,
        SRC: base64.b64encode(f.getvalue()).decode('UTF-8')
    })

print('[')
for sign in signs:
    print('  {')
    print(f'    "{NAME}": r"{sign[NAME]}",')
    print(f'    "{SUMERIAN}": [{print_raw_string_list(sign[SUMERIAN])}],')
    print(f'    "{SRC}": "{sign[SRC]}"')
    print('  },')
print(']')