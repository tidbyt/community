"""
Applet: Bible VOTD
Summary: Shows a daily bible verse
Description: Shows a bible verse on a daily cadence.
Author: github.com/danrods
"""

# Bible Verse of the Day App
#
# Copyright (c) 2022 Dan Rodrigues
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
#
#

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")

# https://ourmanna.readme.io/reference/get-verse-of-the-day
VOTD_URL = "https://beta.ourmanna.com/api/v1/get?format=json"

BIBLE_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAkAAAAJCAYAAADgkQYQAAAALklEQVQYlWNgYGD4jw8wMDD8Z4ApgnJQME5FONgIDro15JtEtCKiHI5XEb5wAgAK2rZKrYeFRwAAAABJRU5ErkJggg==
""")

ABBREV_LOOKUP = json.decode("{\"Genesis\":\"Gen.\",\"Exodus\":\"Ex.\",\"Leviticus\":\"Lev.\",\"Numbers\":\"Num.\",\"Deuteronomy\":\"Dt.\",\"Joshua\":\"Josh.\",\"Judges\":\"Judg.\",\"Ruth\":\"Ruth\",\"1 Samuel\":\"1 S.\",\"2 Samuel\":\"2 S.\",\"1 Kings\":\"1 K.\",\"2 Kings\":\"2 K.\",\"1 Chronicles\":\"1 Chr.\",\"2 Chronicles\":\"2 Chr.\",\"Ezra\":\"Ezra\",\"Nehemiah\":\"Neh.\",\"Esther\":\"Esth.\",\"Job\":\"Job\",\"Psalms\":\"Ps.\",\"Proverbs\":\"Prov.\",\"Ecclesiastes\":\"Eccl.\",\"Song of Solomon\":\"S. S.\",\"Isaiah\":\"Is.\",\"Jeremiah\":\"Jer.\",\"Lamentations\":\"Lam.\",\"Ezekiel\":\"Ezek.\",\"Daniel\":\"Dan.\",\"Hosea\":\"Hos.\",\"Joel\":\"Joel\",\"Amos\":\"Am.\",\"Obadiah\":\"Obad.\",\"Jonah\":\"Jon.\",\"Micah\":\"Mic.\",\"Nahum\":\"Nah.\",\"Habakkuk\":\"Hab.\",\"Zephaniah\":\"Zeph.\",\"Haggai\":\"Hag.\",\"Zechariah\":\"Zech.\",\"Malachi\":\"Mal.\",\"Matthew\":\"Mt.\",\"Mark\":\"Mk.\",\"Luke\":\"Lk.\",\"John\":\"Jn.\",\"Acts\":\"Acts\",\"Romans\":\"Rom.\",\"1 Corinthians\":\"1 Cor.\",\"2 Corinthians\":\"2 Cor.\",\"Galatians\":\"Gal.\",\"Ephesians\":\"Eph.\",\"Philippians\":\"Phil.\",\"Colossians\":\"Col.\",\"1 Thessalonians\":\"1 Th.\",\"2 Thessalonians\":\"2 Th.\",\"1 Timothy\":\"1 Tim.\",\"2 Timothy\":\"2 Tim.\",\"Titus\":\"Tit.\",\"Philemon\":\"Philem.\",\"Hebrews\":\"Heb.\",\"James\":\"Jas.\",\"1 Peter\":\"1 Pet.\",\"2 Peter\":\"2 Pet.\",\"1 John\":\"1 Jn.\",\"2 John\":\"2 Jn.\",\"3 John\":\"3 Jn.\",\"Jude\":\"Jude\",\"Revelation\":\"Rev.\"}")

#
# Needed to shorten the reference or will overflow the label
#
def getFormattedVerseRef(ref):
    print("Getting pretty verse for ref %s" % ref)

    for k in ABBREV_LOOKUP:
        v = ABBREV_LOOKUP[k]
        matches = re.findall(k, ref, 0)

        if (len(matches) > 0 and all(matches)):
            return re.sub(k, v, ref, 1, 0)

    return ref

def main():
    print("~~~~~~~~~Starting App! ~~~~~~~~~~")

    bible_votd = None
    cached_verse = cache.get("bible_votd")
    if cached_verse != None:
        bible_votd = json.decode(cached_verse)
        print("Hit! Displaying cached verse.")
    else:
        print("Miss! Calling VOTD API.")
        rep = http.get(VOTD_URL)
        if rep.status_code != 200:
            fail("API request failed with status %d", rep.status_code)

        print("Got response: %s" % rep.json())

        verseDetails = rep.json()["verse"]["details"]
        verse = verseDetails["text"]

        ref = getFormattedVerseRef(verseDetails["reference"])

        bible_votd = {"ref": ref, "verse": verse}

        cache.set("bible_votd", json.encode(bible_votd), ttl_seconds = 86400)

    verse_text = bible_votd["verse"]
    ref_label = bible_votd["ref"]

    # Empirically the box length should be roughly double the number of characters to fit nicely in the screen
    box_height = 2 * len(verse_text)

    return render.Root(
        delay = 70,
        child = render.Column(
            expanded = True,
            cross_align = "end",
            main_align = "center",
            children = [
                render.Box(
                    height = 22,
                    child = render.Marquee(
                        width = 64,
                        height = 23,
                        offset_start = 0,
                        child = render.Box(
                            height = box_height,
                            padding = 3,
                            child = render.WrappedText(
                                content = verse_text,
                                color = "#fff",
                                font = "6x13",
                            ),
                        ),
                        scroll_direction = "vertical",
                    ),
                ),
                render.Box(
                    height = 1,
                    color = "#099",
                ),
                render.Row(
                    main_align = "start",
                    cross_align = "center",
                    children = [
                        render.Image(
                            height = 9,
                            width = 9,
                            src = BIBLE_ICON,
                        ),
                        render.Box(
                            height = 9,
                            width = 55,
                            child = render.Text(content = "%s" % ref_label, color = "#fff", font = "tom-thumb"),
                        ),
                    ],
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )
