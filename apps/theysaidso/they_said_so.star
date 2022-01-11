"""
Applet: They Said So
Summary: Quote of the Day
Description: Quote of the day powered by theysaidso.com.
Author: Henry So, Jr.
"""

# Quote Of the Day powered by theysaidso.com
#
# Copyright (c) 2022 Henry So, Jr.
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Note: this app is subject to theysaidso.com's public, rate-limited API

load('http.star', 'http')
load('render.star', 'render')
load('cache.star', 'cache')
load('encoding/base64.star', 'base64')
load('encoding/json.star', 'json')

URL = 'http://quotes.rest/qod.json?category='

WIDTH = 64
HEIGHT = 32

QUOTE_W = 22
QUOTE_H = 19
QUOTE_COLOR = '#555'

TEXT_OFFSET = 3
TEXT_COLOR = '#fff'

CITATION_COLOR = '#37f'
ATTRIBUTION_COLOR = '#484'

# subtract one extra for aesthetics
CLOSE_OFFSET = -(QUOTE_H - TEXT_OFFSET - TEXT_OFFSET - 1)

TTL = 60 * 60

CATEGORIES = [
    'inspire', # Inspiring Quote of the day
    'management', # Management Quote of the day
    'sports', # Sports Quote of the day
    'life', # Quote of the day about life
    'funny', # Funny Quote of the day
    'love', # Quote of the day about Love
    'art', # Art quote of the day
    'students', # Quote of the day for students
]

# Takes category (value from CATEGORIES)
def main(config):
    category = config.get('category') or 'fake'

    if category in CATEGORIES:
        key = 'qod:' + category
        content = cache.get(key)
        if content == None:
            #print("retrieving " + category)
            content = http.get(URL + category)
            if content.status_code == 200:
                content = content.json().get('contents', {}).get('quotes')
                # None and empty list are both falsy
                content = content[0] if content else {}
                content = {
                    'quote': content.get('quote'),
                    'author': content.get('author'),
                }
                cache.set(key, json.encode(content), TTL)
            else:
                #print('Server returned %s' % content.status_code)
                content = {
                    'quote': 'Forsooth, the server quoteth "%s".' % content.status_code,
                    'author': 'Anonymous',
                }
        else:
            #print("using cache for " + category)
            content = json.decode(content)
    else:
        content = {
            'quote': "Some say passing an invalid category will yield good results. I don't.",
            'author': 'Anonymous',
        }

    quote = content.get('quote') or "Strange, the API didn't return a quote."
    author = content.get('author') or 'Author Unknown'

    # try to adjust when the quote is too long
    delay = 100
    if len(quote) > 160:
        delay = 50
        if len(quote) > 320:
            quote = quote[0:(quote.rindex(' ', 0, 320))] + '...'

    # generate the widget for the app
    return render.Root(
        delay = delay,
        child = render.Marquee(
            height = HEIGHT,
            # offset it to give some time for the user to read the first line
            offset_start = 5,
            offset_end = 5,
            scroll_direction = 'vertical',
            child = render.Stack([
                render.Column(
                    children = [
                        # use this Padding to hackily measure the text
                        render.Padding(
                            pad = (0, CLOSE_OFFSET, 0, 0),
                            child = render.WrappedText(
                                content = quote,
                                width = WIDTH,
                                color = '#000',
                            ),
                        ),
                        render.Box(
                            width = QUOTE_W,
                            height = QUOTE_H,
                            color = QUOTE_COLOR,
                            child = render.Image(RQUOTE),
                        ),
                    ],
                    cross_align = 'end',
                ),
                render.Box(
                    width = QUOTE_W,
                    height = QUOTE_H,
                    color = QUOTE_COLOR,
                    child = render.Image(LQUOTE),
                ),
                render.Column([
                    render.Box(
                        width = WIDTH,
                        height = TEXT_OFFSET,
                    ),
                    render.WrappedText(
                        content = quote,
                        width = WIDTH,
                        color = TEXT_COLOR,
                    ),
                    render.WrappedText(
                        content = '— ' + author,
                        width = WIDTH,
                        color = CITATION_COLOR,
                    ),
                    render.Text(
                        content = 'theysaidso.com',
                        color = ATTRIBUTION_COLOR,
                    ),
                ]),
            ]),
        )
    )

def get_schema():
    categories = [
        { 'text': category, 'value': category }
        for category in CATEGORIES
    ]
    return [
        {
            'type': 'dropdown',
            'id': 'category',
            'name': 'Category',
            'icon': 'quoteRight',
            'description': 'The quote category to select from.',
            'options': categories,
            'default': 'inspire',
        },
    ]

LQUOTE = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABYAAAATAgMAAADpFxUbAAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAADlJREFUCNeVybENADAIA8GnSE/DPh4hjfdfJZA+RbDkkwzGZnc8JayhrNrM
q+ew4wUUZLO494kokQelgwyOl8+GjgAAAABJRU5ErkJggg==
""")
RQUOTE = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABYAAAATAgMAAADpFxUbAAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAADpJREFUCNeVyaERADEQQtFv8DHbDyUgsv23kk38iQPxZgBTZgHi5SdGHnqr
9xdRZ3C1F6HCZbbpXMoB+pgMpp7gufIAAAAASUVORK5CYII=
""")
