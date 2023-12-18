import datetime
import decimal
import math
import re
import requests

# https://ssd.jpl.nasa.gov/api/horizons.api?format=text&COMMAND='MB'
ID = 'id'
NAME = 'name'
SUN = 10
MERCURY = 199
VENUS = 299
MOON = 301
EARTH = 399
MARS = 499
JUPITER = 599
SATURN = 699
URANUS = 799
NEPTUNE = 899

START_DATE = datetime.datetime(1900, 1, 1)
STOP_DATE = datetime.datetime(2100, 1, 1)

START_TOKEN = "$$SOE"
END_TOKEN = "$$EOE"

def nasa_url(planet, centre, start, stop):
    return f"https://ssd.jpl.nasa.gov/api/horizons.api?format=text&COMMAND='{planet}'&OBJ_DATA='NO'&MAKE_EPHEM='YES'&EPHEM_TYPE='VECTOR'&CENTER='@{centre}'&START_TIME='{start.year}-{start.month}-{start.day}'&STOP_TIME='{stop.year}-{stop.month}-{stop.day}'&STEP_SIZE='1d'&VEC_TABLE='1'"

def parse_line(line):
    try:
        m = re.match(r' X =(.*) Y =(.*) Z =.*', line)
        x = decimal.Decimal(m.group(1))
        y = decimal.Decimal(m.group(2))
        angle = decimal.Decimal(math.atan2(x, y))
        return float(angle.quantize(decimal.Decimal('1.00000')))
    except:
        print(f'oh no: {line}')

def planet_angles(planet, centre, start_date, stop_date):
    url = nasa_url(planet, centre, start_date, stop_date)

    resp = requests.get(url, headers={'User-Agent': 'https://github.com/tidbyt/community/tree/main/apps/planetarium'})
    resp.raise_for_status()

    content = resp.text
    section_start = content.find(START_TOKEN) + len(START_TOKEN) + 1
    section_end = content.find(END_TOKEN) - 1
    section = content[section_start:section_end].splitlines()
    
    return [parse_line(section[line_num]) for line_num in range(1, len(section), 2)]

results = [planet_angles(planet, SUN, START_DATE, STOP_DATE) for planet in [MERCURY, VENUS, EARTH, MARS, JUPITER, SATURN, URANUS, NEPTUNE]]

print(f'START_DATE = time.time(year={START_DATE.year}, month={START_DATE.month}, day={START_DATE.day})\n')
print('# List of lists, where ith list contains data for ith planet from the sun (Mercury = 0) and the jth member\n# of each list contains the angle from vertical in radians for the jth day since START_DATE inclusive.')
print(f'ANGLES = {results}')