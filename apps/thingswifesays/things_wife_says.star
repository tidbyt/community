"""
Applet: Things Wife Says
Summary: Show phrases
Description: Enter phrases your wife says and app will cycle through them.
Author: vipulchhajer
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")

PHRASES = [
    "It's fineee",
    "Is it really tho?",
    "That's hella tight",
    "I'm gonna sleep in",
    "I'm taking a short nap mmmkay?",
]

#Load images
WOMAN_ICON = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABwAAAAcCAYAAAByDd+UAAAAAXNSR0IArs4c6QAAAXZJREFUSEvNlq0OAjEMgHcPgQAH4iyKN8ASFBJHUAgUr0CCQqAIjicgJCjeAIVFgAPBQxzpwpberu16ByHM3HEt/fq3bon58UqUvEypF7UXVTDGZGkztbzL7UJyA7loUxJaEEDcU4qScIq0LQKVacypIed+AwT6G6oG5hrkftyYRndkwicYhm94gR6zPDz0wteNMqhNcQDOMQphp800g0bB3tcfNct61J8kk5IjaDkgGEuGfQvKtrsClJNXBrr6ARC/u1A5uRboaxg2hLZ+2JH3u5xSyNwnDUMA4RPbpbZUXwaKEfo9SKV0312Z3nHisxv+ZvakLqVclABxC8MjA0BOqZuHXJQlgfEI8elQtlvxlKEGOTVg/fkHkYRTR9oe4SylhjgJdBPfATGEipgb2qWB1AmvBaIDOV7D6frMZm7WOhVki2un8O0wH7griQycrs/RCxOGUjBMX47bnwPBIEBjMND7GlA7zP8PqPW8qp7mIlzVNvm/F7LJ0x29lys8AAAAAElFTkSuQmCC")

def main(config):
    PHRASES = [
        config.str("phrase1"),
        config.str("phrase2"),
        config.str("phrase3"),
        config.str("phrase4"),
        config.str("phrase5"),
    ]

    index_cached = cache.get("array_index")
    if index_cached != None:
        print("Hit! Displaying cached data.")
        index = int(index_cached)
    else:
        print("Miss! Calling random.org API.")

        # Alt way to generate random number, learned from https://github.com/savetz/tidbyt-conways-game-of-life/blob/main/life-pretty.star
        resp = http.get("https://www.random.org/integers/?num=1&min=0&max=4&col=1&base=10&format=plain&rnd=new")
        if resp.status_code != 200:
            fail("Request failed with status %d", resp.status_code)
        random_index = resp.body()
        random_index = re.sub("\n", "", random_index)  #squish the numbers into a string of digits
        index = int(random_index)
        cache.set("array_index", str(int(index)), ttl_seconds = 60)
    phrase = PHRASES[index]

    return render.Root(
        child = render.Box(
            child = render.Row(
                main_align = "center",
                cross_align = "center",
                expanded = True,
                children = [
                    render.Box(
                        color = "#f3f6f4",  #remove color background if picture is used
                        child = render.Image(src = WOMAN_ICON),
                        width = 28,
                        height = 28,
                    ),
                    render.Box(
                        child = render.Marquee(
                            height = 16,
                            offset_start = 6,
                            offset_end = 6,
                            child = render.WrappedText(
                                content = phrase,
                                width = 30,
                                # color="#f44336"
                            ),
                            scroll_direction = "vertical",
                        ),
                        width = 34,
                        height = 32,
                        padding = 2,
                    ),
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "phrase1",
                name = "phrase 1",
                desc = "a thing your wife says",
                icon = "faceSmile",
            ),
            schema.Text(
                id = "phrase2",
                name = "phrase 2",
                desc = "another thing your wife says",
                icon = "faceSmile",
            ),
            schema.Text(
                id = "phrase3",
                name = "phrase 3",
                desc = "third thing your wife says",
                icon = "faceSmile",
            ),
            schema.Text(
                id = "phrase4",
                name = "phrase 4",
                desc = "fourth thing your wife says",
                icon = "faceSmile",
            ),
            schema.Text(
                id = "phrase5",
                name = "phrase 5",
                desc = "fifth thing your wife says",
                icon = "faceSmile",
            ),
        ],
    )
