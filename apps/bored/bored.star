"""
Applet: Bored
Summary: Things to do when bored
Description: This app will suggest things you can do when you are bored.
Author: Anders Heie
"""

load("cache.star", "cache")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

# Global defines
DEFAULT_COLOR = "#FF00FF"
DEFAULT_FONT = "6x13"
DEFAULT_DIRECTION = "vertical"

# Hardcoded list of activities with effort levels (0.0 = very easy, 1.0 = very hard)
# Pre-shuffled to provide variety in sequential order
BORED_ACTIVITIES = [
    {"activity": "Scream at a mountain", "effort": 0.8},
    {"activity": "Listen to music from a decade you weren't alive in", "effort": 0.1},
    {"activity": "Try a new recipe", "effort": 0.6},
    {"activity": "Convince your reflection it's wrong", "effort": 0.5},
    {"activity": "Count birds you can see", "effort": 0.2},
    {"activity": "Read poetry aloud", "effort": 0.4},
    {"activity": "Browse through a dictionary for new words", "effort": 0.3},
    {"activity": "Learn about a historical event", "effort": 0.5},
    {"activity": "Read the news from another country", "effort": 0.3},
    {"activity": "Study constellations and star patterns", "effort": 0.6},

    # Cooking & Food
    {"activity": "Try a new recipe", "effort": 0.6},
    {"activity": "Bake cookies or bread", "effort": 0.7},
    {"activity": "Make homemade pizza", "effort": 0.8},
    {"activity": "Experiment with spices you never use", "effort": 0.4},
    {"activity": "Try cooking a dish from another culture", "effort": 0.8},
    {"activity": "Make smoothies with unusual combinations", "effort": 0.3},
    {"activity": "Learn to fold fancy napkins", "effort": 0.5},
    {"activity": "Organize your spice rack", "effort": 0.4},
    {"activity": "Make tea blends from scratch", "effort": 0.5},
    {"activity": "Try eating with your non-dominant hand", "effort": 0.2},

    # Physical Activities
    {"activity": "Take a walk outside", "effort": 0.4},
    {"activity": "Do some stretching or yoga", "effort": 0.5},
    {"activity": "Dance to your favorite music", "effort": 0.6},
    {"activity": "Do jumping jacks for 2 minutes", "effort": 0.7},
    {"activity": "Try balancing on one foot with eyes closed", "effort": 0.3},
    {"activity": "Do wall push-ups", "effort": 0.6},
    {"activity": "Practice walking backwards", "effort": 0.3},
    {"activity": "Stretch like a cat", "effort": 0.2},
    {"activity": "Do breathing exercises", "effort": 0.2},
    {"activity": "Try standing on your head", "effort": 0.8},

    # Social & Communication
    {"activity": "Call a friend or family member", "effort": 0.3},
    {"activity": "Write a letter to someone you miss", "effort": 0.5},
    {"activity": "Send a funny meme to a friend", "effort": 0.1},
    {"activity": "Compliment a stranger online", "effort": 0.2},
    {"activity": "Write thank you notes", "effort": 0.4},
    {"activity": "Practice conversation starters", "effort": 0.3},
    {"activity": "Record a voice memo for future you", "effort": 0.2},
    {"activity": "Leave positive reviews for businesses you like", "effort": 0.3},
    {"activity": "Text someone you haven't talked to in months", "effort": 0.4},
    {"activity": "Practice different accents", "effort": 0.5},

    # Creative & Artistic
    {"activity": "Write in a journal", "effort": 0.3},
    {"activity": "Draw something you see around you", "effort": 0.4},
    {"activity": "Write a haiku about your day", "effort": 0.5},
    {"activity": "Make up a story about your pet", "effort": 0.4},
    {"activity": "Design your dream house on paper", "effort": 0.6},
    {"activity": "Create art using only office supplies", "effort": 0.7},
    {"activity": "Write a song parody", "effort": 0.8},
    {"activity": "Make a collage from magazines", "effort": 0.5},
    {"activity": "Practice origami", "effort": 0.6},
    {"activity": "Invent a new superhero", "effort": 0.4},

    # Organization & Productivity
    {"activity": "Organize a room or drawer", "effort": 0.6},
    {"activity": "Clean out your email inbox", "effort": 0.7},
    {"activity": "Organize your photos", "effort": 0.8},
    {"activity": "Make a bucket list", "effort": 0.3},
    {"activity": "Plan your ideal vacation", "effort": 0.5},
    {"activity": "Reorganize your bookshelf", "effort": 0.5},
    {"activity": "Clean your computer desktop", "effort": 0.4},
    {"activity": "Update your resume", "effort": 0.8},
    {"activity": "Organize your closet by color", "effort": 0.6},
    {"activity": "Create a meal plan for next week", "effort": 0.5},

    # Technology & Digital
    {"activity": "Learn something new online", "effort": 0.4},
    {"activity": "Update all your apps", "effort": 0.2},
    {"activity": "Backup your important files", "effort": 0.5},
    {"activity": "Learn keyboard shortcuts", "effort": 0.6},
    {"activity": "Customize your phone wallpaper", "effort": 0.2},
    {"activity": "Unsubscribe from unnecessary emails", "effort": 0.3},
    {"activity": "Learn a new app or software", "effort": 0.7},
    {"activity": "Create a playlist for different moods", "effort": 0.3},
    {"activity": "Research your family tree", "effort": 0.6},
    {"activity": "Take a virtual museum tour", "effort": 0.2},

    # Nature & Outdoors
    {"activity": "Look at clouds and find shapes", "effort": 0.1},
    {"activity": "Start a small herb garden", "effort": 0.7},
    {"activity": "Watch birds outside your window", "effort": 0.1},
    {"activity": "Collect interesting leaves or rocks", "effort": 0.3},
    {"activity": "Stargaze and identify constellations", "effort": 0.4},
    {"activity": "Watch a sunrise or sunset", "effort": 0.2},
    {"activity": "Create a nature journal", "effort": 0.5},
    {"activity": "Feed the birds in your yard", "effort": 0.3},
    {"activity": "Take photos of flowers", "effort": 0.2},
    {"activity": "Listen to nature sounds", "effort": 0.1},

    # Games & Puzzles
    {"activity": "Work on a puzzle or brain teaser", "effort": 0.4},
    {"activity": "Play solitaire with real cards", "effort": 0.3},
    {"activity": "Create your own word search", "effort": 0.6},
    {"activity": "Play 20 questions with yourself", "effort": 0.2},
    {"activity": "Try to solve a Rubik's cube", "effort": 0.9},
    {"activity": "Play online chess", "effort": 0.6},
    {"activity": "Create riddles for friends", "effort": 0.5},
    {"activity": "Learn card tricks", "effort": 0.7},
    {"activity": "Play trivia games online", "effort": 0.3},
    {"activity": "Invent a new board game", "effort": 0.9},

    # Silly & Random
    {"activity": "Practice your Oscar acceptance speech", "effort": 0.2},
    {"activity": "Pretend you're a nature documentary narrator", "effort": 0.3},
    {"activity": "Have a conversation with your reflection", "effort": 0.1},
    {"activity": "Try to lick your elbow", "effort": 0.1},
    {"activity": "Practice your evil villain laugh", "effort": 0.2},
    {"activity": "Make faces at yourself in the mirror", "effort": 0.1},
    {"activity": "Pretend the floor is lava", "effort": 0.2},
    {"activity": "Try to wiggle your ears", "effort": 0.1},
    {"activity": "Practice walking like different animals", "effort": 0.3},
    {"activity": "Make up new words and definitions", "effort": 0.4},
    {"activity": "Protest Donald Trump", "effort": 0.8},

    # Self-Care & Mindfulness
    {"activity": "Take a relaxing bath or shower", "effort": 0.3},
    {"activity": "Practice meditation for 10 minutes", "effort": 0.4},
    {"activity": "Do a face mask or skincare routine", "effort": 0.4},
    {"activity": "Practice gratitude - list 5 good things", "effort": 0.2},
    {"activity": "Give yourself a hand massage", "effort": 0.2},
    {"activity": "Practice positive affirmations", "effort": 0.3},
    {"activity": "Try progressive muscle relaxation", "effort": 0.5},
    {"activity": "Boycott Tesla", "effort": 0.6},
    {"activity": "Sit quietly and just breathe", "effort": 0.1},
    {"activity": "Hug a pillow or stuffed animal", "effort": 0.1},
    {"activity": "Listen to calming music with eyes closed", "effort": 0.1},

    # Silly & Absurd Activities
    {"activity": "Argue with JD Vance about a couch", "effort": 0.3},
    {"activity": "Scream at a mountain", "effort": 0.8},
    {"activity": "Disbelieve a giraffe", "effort": 0.2},
    {"activity": "Apologize to your houseplants", "effort": 0.2},
    {"activity": "Have a staring contest with your pet", "effort": 0.1},
    {"activity": "Sing the alphabet backwards", "effort": 0.4},
    {"activity": "Pretend you're a nature documentary narrator", "effort": 0.3},
    {"activity": "Convince your reflection it's wrong", "effort": 0.5},
    {"activity": "Write a strongly worded letter to gravity", "effort": 0.4},
    {"activity": "Practice your acceptance speech for an award you'll never win", "effort": 0.3},
    {"activity": "Debate the philosophical implications of socks", "effort": 0.6},
    {"activity": "Create conspiracy theories about your neighbors' mailbox", "effort": 0.4},
    {"activity": "Impersonate a robot having an existential crisis", "effort": 0.5},
    {"activity": "Try to teach your shadow to dance", "effort": 0.3},
    {"activity": "Have a formal conversation with a banana", "effort": 0.2},
    {"activity": "Pretend you're allergic to the color blue", "effort": 0.3},
    {"activity": "Write haikus about your left shoe", "effort": 0.4},
    {"activity": "Apologize to every door you've ever slammed", "effort": 0.6},
    {"activity": "Practice being disappointed in a cloud", "effort": 0.2},
    {"activity": "Explain WiFi to a medieval peasant", "effort": 0.5},
    {"activity": "Have an argument with a calculator about math", "effort": 0.3},
    {"activity": "Pretend you're a spy but really bad at it", "effort": 0.4},
    {"activity": "Convince yourself that Wednesday is actually Thursday", "effort": 0.4},
    {"activity": "Write a breakup letter to your least favorite vegetable", "effort": 0.3},
    {"activity": "Practice your evil villain laugh", "effort": 0.2},
    {"activity": "Have a tea party with imaginary celebrities", "effort": 0.3},
    {"activity": "Pretend you're stuck in an invisible box", "effort": 0.4},
    {"activity": "Write reviews for things that don't exist", "effort": 0.5},
    {"activity": "Have a philosophical debate with your toaster", "effort": 0.3},
    {"activity": "Pretend you're a contestant on a game show about cereal", "effort": 0.4},
    {"activity": "Practice being surprised by your own reflection", "effort": 0.2},
    {"activity": "Write an angry letter to the inventor of Mondays", "effort": 0.3},
    {"activity": "Pretend you're a food critic reviewing air", "effort": 0.4},
    {"activity": "Have a heated discussion with a rubber duck about economics", "effort": 0.5},
    {"activity": "Practice your superhero landing in slow motion", "effort": 0.3},
    {"activity": "Convince yourself that you're actually a time traveler", "effort": 0.4},
    {"activity": "Write a manifesto about the superiority of forks over spoons", "effort": 0.5},
    {"activity": "Pretend you're being interviewed about your sock-matching technique", "effort": 0.3},
    {"activity": "Have a staring contest with a clock", "effort": 0.2},
    {"activity": "Practice your Oscar acceptance speech for 'Best Human'", "effort": 0.3},
]

def main(config):
    # Cache key for tracking which activity to show next
    cache_key = "bored_activity_index"

    # Get current activity index from cache
    activity_index = cache.get(cache_key)
    if activity_index == None:
        # Start at a random position in the list instead of always starting at 0
        activity_index = random.number(0, len(BORED_ACTIVITIES) - 1)

        # Cache the random starting position immediately
        cache.set(cache_key, str(activity_index), ttl_seconds = 3600)
        print("Starting at random activity index: " + str(activity_index))
    else:
        activity_index = int(activity_index)
        print("Retrieved activity index: " + str(activity_index))

    # Pre-analyze custom settings for personal activities
    custom_bored = []
    if config.get("personal1", "").strip() != "":
        custom_bored.append(config.get("personal1", "").strip())
    if config.get("personal2", "").strip() != "":
        custom_bored.append(config.get("personal2", "").strip())
    if config.get("personal3", "").strip() != "":
        custom_bored.append(config.get("personal3", "").strip())
    if config.get("personal4", "").strip() != "":
        custom_bored.append(config.get("personal4", "").strip())
    if config.get("personal5", "").strip() != "":
        custom_bored.append(config.get("personal5", "").strip())
    if config.get("personal6", "").strip() != "":
        custom_bored.append(config.get("personal6", "").strip())
    if config.get("personal7", "").strip() != "":
        custom_bored.append(config.get("personal7", "").strip())
    if config.get("personal8", "").strip() != "":
        custom_bored.append(config.get("personal8", "").strip())
    if config.get("personal9", "").strip() != "":
        custom_bored.append(config.get("personal9", "").strip())
    if config.get("personal10", "").strip() != "":
        custom_bored.append(config.get("personal10", "").strip())

    hasPersonalized = len(custom_bored) > 0
    print("Found personalized activities: " + str(len(custom_bored)))

    # Determine which activity list to use and select activity
    effort_level = 0.5  # Default effort level for personal activities
    if hasPersonalized:
        # Check if we should show personal activities
        chance = int(config.get("personalized_chance", "50"))  # Increased default to 50%
        if chance > random.number(0, 99):
            # Use personal activities
            activity = custom_bored[random.number(0, len(custom_bored) - 1)]
            effort_level = 0.5  # Assume medium effort for personal activities
            print("Using personal activity: " + activity)
        else:
            # Use hardcoded activities with cycling
            activity_data = BORED_ACTIVITIES[activity_index]
            activity = activity_data["activity"]
            effort_level = activity_data["effort"]
            activity_index = (activity_index + 1) % len(BORED_ACTIVITIES)
            cache.set(cache_key, str(activity_index), ttl_seconds = 3600)  # Cache for 1 hour
            print("Using hardcoded activity: " + activity)
    else:
        # Use hardcoded activities with cycling
        activity_data = BORED_ACTIVITIES[activity_index]
        activity = activity_data["activity"]
        effort_level = activity_data["effort"]
        activity_index = (activity_index + 1) % len(BORED_ACTIVITIES)
        cache.set(cache_key, str(activity_index), ttl_seconds = 3600)  # Cache for 1 hour
        print("Using hardcoded activity: " + activity)

    color = config.get("color", DEFAULT_COLOR)
    font = config.get("font", DEFAULT_FONT)

    # Create the effort meter with smooth gradient
    def create_effort_meter(effort):
        # Meter dimensions
        meter_width = 50
        meter_height = 4
        indicator_pos = int(effort * (meter_width - 2)) + 1

        # Create very smooth gradient with many more color steps
        gradient_colors = [
            "#00FF00",  # Pure green
            "#19FF00",
            "#33FF00",
            "#4CFF00",
            "#66FF00",
            "#7FFF00",
            "#99FF00",
            "#B2FF00",
            "#CCFF00",
            "#E5FF00",
            "#FFFF00",  # Pure yellow (middle)
            "#FFE500",
            "#FFCC00",
            "#FFB200",
            "#FF9900",
            "#FF7F00",
            "#FF6600",
            "#FF4C00",
            "#FF3300",
            "#FF1900",
            "#FF0000",  # Pure red
        ]

        gradient_segments = []
        for i in range(meter_width):
            # Map pixel position to color array index
            color_index = int((float(i) / float(meter_width - 1)) * (len(gradient_colors) - 1))
            segment_color = gradient_colors[color_index]

            gradient_segments.append(
                render.Padding(
                    pad = (i, 0, 0, 0),
                    child = render.Box(
                        width = 1,
                        height = meter_height,
                        color = segment_color,
                    ),
                ),
            )

        meter_content = render.Stack(
            children = gradient_segments + [
                # Indicator line (white vertical line)
                render.Padding(
                    pad = (indicator_pos, 0, 0, 0),
                    child = render.Box(
                        width = 1,
                        height = meter_height + 2,
                        color = "#FFFFFF",
                    ),
                ),
            ],
        )

        # Add "effort" label above the meter
        return render.Column(
            children = [
                render.Box(
                    width = meter_width,
                    height = 8,
                    child = render.Text(
                        "effort",
                        font = "tb-8",
                        color = "#FFFFFF",
                    ),
                ),
                meter_content,
            ],
        )

    # Create the main content area
    if config.get("direction", DEFAULT_DIRECTION) == "horizontal":
        main_content = render.Box(
            height = 18,  # Leave room for effort meter and larger label
            child = render.Marquee(
                width = 64,
                child = render.Text(activity, color = color, font = font),
                offset_start = 35,
                offset_end = 35,
            ),
        )
    else:
        # If we scroll vertically, we need smaller fonts to avoid long words being cut off at the sides
        if font != "tom-thumb" or font != "tb-8":
            font = "tb-8"

        main_content = render.Box(
            height = 18,  # Leave room for effort meter and larger label
            child = render.Marquee(
                height = 18,
                child = render.WrappedText(
                    content = activity,
                    color = color,
                    width = 64,
                    font = font,
                    align = "center",
                ),
                offset_start = 5,
                offset_end = 5,
                scroll_direction = "vertical",
            ),
        )

    # Create effort meter labels
    effort_labels = render.Row(
        expanded = True,
        main_align = "space_between",
        children = [
            render.Text("Easy", font = "tom-thumb", color = "#888888"),
            render.Text("Hard", font = "tom-thumb", color = "#888888"),
        ],
    )

    # Combine everything
    display_content = render.Column(
        children = [
            main_content,
            render.Padding(
                pad = (7, 1, 7, 0),  # Center the meter with some padding
                child = create_effort_meter(effort_level),
            ),
            render.Padding(
                pad = (2, 1, 2, 0),
                child = effort_labels,
            ),
        ],
    )

    return render.Root(
        delay = int(config.get("speed", 45)),
        child = display_content,
    )

def get_schema():
    color_options = [
        schema.Option(
            display = "Pink",
            value = "#FF94FF",
        ),
        schema.Option(
            display = "Mustard",
            value = "#FFD10D",
        ),
        schema.Option(
            display = "Blue",
            value = "#0000FF",
        ),
        schema.Option(
            display = "Red",
            value = "#FF0000",
        ),
        schema.Option(
            display = "Green",
            value = "#00FF00",
        ),
        schema.Option(
            display = "Purple",
            value = "#FF00FF",
        ),
        schema.Option(
            display = "Cyan",
            value = "#00FFFF",
        ),
        schema.Option(
            display = "White",
            value = "#FFFFFF",
        ),
    ]

    speed_options = [
        schema.Option(
            display = "Slow Scroll",
            value = "60",
        ),
        schema.Option(
            display = "Medium Scroll",
            value = "45",
        ),
        schema.Option(
            display = "Fast Scroll",
            value = "30",
        ),
    ]

    font_options = [
        schema.Option(
            display = "Tiny",
            value = "tom-thumb",
        ),
        schema.Option(
            display = "Small",
            value = "tb-8",
        ),
        schema.Option(
            display = "Medium (horizontal only)",
            value = "6x13",
        ),
        schema.Option(
            display = "Huge (Horizontal only)",
            value = "10x20",
        ),
    ]

    direction_options = [
        schema.Option(
            display = "Horizontal scroll",
            value = "horizontal",
        ),
        schema.Option(
            display = "Vertical scroll",
            value = "vertical",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "color",
                name = "Text Color",
                desc = "The color of text to be displayed.",
                icon = "brush",
                default = color_options[0].value,
                options = color_options,
            ),
            schema.Dropdown(
                id = "font",
                name = "Font size",
                desc = "Size of font",
                icon = "brush",
                default = font_options[0].value,
                options = font_options,
            ),
            schema.Dropdown(
                id = "direction",
                name = "Scroll direction",
                desc = "Direction to scroll if text too long",
                icon = "brush",
                default = direction_options[0].value,
                options = direction_options,
            ),
            schema.Dropdown(
                id = "speed",
                name = "Scroll Speed",
                desc = "Scrolling speed",
                icon = "gear",
                default = speed_options[1].value,
                options = speed_options,
            ),
            schema.Toggle(
                id = "scroll",
                name = "Try to finish?",
                desc = "Keep scrolling text even if it's longer than app-rotation time",
                icon = "user",
                default = True,
            ),
            schema.Text(
                id = "personalized_chance",
                name = "% Chance of showing",
                desc = "Number from 0-100 indicating the percentage chance that the custom things below are shown",
                icon = "user",
                default = "50",
            ),
            schema.Text(
                id = "personal1",
                name = "First thing to do",
                desc = "Optional: Enter a thing to do",
                icon = "user",
                default = "",
            ),
            schema.Text(
                id = "personal2",
                name = "Second thing to do",
                desc = "Optional: Enter a thing to do",
                icon = "user",
                default = "",
            ),
            schema.Text(
                id = "personal3",
                name = "Third thing to do",
                desc = "Optional: Enter a thing to do",
                icon = "user",
                default = "",
            ),
            schema.Text(
                id = "personal4",
                name = "Fourth thing to do",
                desc = "Optional: Enter a thing to do",
                icon = "user",
                default = "",
            ),
            schema.Text(
                id = "personal5",
                name = "Fifth thing to do",
                desc = "Optional: Enter a thing to do",
                icon = "user",
                default = "",
            ),
            schema.Text(
                id = "personal6",
                name = "Sixth thing to do",
                desc = "Optional: Enter a thing to do",
                icon = "user",
                default = "",
            ),
            schema.Text(
                id = "personal7",
                name = "Seventh thing to do",
                desc = "Optional: Enter a thing to do",
                icon = "user",
                default = "",
            ),
            schema.Text(
                id = "personal8",
                name = "Eighth thing to do",
                desc = "Optional: Enter a thing to do",
                icon = "user",
                default = "",
            ),
            schema.Text(
                id = "personal9",
                name = "Nineth thing to do",
                desc = "Optional: Enter a thing to do",
                icon = "user",
                default = "",
            ),
            schema.Text(
                id = "personal10",
                name = "Tenth thing to do",
                desc = "Optional: Enter a thing to do",
                icon = "user",
                default = "",
            ),
        ],
    )
