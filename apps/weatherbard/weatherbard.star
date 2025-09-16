# Applet: Weatherbard
# Summary: Weather + Poem
# Description: Shows current weather and a poetic line in the style of Mary Oliver.
# Author: mgtkach

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("time.star", "time")

ENCRYPTED_API_KEY = "AV6+xWcEyGZAXJz6fIH2xJDhQ8MparbbAKoATMOWWwXDzXhcUnLkMH6GckSJ70dfic09fJtFicDThu5qnhA4dwLTtYqBfSAMkJ9ccPq9mPvOUdD27DZQ5lJQ0xe4/H4amEvUl/01ev993RUQO6Qbew76RzHUe39ZyQd+4jrsWsNNbDOYZz0="

poems = {
    "clear": [
        "The sun spills gold across the quiet field.",
        "All things stretch toward light and call it good.",
        "No curtain today between earth and sky.",
        "Each petal, lifting, receives the sun’s secret.",
        "The meadow wears sunlight like a shawl.",
        "Under a bright sky, the stones sing.",
        "The morning opens its palms to the sun.",
        "I wake into the hush of a golden day.",
        "Each leaf praises the morning in silence.",
        "Even the shadows are kind when the sky is clear.",
        "The breeze lifts the grasses like prayer.",
        "The hill rests under a blue cathedral.",
        "My heart climbs the sunlight like a vine.",
        "A clear sky is a door I step through.",
        "Sunlight stitches the field with golden thread.",
        "All around me, the light hums with knowing.",
        "The world leans toward clarity.",
        "Light drips from the petals like honey.",
        "A single crow crosses the empty blue.",
        "The world lifts its face to be seen.",
        "Even the stones breathe under a clear sky.",
        "The sun keeps its promises in silence.",
        # completed
    ],
    "clouds": [
        "The sky speaks in softened syllables.",
        "Today, the sky is thinking deeply.",
        "The morning is a study in pale gray.",
        "Clouds wander like sheep without shepherds.",
        "The field waits quietly beneath the wool sky.",
        "Under clouds, the light speaks in riddles.",
        "The clouds are the sky's long breath.",
        "The sky forgets to shine and hums instead.",
        "A grayness rests over everything.",
        "A field of light, dulled with mercy.",
        "The clouds offer no answers, only pauses.",
        "The wind drapes the clouds over the trees.",
        "Everything becomes a little slower in the gray.",
        "In the cloudlight, every branch waits.",
        "The dog sleeps in a curl of gray light.",
        "A heron moves as though inside a dream.",
        "The sky is a shroud of thought.",
        "A cathedral without sun still holds prayer.",
        "The light today is reluctant and gentle.",
        "My shadow forgets me and walks away.",
        "There is time to wonder in a cloudy day.",
        "The trees lean inward as if whispering secrets.",
        # completed
    ],
    "rain": [
        "The sky weeps gently on the earth’s brow.",
        "Each drop a soft question, asked and answered.",
        "Rain teaches even stones to listen.",
        "The ground sighs into its thirst.",
        "Leaves bow under the grace of water.",
        "Rain walks the roof like a poet.",
        "Everything learns to shine when wet.",
        "The field drinks slowly.",
        "Puddles gather sky and swallow it whole.",
        "The moss celebrates quietly.",
        "Water writes its wisdom on the wind.",
        "Even the fox waits beneath the pine.",
        "I open my hands and they fill with weather.",
        "A hush and a rhythm, soft as prayer.",
        "The rain knows no hurry.",
        "A stone learns patience in the rain.",
        "Rain draws lace on the windows.",
        "This is the sky remembering its oldest song.",
        "Raindrops repeat what the earth already knew.",
        "Everything glistens, even sorrow.",
        "Rain drapes the garden in forgiveness.",
        "The heron blinks through silver air.",
        "Roots stretch like arms toward blessing.",
        "The path becomes a question.",
        "A drumming at the soul’s door.",
        "I listen until the poem inside the rain finishes.",
        "Even silence is soaked.",
        "My breath fogs, and I remain.",
        "I become small enough to feel the drops.",
        # completed
    ],
    "mist": [
        "Mist drifts low, soft as breath.",
        "The valley fills with silver air.",
        "Mist lies close upon the ground.",
        "The hillside fades into whiteness.",
        "Footsteps blur where paths dissolve.",
        "The river runs beneath a ghostly veil.",
        "The horizon folds into gray silence.",
        "Mist curls in quiet ribbons through the field.",
        "Shapes melt like sugar into fog.",
        "Mist gathers, holding the morning still.",
        "The forest is hushed in drifting white.",
        "The world is hidden, not gone.",
        "Light scatters softly in the haze.",
        "A gauze of earthbound cloud drapes the land.",
        "Petals glisten beneath the pale cover.",
        "I could step inside and be erased.",
        "This stillness is the mist’s gift.",
        "The distance folds gently away.",
        "Dew thickens in the quiet air.",
        "Breath joins the veil, then disappears.",
        "Mist remakes the morning in gray brushstrokes.",
        "The hills wear cloaks of shifting white.",
        "The day forgets its outlines here.",
        "I wait as the fog writes its silence."
    ],
    "fog": [
        "The world walks in silence, hooded and barefoot.",
        "What you cannot see is still breathing.",
        "I walk through milk and breath.",
        "Each sound is a whisper of itself.",
        "The lake forgets its shape.",
        "Even my thoughts wear fog today.",
        "The wind becomes invisible.",
        "Footsteps vanish before they finish.",
        "My breath is part of the sky now.",
        "A heron stands where the world ends.",
        "Fog teaches us to feel instead of see.",
        "The sun is a rumor in the distance.",
        "Even time forgets its ticking here.",
        "I listen with my whole skin.",
        "What comes next is not yet drawn.",
        "The branches hold stories still forming.",
        "The fox is a shadow with breath.",
        "I trust the fog like an old friend.",
        "Everything finds stillness in this blur.",
        "The sky leans closer and forgets its name.",
        "No borders, no fences — only softness.",
        "The hush is louder than words.",
        "I vanish by inches and feel free.",
        "The silence wears a shroud.",
        "The fog knows where I’ve been.",
        "The air speaks without speaking.",
    ],
    "drizzle": [
        "A whispering rain, not quite committed.",
        "The world is damp with possibility.",
        "A hush falls, drop by tender drop.",
        "Rain traces thoughts on my sleeves.",
        "Drizzle hushes the thorns.",
        "Every leaf leans toward its sip.",
        "Each drop small but whole.",
        "The moss loves this more than sun.",
        "I walk a little slower, in rhythm.",
        "There is no rush in drizzle.",
        "The sky sketches quietly in water.",
        "I hold my breath to hear it fall.",
        "The flowers nod in damp approval.",
        "A hymn of patience from the clouds.",
        "The day wears wet lace.",
        "I am covered in sky without realizing.",
        "A thousand silent gifts.",
        "The rain hardly speaks, but still it says.",
        "The soil softens like old bread.",
        "I trace poems in the wet dust.",
        "The air smells of earth made gentle.",
        "The drops fall like old stories.",
        "The drizzle waits for no applause.",
        "A slow wetness, as if the sky is remembering.",
    ],

}

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "location",
                name = "Location",
                desc = "Enter your city and country code (e.g. London,UK)",
                icon = "mapPin",
                default = "Washington,DC,US",
            ),
            schema.Dropdown(
                id = "units",
                name = "Units",
                desc = "Choose your preferred temperature units",
                icon = "thermometer",
                options = [
                    schema.Option(value = "imperial", display = "Imperial (°F)"),
                    schema.Option(value = "metric", display = "Metric (°C)"),
                ],
                default = "imperial",
            ),
        ],
    )

def main(ctx):
    location = str(ctx.get("location") or "Washington,DC,US")
    units = str(ctx.get("units") or "imperial")

    # Get encrypted API key securely from manifest.yaml
    weather_api_key = secret.decrypt(ENCRYPTED_API_KEY)
    if weather_api_key == None:
        return render.Root(
            child = render.Text("Missing API key", font = "6x13"),
        )

    # Fetch weather (with caching)
    cache_key = "weatherbard:" + location + ":" + units
    weather_json = cache.get(cache_key)

    if weather_json == None:
        response = http.get(
            "https://api.openweathermap.org/data/2.5/weather?q=" + location +
            "&appid=" + weather_api_key + "&units=" + units,
        )
        if response.status_code != 200:
            return render.Root(child = render.Text("Weather fetch failed", font = "6x13"))
        weather_data = response.json()

        cache.set(cache_key, json.encode(weather_data), ttl_seconds = 600)
    else:
        weather_data = json.decode(weather_json)

    condition = weather_data["weather"][0]["main"].lower()

    # Select poem locally and rotate lines
    poem_lines = poems.get(condition, ["No verse today."])
    offset = int(math.mod(time.now().unix, len(poem_lines)))
    line1 = poem_lines[offset]
    line2 = ""
    line3 = ""

    # Layout: just scroll the poem text
    return [render.Root(
        delay = 150,
        child = render.Marquee(
            scroll_direction = "vertical",
            offset_start = 0,
            offset_end = 0,
            width = 64,
            height = 32,
            child = render.Column(
                children = [
                    render.WrappedText(content = line1, font = "5x8", width = 60),
                    render.WrappedText(content = line2, font = "5x8", width = 60),
                    render.WrappedText(content = line3, font = "5x8", width = 60) if line3 else render.Text("", font = "5x8"),
                ],
            ),
        ),
    )]
