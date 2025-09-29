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
        "In light's quiet presence, I am a blade of grass.",
        "The meadow wears sunlight like a shawl.",
        "Under a bright sky, the stones sing.",
        "The morning opens its palms to the sun.",
        "I wake into the hush of a golden day.",
        "Each leaf praises the morning in silence.",
        "Even the shadows are kind when the sky is clear.",
        "The breeze lifts the grasses like prayer.",
        "Every bird is a bell rung by light.",
        "The hill rests under a blue cathedral.",
        "My heart climbs the sunlight like a vine.",
        "The path is lit with a thousand small intentions.",
        "A clear sky is a door I step through.",
        "I kneel in the grasses and call it enough.",
        "The world is tender when the sky is kind.",
        "Sunlight stitches the field with golden thread.",
        "All around me, the light hums with knowing.",
        "The world leans toward clarity.",
        "The wind speaks only in kindness today.",
        "My breath is wide as the morning sky.",
        "Light drips from the petals like honey.",
        "A single crow crosses the empty blue.",
        "The air is made of beginnings.",
        "The world lifts its face to be seen.",
        "Even the stones breathe under a clear sky.",
        "The sun keeps its promises in silence.",
        # completed
    ],
    "clouds": [
        "A hush in the sky, soft with remembering.",
        "The sky speaks in softened syllables.",
        "Today, the sky is thinking deeply.",
        "The morning is a study in pale gray.",
        "Clouds wander like sheep without shepherds.",
        "The field waits quietly beneath the wool sky.",
        "A veil of sky, soft and slow.",
        "Even the breeze walks more softly today.",
        "The sky curls inward, dreaming.",
        "Under clouds, the light speaks in riddles.",
        "The sparrow perches, listening to the hush.",
        "The clouds are the sky's long breath.",
        "Stillness blankets the garden.",
        "The sky forgets to shine and hums instead.",
        "A grayness rests over everything.",
        "I walk inside the softness of thought.",
        "A field of light, dulled with mercy.",
        "The clouds offer no answers, only pauses.",
        "The wind drapes the clouds over the trees.",
        "Everything becomes a little slower in the gray.",
        "In the cloudlight, every branch waits.",
        "The edges of the world go missing.",
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
        "I watch the earth receiving its lesson.",
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
        "The morning wears its veil with grace.",
        "Mist rises slowly, like a forgotten thought.",
        "The field listens with its eyes closed.",
        "The horizon slips away into breath.",
        "I walk among whispers and pale light.",
        "Mist bends the world toward reverence.",
        "Everything is a suggestion this morning.",
        "The path dissolves, but still I follow.",
        "The river hushes itself with fog.",
        "This is the day the trees disappear.",
        "Mist curls like old poems across the field.",
        "A single crow writes in gray ink.",
        "What you can't see still sings.",
        "I dissolve like sugar in this softness.",
        "The mist is a pause before the sentence continues.",
        "The forest dreams in white shroud.",
        "It is not lost, but waiting.",
        "Light hums through the veil.",
        "The earth has drawn a curtain for a moment of rest.",
        "The flowers remain, cloaked and patient.",
        "I could vanish here and be content.",
        "The hush is a kind of blessing.",
        "Every branch is a memory without edges.",
        "The horizon retreats kindly.",
        "The dew waits without hurry.",
        "It is enough to breathe in a world like this.",
        "I find the world made new in this haze.",
        "Mist paints the hills in a single color: wonder.",
        "This is how the morning forgets itself.",
        "I stay quiet and let the fog speak.",
    ],
    "fog": [
        "The world walks in silence, hooded and barefoot.",
        "What you cannot see is still breathing.",
        "Step softly — the world is dreaming out loud.",
        "The trees blur into themselves.",
        "I walk through milk and breath.",
        "Each sound is a whisper of itself.",
        "The lake forgets its shape.",
        "Even my thoughts wear fog today.",
        "The wind becomes invisible.",
        "Footsteps vanish before they finish.",
        "My breath is part of the sky now.",
        "A heron stands where the world ends.",
        "Fog teaches us to feel instead of see.",
        "The forest becomes an idea.",
        "I dissolve into the waiting hush.",
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
        "The sparrow stays one branch lower.",
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
        "I learn to listen in gray.",
        "The soil softens like old bread.",
        "Nothing is hard in this moment.",
        "Even the trees breathe differently.",
        "I trace poems in the wet dust.",
        "The air smells of earth made gentle.",
        "Each step carries a hush.",
        "My jacket remembers other rains.",
        "The drops fall like old stories.",
        "The drizzle waits for no applause.",
        "A slow wetness, as if the sky is remembering.",
    ],
    "snow": [
        "The world forgets its name under white silence.",
        "Each flake a note in winter’s lullaby.",
        "Stillness falls in bright abundance.",
        "The hush of snow carries its own music.",
        "I walk into the whiteness and am remade.",
        "Snow tucks the field in with a prayer.",
        "Every branch is a hymn in white.",
        "The wind moves slow in a world erased.",
        "Each footprint writes a small confession.",
        "The quiet is deep enough to listen.",
    ],
    "haze": [
        "The sky carries weight you cannot name.",
        "Light diffused, like memory before sleep.",
        "You walk slower in this kind of light.",
        "The horizon wears a mask of longing.",
        "Each color has forgotten its name.",
        "The air is soft with forgetting.",
        "I drift through the day like a leaf.",
        "Haze teaches me not to rush.",
        "The world is wrapped in an old thought.",
        "I squint at the sky and still trust it.",
    ],
    "thunderstorm": [
        "The sky speaks in a furious tongue.",
        "Lightning sketches warnings in the air.",
        "This is no time for silence.",
        "The wind runs wild like a story undone.",
        "Rain hammers out a hard rhythm.",
        "Each flash reveals the hidden.",
        "The trees hold their breath.",
        "I wait, small beneath the shouting sky.",
        "Thunder rolls through my bones.",
        "The storm rewrites the silence.",
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
    unit_label = "°F" if units == "imperial" else "°C"
    raw_temp = weather_data["main"]["temp"] if "temp" in weather_data["main"] else None

    temp = str(int(raw_temp)) + unit_label if raw_temp != None else "--" + unit_label

    # Select poem locally and rotate lines
    poem_lines = poems.get(condition, ["No verse today."])
    offset = int(math.mod(time.now().unix, len(poem_lines)))
    line1 = poem_lines[offset]
    line2 = ""
    line3 = ""

    # Layout with top box 7 high, flush against the top, right-aligned temp, spaced label
    return [render.Root(
        delay = 150,
        child = render.Column(
            children = [
                render.Box(
                    width = 64,
                    height = 7,
                    color = "#000055",
                    child = render.Row(
                        main_align = "space_between",
                        children = [
                            render.Text("weatherbard", font = "CG-pixel-3x5-mono"),
                            render.Text(temp, font = "CG-pixel-3x5-mono"),
                        ],
                    ),
                ),
                render.Marquee(
                    scroll_direction = "vertical",
                    offset_start = 0,
                    offset_end = 0,
                    width = 64,
                    height = 25,
                    child = render.Column(
                        children = [
                            render.WrappedText(content = line1, font = "5x8", width = 60),
                            render.WrappedText(content = line2, font = "5x8", width = 60),
                            render.WrappedText(content = line3, font = "5x8", width = 60) if line3 else render.Text("", font = "5x8"),
                        ],
                    ),
                ),
            ],
        ),
    )]
