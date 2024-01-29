"""
Applet: Quotetopia
Summary: Quotetopia, Great Quotes
Description: This app gives a new cool, humorous, or inspiring quote of the day.
Author: Taylor White
"""

load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_REGULAR_FONT_MIN = 60
DEFAULT_LARGE_FONT_MIN = 52
DEFAULT_EXTRA_LARGE_FONT_MIN = 32

DEFAULT_AUTH_SMALL_FONT_MIN = 25
DEFAULT_AUTH_REGULAR_FONT_MIN = 15
DEFAULT_AUTH_LARGE_FONT_MIN = 8

font_options = [
    schema.Option(
        display = "tb-8",
        value = "tb-8",
    ),
    schema.Option(
        display = "Dina R400 6",
        value = "Dina_r400-6",
    ),
    schema.Option(
        display = "5x8",
        value = "5x8",
    ),
    schema.Option(
        display = "6x13",
        value = "6x13",
    ),
    schema.Option(
        display = "10x20",
        value = "10x20",
    ),
    schema.Option(
        display = "Tom Thumb",
        value = "tom-thumb",
    ),
    schema.Option(
        display = "3x5 Monospace",
        value = "CG-pixel-3x5-mono",
    ),
    schema.Option(
        display = "4x5 Monospace",
        value = "CG-pixel-4x5-mono",
    ),
]

DEFAULT_COLORS = [
    "#FFFFFF",  # White
    "#d94e6f",  # Rose
    "#FF6665",  # Blush
    "#ff9200",  # Tangerine
    "#f4c100",  # Golden
    "#69c300",  # Lime
    "#19c295",  # Mediterranean
    "#00bfd4",  # Caribbean
    "#24a4ee",  # Sky
    "#0091ea",  # Altitude
    #"#0085f2", # Azure
    "#6a4ce0",  # Wisteria
    "#b429cc",  # Dahlia
    "#dd299d",  # Fuchsia
]

DEFAULT_QUOTES = [
    {"quote": "The only way to do great work is to love what you do.", "author": "Steve Jobs"},
    {"quote": "In three words I can sum up everything I've learned about life: it goes on.", "author": "Robert Frost"},
    {"quote": "Believe you can and you're halfway there.", "author": "Theodore Roosevelt"},
    {"quote": "Nothing is as frustrating as arguing with someone who knows what he's talking about.", "author": "Sam Ewing"},
    {"quote": "At his best, man is the noblest of all animals; separated from law and justice, he is the worst.", "author": "Aristotle"},
    {"quote": "Give me a lever long enough, and I shall move the world.", "author": "Archimedes"},
    {"quote": "Whether you think you can or you think you can't, you're right.", "author": "Henry Ford"},
    {"quote": "Your work is going to fill a large part of your life, and the only way to be truly satisfied is to do what you believe is great work. And the only way to do great work is to love what you do. If you haven't found it yet, keep looking. Don't settle. As with all matters of the heart, you'll know when you find it.", "author": "Steve Jobs"},
    {"quote": "It takes 20 years to build a reputation and five minutes to ruin it.", "author": "Warren Buffett"},
    {"quote": "We hold these truths to be self-evident, that all men are created equal, that they are endowed by their Creator with certain unalienable Rights, that among these are Life, Liberty and the pursuit of Happiness.", "author": "Our Founding Fathers"},
    {"quote": "Chop your own wood, and it will warm you twice.", "author": "Henry Ford"},
    {"quote": "To avoid criticism say nothing, do nothing, be nothing.", "author": "Aristotle"},
    {"quote": "Veni, vidi, vici. (I came, I saw, I conquered.)", "author": "Gaius Julius Caesar"},
    {"quote": "Fall down seven times, stand up eight.", "author": "Japanese Proverb"},
    {"quote": "Energy and persistence conquer all things.", "author": "Benjamin Franklin"},
    {"quote": "Giving up smoking is the easiest thing in the world. I know because I've done it thousands of times.", "author": "Mark Twain"},
    {"quote": "A day without laughter is a day wasted.", "author": "Charlie Chaplin"},
    {"quote": "Learning is not attained by chance; it must be sought for with ardor and attended to with diligence.", "author": "Abigail Adams"},
    {"quote": "When one door closes, another door opens.", "author": "Italian Proverb"},
    {"quote": "The best way to predict the future is to invent it.", "author": "Xerox PARC Researchers"},
    {"quote": "No one can make you feel inferior without your consent.", "author": "Eleanor Roosevelt"},
    {"quote": "Understand -ing is a two-way street.", "author": "Eleanor Roosevelt"},
    {"quote": "The man who does not read has no advantage over the man who cannot read.", "author": "Mark Twain"},
    {"quote": "I know not with what weapons World War III will be fought, but World War IV will be fought with sticks and stones.", "author": "Albert Einstein"},
    {"quote": "The future cannot be predicted, but futures can be invented. It was man's ability to invent which has made human society what it is.", "author": "Dennis Gabor"},
    {"quote": "The two most important days in your life are the day you are born and the day you find out why.", "author": "Mark Twain"},
    {"quote": "No man is a failure who has friends.", "author": "Clarence the Angel"},
    {"quote": "If you tell the truth you don't have to remember anything.", "author": "Mark Twain"},
    {"quote": "The difference between the right word and the almost right word is the difference between lightning and a lightning bug.", "author": "Mark Twain"},
    {"quote": "Too many of us are not living our dreams because we are living our fears.", "author": "Les Brown"},
    {"quote": "You can cut all the flowers but you cannot keep Spring from coming.", "author": "Pablo Neruda"},
    {"quote": "Not everything that can be counted counts, and not everything that counts can be counted.", "author": "William Bruce Cameron"},
    {"quote": "Patience is bitter, but its fruit is sweet.", "author": "Aristotle"},
    {"quote": "Mankind must put an end to war, or war will put an end to mankind.", "author": "John F. Kennedy"},
    {"quote": "You can't build a reputation on what you are going to do.", "author": "Henry Ford"},
    {"quote": "Ask not what your country can do for you; ask what you can do for your country.", "author": "John F. Kennedy"},
    {"quote": "One more such victory and the cause is lost.", "author": "Pyrrus"},
    {"quote": "Where performance is measured, performance improves. Where performance is measured and reported, the rate of improvement accelerates.", "author": "Thomas S. Monson"},
    {"quote": "Come and take them.", "author": "King Leonidas to Xerxes"},
    {"quote": "In order to write about life, first you must live it.", "author": "Ernest Hemingway"},
    {"quote": "All truths are easy to understand once they are discovered; the point is to discover them.", "author": "Galileo Galilei"},
    {"quote": "Live in the sunshine, swim the sea, drink the wild air.", "author": "Ralph Waldo Emerson"},
    {"quote": "It takes a great deal of bravery to stand up to our enemies, but just as much to stand up to our friends.", "author": "J.K. Rowling"},
    {"quote": "Never cease to act because you fear you may fail.", "author": "Queen Liliuokalani"},
    {"quote": "Millions long for immortality who don't know what to do with themselves on a rainy Sunday afternoon.", "author": "Susan Ertz"},
    {"quote": "Which painting in the National Gallery would I save if there was a fire? The one nearest the door, of course.", "author": "George Bernard Shaw"},
    {"quote": "Where there's a will, there's a way.", "author": "English Proverb"},
    {"quote": "Whatever the mind of man can conceive and believe, it can achieve.", "author": "Napoleon Hill"},
    {"quote": "Life's tragedy is that we get old too soon and wise too late.", "author": "Benjamin Franklin"},
    {"quote": "Life is tough, and if you have the ability to laugh at it you have the ability to enjoy it.", "author": "Salma Hayek"},
    {"quote": "If your actions create a legacy that inspires others to dream more, learn more, do more and become more, then you are an excellent leader.", "author": "Dolly Parton"},
    {"quote": "Never let your sense of morals prevent you from doing what's right.", "author": "Isaac Asimov"},
    {"quote": "A ship in port is safe, but that's not what ships are built for.", "author": "Grace Hopper"},
    {"quote": "Genius is one percent inspiration, ninety-nine percent perspiration.", "author": "Thomas Edison"},
    {"quote": "If you have a garden and a library, you have everything you need.", "author": "Marcus Tullius Cicero"},
    {"quote": "You miss 100% of the shots you don't take.", "author": "Wayne Gretzky"},
    {"quote": "The price of apathy towards public affairs is to be ruled by evil men.", "author": "Plato"},
    {"quote": "Opportunity is missed by most people because it is dressed in overalls and looks like work.", "author": "Thomas Edison"},
    {"quote": "The best portion of a man's life consists of his little, nameless, unremembered acts of kindness and love.", "author": "Benjamin Franklin"},
    {"quote": "I've learned that people will forget what you said, people will forget what you did, but people will never forget how you made them feel.", "author": "Maya Angelou"},
    {"quote": "There are three ways to get something done: do it yourself, hire someone, or forbid your kids to do it.", "author": "Mona Crane"},
    {"quote": "One man with courage is a majority.", "author": "Andrew Jackson"},
    {"quote": "The secret to creativity is knowing how to hide your sources.", "author": "Albert Einstein"},
    {"quote": "We the People of the United States, in Order to form a more perfect Union, establish Justice, insure domestic Tranquility, provide for the common defense, promote the general Welfare, and secure the Blessings of Liberty to ourselves and our Posterity, do ordain and establish this Constitution for the United States of America.", "author": "U.S. Constitution"},
    {"quote": "Small opportunities are often the beginning of great enterprises.", "author": "Demosthenes"},
    {"quote": "If you owe the bank $100, that's your problem. If you owe the bank $100 million, that's the bank's problem.", "author": "Jean Paul Getty"},
    {"quote": "An eye for an eye makes the whole world blind.", "author": "Mahatma Gandhi"},
    {"quote": "He who cannot be a good follower cannot be a good leader.", "author": "Aristotle"},
    {"quote": "History will be kind to me, for I intend to write it.", "author": "Winston Churchill"},
    {"quote": "Where there is great power, there is great responsibility.", "author": "Winston Churchill"},
    {"quote": "Early to bed and early to rise makes a man healthy, wealthy, and wise.", "author": "Benjamin Franklin"},
    {"quote": "Be yourself; everyone else is already taken", "author": "Oscar Wilde"},
    {"quote": "Well done is better than well said.", "author": "Benjamin Franklin"},
    {"quote": "Never let the fear of striking out keep you from playing the game.", "author": "Babe Ruth"},
    {"quote": "Do not let making a living prevent you from making a life.", "author": "John Wooden"},
    {"quote": "The secret of success is to do the common thing uncommonly well.", "author": "ohn D. Rockefeller Jr."},
    {"quote": "I find that the harder I work, the more luck I seem to have.", "author": "Thomas Jefferson"},
    {"quote": "Leave nothing for tomorrow which can be done today.", "author": "Abraham Lincoln"},
    {"quote": "Twenty years from now you will be more disappointed by the things that you didn't do than by the ones you did do. So, throw off the bowlines, sail away from safe harbor, catch the trade winds in your sails. Explore, Dream, Discover.", "author": "Mark Twain"},
    {"quote": "Great minds discuss ideas; average minds discuss events; small minds discuss people.", "author": "Eleanor Roosevelt"},
]

DEFAULT_DURATION_IN_MINUTES = 1

DEFAULT_FONT = "tb-8"
DEFAULT_COLOR = "#FFFFFF"

def main(config):
    quote_color = config.str("quote_color", DEFAULT_COLOR)

    author_color = config.str("author_color", DEFAULT_COLOR)
    duration_in_minutes = int(config.str("duration_in_minutes", DEFAULT_DURATION_IN_MINUTES))
    current_timestamp = time.now().unix
    current_interval = (current_timestamp // (60 * duration_in_minutes))
    quote_index = current_interval % len(DEFAULT_QUOTES)

    if config.bool("randomize_colors"):
        quote_color = DEFAULT_COLORS[random.number(0, 12)]
        author_color = DEFAULT_COLORS[random.number(0, 12)]

    selected_quote_text = DEFAULT_QUOTES[quote_index % len(DEFAULT_QUOTES)]["quote"]
    selected_quote_author = DEFAULT_QUOTES[quote_index % len(DEFAULT_QUOTES)]["author"]

    if len(selected_quote_text) < DEFAULT_EXTRA_LARGE_FONT_MIN:
        quote_font = font_options[4].value  # "10x20"
    elif len(selected_quote_text) < DEFAULT_LARGE_FONT_MIN:
        quote_font = font_options[3].value  # "6x13"
    elif len(selected_quote_text) < DEFAULT_REGULAR_FONT_MIN:
        quote_font = font_options[0].value  # "tb-8"
    else:
        quote_font = DEFAULT_FONT

    if len(selected_quote_author) < DEFAULT_AUTH_LARGE_FONT_MIN:
        author_font = font_options[3].value  # "6x13"
    elif len(selected_quote_author) < DEFAULT_AUTH_REGULAR_FONT_MIN:
        author_font = font_options[0].value  # "tb-8"
    elif len(selected_quote_author) < DEFAULT_AUTH_SMALL_FONT_MIN:
        author_font = font_options[5].value  # "tom-thumb"
    else:
        author_font = font_options[5].value  # "tom-thumb"

    msg = render.WrappedText(selected_quote_text, font = quote_font, color = quote_color)
    author = render.WrappedText(selected_quote_author, font = author_font, color = author_color)
    author_box = render.Box(
        child = render.Box(
            child = render.Box(
                child = author,
                width = 48,
                height = 25,
                color = "#000000",
            ),
            height = 26,
            width = 50,
            color = "#FFFFFF",
            padding = 1,
        ),
        color = "#000000",
        padding = 1,
    )

    author_box_animation_short = get_frames(author_box, 30)
    author_box_animation = get_frames(author_box, 50)

    marquee = render.Marquee(
        height = 32,
        scroll_direction = "vertical",
        child = msg,
        offset_start = 30,
        offset_end = 30,
        align = "center",
    )

    marqueeWithPadding = render.Padding(
        child = marquee,
        pad = (2, 0, 0, 0),
    )

    sequence = render.Sequence(
        children = [author_box_animation_short, marqueeWithPadding, author_box_animation],
    )

    return render.Root(
        delay = 100,
        child = sequence,
        show_full_animation = True,
    )

def get_frames(child_widget, frame_count):
    widgets = []
    for _ in range(1, frame_count + 1):
        widgets.append(child_widget)

    return render.Animation(
        children = widgets,
    )

def get_schema():
    duration_in_minutes_options = [
        schema.Option(
            display = "Every minute",
            value = "1",
        ),
        schema.Option(
            display = "Every 5 minutes",
            value = "5",
        ),
        schema.Option(
            display = "Every hour",
            value = "60",
        ),
        schema.Option(
            display = "Every 6 hours",
            value = "360",
        ),
        schema.Option(
            display = "Every 12 hours",
            value = "720",
        ),
        schema.Option(
            display = "Every 24 hours",
            value = "1440",
        ),
        schema.Option(
            display = "Every week",
            value = "10080",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "duration_in_minutes",
                name = "Quote duration",
                desc = "Select the duration that a quote should be shown.",
                icon = "clock",
                options = duration_in_minutes_options,
                default = duration_in_minutes_options[1].value,
            ),
            schema.Toggle(
                id = "randomize_colors",
                name = "Randomize Colors",
                desc = "Ignore the color settings and randomize them instead.",
                icon = "shuffle",
                default = True,
            ),
            schema.Color(
                id = "quote_color",
                name = "Quote Color",
                desc = "Color of the quote text",
                icon = "brush",
                default = "#0091ea",
                palette = DEFAULT_COLORS,
            ),
            schema.Color(
                id = "author_color",
                name = "Author Color",
                desc = "Color of the author text",
                icon = "brush",
                default = "#19c295",
                palette = DEFAULT_COLORS,
            ),
        ],
    )
