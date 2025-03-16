"""
Applet: Schopenhauer
Summary: Random Schopenhauer quote
Description: The App displays a random quote by Arthur Schopenhauer.
Author: nelken
"""

load("encoding/base64.star", "base64")
load("render.star", "render")
load("time.star", "time")

# Linear Congruential Generator as a workaround to pixlet not supporting random numbers
def lcg(seed, a, c, m):
    return (a * seed + c) % m

def generate_random_number(seed, m):
    a = 1664525
    c = 1013904223
    return lcg(seed, a, c, m)

# some quotes attributed to Arthur Schopenhauer. Note that some may be hallucinated...
quotes = [
    {
        "id": "1",
        "quote": "The two enemies of human happiness are pain and boredom.",
    },
    {
        "id": "2",
        "quote": "Compassion is the basis of morality.",
    },
    {
        "id": "3",
        "quote": "Talent hits a target no one else can hit; Genius hits a target no one else can see.",
    },
    {
        "id": "4",
        "quote": "A man can do what he wants, but not want what he wants.",
    },
    {
        "id": "5",
        "quote": "All truth passes through three stages. First, it is ridiculed. Second, it is violently opposed. Third, it is accepted as being self-evident.",
    },
    {
        "id": "6",
        "quote": "Mostly it is loss which teaches us about the worth of things.",
    },
    {
        "id": "7",
        "quote": "The person who writes for fools is always sure of a large audience.",
    },
    {
        "id": "8",
        "quote": "Every man takes the limits of his own field of vision for the limits of the world.",
    },
    {
        "id": "9",
        "quote": "One should use common words to say uncommon things.",
    },
    {
        "id": "10",
        "quote": "The greatest of follies is to sacrifice health for any other kind of happiness.",
    },
    {
        "id": "11",
        "quote": "It is difficult to find happiness within oneself, but it is impossible to find it anywhere else.",
    },
    {
        "id": "12",
        "quote": "Life swings like a pendulum backward and forward between pain and boredom.",
    },
    {
        "id": "13",
        "quote": "To live alone is the fate of all great souls.",
    },
    {
        "id": "14",
        "quote": "The alchemists in their search for gold discovered many other things of greater value.",
    },
    {
        "id": "15",
        "quote": "The more unintelligent a man is, the less mysterious existence seems to him.",
    },
    {
        "id": "16",
        "quote": "We can regard our life as a uselessly disturbing episode in the blissful repose of nothingness.",
    },
    {
        "id": "17",
        "quote": "Change alone is eternal, perpetual, immortal.",
    },
    {
        "id": "18",
        "quote": "Suffering by nature or chance never seems so painful as suffering inflicted on us by the arbitrary will of another.",
    },
    {
        "id": "19",
        "quote": "Politeness is to human nature what warmth is to wax.",
    },
    {
        "id": "20",
        "quote": "To free a man from error is to give, not to take away. Knowledge that a thing is false is a truth.",
    },
    {
        "id": "21",
        "quote": "After your death, you will be what you were before your birth.",
    },
    {
        "id": "22",
        "quote": "The longer a man's fame is likely to last, the later it will be in coming.",
    },
    {
        "id": "23",
        "quote": "Money is human happiness in the abstract; he, then, who is no longer capable of enjoying human happiness in the concrete devotes his heart entirely to money.",
    },
    {
        "id": "24",
        "quote": "Sleep is the interest we have to pay on the capital which is called in at death.",
    },
    {
        "id": "25",
        "quote": "We forfeit three-fourths of ourselves in order to be like other people.",
    },
    {
        "id": "26",
        "quote": "To feel envy is human, to savor schadenfreude is devilish.",
    },
    {
        "id": "27",
        "quote": "The first forty years of life give us the text: the next thirty supply the commentary.",
    },
    {
        "id": "28",
        "quote": "It is in the treatment of trifles that a person shows what they are.",
    },
    {
        "id": "29",
        "quote": "Every parting gives a foretaste of death, every reunion a hint of the resurrection.",
    },
    {
        "id": "30",
        "quote": "The wise have always said the same things, and fools, who are the majority, have always done just the opposite.",
    },
    {
        "id": "31",
        "quote": "A pessimist is an optimist in full possession of the facts.",
    },
    {
        "id": "32",
        "quote": "Wealth is like seawater; the more we drink, the thirstier we become.",
    },
    {
        "id": "33",
        "quote": "Every man has been made by God in order to acquire knowledge and contemplate.",
    },
    {
        "id": "34",
        "quote": "We should be careful to get out of an experience only the wisdom that is in it—and stop there.",
    },
    {
        "id": "35",
        "quote": "Wicked thoughts and worthless efforts gradually set their mark on the face, especially the eyes.",
    },
    {
        "id": "36",
        "quote": "Boredom is just the reverse side of fascination: both depend on being outside rather than inside a situation, and one leads to the other.",
    },
    {
        "id": "37",
        "quote": "The wise man lives as long as he ought, not as long as he can.",
    },
    {
        "id": "38",
        "quote": "To live alone is the fate of all great souls.",
    },
    {
        "id": "39",
        "quote": "Religion is the masterpiece of the art of animal training, for it trains people as to how they shall think.",
    },
    {
        "id": "40",
        "quote": "Men need some kind of external activity, because they are inactive within.",
    },
    {
        "id": "41",
        "quote": "Nature shows that with the growth of intelligence comes increased capacity for pain.",
    },
    {
        "id": "42",
        "quote": "We seldom think of what we have, but always of what we lack.",
    },
    {
        "id": "43",
        "quote": "Great men are like eagles, and build their nest on some lofty solitude.",
    },
    {
        "id": "44",
        "quote": "Every possession and every happiness is but lent by chance for an uncertain time, and may therefore be demanded back the next hour.",
    },
    {
        "id": "45",
        "quote": "The longer a man's fame is likely to last, the later it will be in coming.",
    },
    {
        "id": "46",
        "quote": "Life and dreams are leaves of the same book.",
    },
    {
        "id": "47",
        "quote": "Truth that is naked is the most beautiful, and the simpler its expression the deeper is the impression it makes.",
    },
    {
        "id": "48",
        "quote": "No rose without a thorn, but many a thorn without a rose.",
    },
    {
        "id": "49",
        "quote": "Just remember, once you're over the hill you begin to pick up speed.",
    },
    {
        "id": "50",
        "quote": "Faith is like love: it does not let itself be forced.",
    },
    {
        "id": "51",
        "quote": "Nature never deceives us; it is we who deceive ourselves.",
    },
    {
        "id": "52",
        "quote": "There is no doubt that life is given us, not to be enjoyed, but to be overcome; to be got over.",
    },
    {
        "id": "53",
        "quote": "Patience is the first rule of success.",
    },
    {
        "id": "54",
        "quote": "We should always be wary of the gratitude of those we are trying to help.",
    },
    {
        "id": "55",
        "quote": "There is no absurdity so obvious but that it may be firmly planted in the human head if you only begin to inculcate it before the age of five, by constantly repeating it with an air of great solemnity.",
    },
    {
        "id": "56",
        "quote": "What people commonly call fate is mostly their own stupidity.",
    },
    {
        "id": "57",
        "quote": "To buy books would be a good thing if we also could buy the time to read them.",
    },
    {
        "id": "58",
        "quote": "Martyrdom is the only way in which a man can become famous without ability.",
    },
    {
        "id": "59",
        "quote": "With people of limited ability modesty is merely honesty. But with those who possess great talent it is hypocrisy.",
    },
    {
        "id": "60",
        "quote": "Martyrdom is the only way in which a man can become famous without ability.",
    },
    {
        "id": "61",
        "quote": "Opinion is like a pendulum and obeys the same law. If it goes past the center of gravity on one side, it must go a like distance on the other.",
    },
    {
        "id": "62",
        "quote": "Just as one spoils the stomach by over-feeding it and thereby makes it insensible to normal pleasure, so too the mind is rendered obtuse and insensible to what is truly beautiful by being overstimulated with cloying pleasures.",
    },
    {
        "id": "63",
        "quote": "In the consciousness of the individual, the will to live is the primordial and fundamental phenomenon.",
    },
    {
        "id": "64",
        "quote": "Will minus intellect constitutes vulgarity.",
    },
    {
        "id": "65",
        "quote": "Life is a constant process of dying.",
    },
    {
        "id": "66",
        "quote": "There is not much to be got anywhere in the world. It is filled with misery and pain.",
    },
    {
        "id": "67",
        "quote": "Everyone takes the limits of his own vision for the limits of the world.",
    },
    {
        "id": "68",
        "quote": "Happiness consists in frequent repetition of pleasure.",
    },
    {
        "id": "69",
        "quote": "Politeness is to human nature what warmth is to wax.",
    },
    {
        "id": "70",
        "quote": "What now on the other hand makes people sociable is their incapacity to endure solitude and thus themselves.",
    },
    {
        "id": "71",
        "quote": "We will gradually become indifferent to what goes on in the minds of other people when we acquire enough experience to see how shallow and futile their thoughts are.",
    },
    {
        "id": "72",
        "quote": "If we were not all so interested in ourselves, life would be so uninteresting that none of us would be able to endure it.",
    },
    {
        "id": "73",
        "quote": "The wise have always said the same things, and fools, who are the majority, have always done just the opposite.",
    },
    {
        "id": "74",
        "quote": "Honor means that a man is not exceptional; fame, that he is.",
    },
    {
        "id": "75",
        "quote": "Wealth is like sea-water; the more we drink, the thirstier we become; and the same is true of fame.",
    },
    {
        "id": "76",
        "quote": "If a man has a certain amount of money, it makes no difference whether he has it or not; he will live accordingly.",
    },
    {
        "id": "77",
        "quote": "We seldom think of what we have, but always of what we lack.",
    },
    {
        "id": "78",
        "quote": "To buy books would be a good thing if we also could buy the time to read them.",
    },
    {
        "id": "79",
        "quote": "The greatest of follies is to sacrifice health for any other kind of happiness.",
    },
    {
        "id": "80",
        "quote": "Mostly it is loss which teaches us about the worth of things.",
    },
    {
        "id": "81",
        "quote": "The discovery of truth is prevented more effectively, not by the false appearance things present and which mislead into error, not directly by weak reasoning powers, but by preconceived opinion, by prejudice.",
    },
    {
        "id": "82",
        "quote": "Compassion is the basis of morality.",
    },
    {
        "id": "83",
        "quote": "It is difficult to find happiness within oneself, but it is impossible to find it anywhere else.",
    },
    {
        "id": "84",
        "quote": "Life swings like a pendulum backward and forward between pain and boredom.",
    },
    {
        "id": "85",
        "quote": "There is no more mistaken path to happiness than worldliness, revelry, high life.",
    },
    {
        "id": "86",
        "quote": "The alchemists in their search for gold discovered many other things of greater value.",
    },
    {
        "id": "87",
        "quote": "Religion is the masterpiece of the art of animal training, for it trains people as to how they shall think.",
    },
    {
        "id": "88",
        "quote": "The wise have always said the same things, and fools, who are the majority, have always done just the opposite.",
    },
    {
        "id": "89",
        "quote": "The longer a man's fame is likely to last, the later it will be in coming.",
    },
    {
        "id": "90",
        "quote": "To live alone is the fate of all great souls.",
    },
    {
        "id": "91",
        "quote": "Mostly it is loss which teaches us about the worth of things.",
    },
    {
        "id": "92",
        "quote": "Every possession and every happiness is but lent by chance for an uncertain time, and may therefore be demanded back the next hour.",
    },
    {
        "id": "93",
        "quote": "The greatest of follies is to sacrifice health for any other kind of happiness.",
    },
    {
        "id": "94",
        "quote": "Reading is equivalent to thinking with someone else's head instead of with one's own.",
    },
    {
        "id": "95",
        "quote": "The fundament upon which all our knowledge and learning rests is the inexplicable.",
    },
    {
        "id": "96",
        "quote": "In our monogamous part of the world, to marry means to halve one’s rights and double one’s duties.",
    },
    {
        "id": "97",
        "quote": "The first forty years of life give us the text; the next thirty supply the commentary on it.",
    },
    {
        "id": "98",
        "quote": "The man who does not value himself, cannot value anything or anyone.",
    },
    {
        "id": "99",
        "quote": "Every man takes the limits of his own vision for the limits of the world.",
    },
    {
        "id": "100",
        "quote": "Truth that is naked is the most beautiful, and the simpler its expression the deeper is the impression it makes.",
    },
]

def main():
    # the app design is inspired by the bofh quotes design
    img_b64 = "/9j/4AAQSkZJRgABAQAAAQABAAD/4gHYSUNDX1BST0ZJTEUAAQEAAAHIAAAAAAQwAABtbnRyUkdCIFhZWiAH4AABAAEAAAAAAABhY3NwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAA9tYAAQAAAADTLQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAlkZXNjAAAA8AAAACRyWFlaAAABFAAAABRnWFlaAAABKAAAABRiWFlaAAABPAAAABR3dHB0AAABUAAAABRyVFJDAAABZAAAAChnVFJDAAABZAAAAChiVFJDAAABZAAAAChjcHJ0AAABjAAAADxtbHVjAAAAAAAAAAEAAAAMZW5VUwAAAAgAAAAcAHMAUgBHAEJYWVogAAAAAAAAb6IAADj1AAADkFhZWiAAAAAAAABimQAAt4UAABjaWFlaIAAAAAAAACSgAAAPhAAAts9YWVogAAAAAAAA9tYAAQAAAADTLXBhcmEAAAAAAAQAAAACZmYAAPKnAAANWQAAE9AAAApbAAAAAAAAAABtbHVjAAAAAAAAAAEAAAAMZW5VUwAAACAAAAAcAEcAbwBvAGcAbABlACAASQBuAGMALgAgADIAMAAxADb/2wBDAAUDBAQEAwUEBAQFBQUGBwwIBwcHBw8LCwkMEQ8SEhEPERETFhwXExQaFRERGCEYGh0dHx8fExciJCIeJBweHx7/2wBDAQUFBQcGBw4ICA4eFBEUHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh7/wAARCAAUABADASIAAhEBAxEB/8QAFwAAAwEAAAAAAAAAAAAAAAAAAAUHBv/EACMQAAEEAQMFAQEAAAAAAAAAAAECAwQRBQAhMQYHEjJBYYH/xAAUAQEAAAAAAAAAAAAAAAAAAAAA/8QAFBEBAAAAAAAAAAAAAAAAAAAAAP/aAAwDAQACEQMRAD8A3WKy+OxcllibjUSkyHktrc9lN7EgCyAPI0NLe4c7FOREtRI62nE2Fg0DRopBo8gfdRLrjuo6910IzD6GsHj3nG1tM7mUtKSUqUfgDiQBXG531PofcDqKPnZmWlSzMXOcC5TLopC6T4poD18RQFfBoEuRnuyMPBjLajhKLIUloBe1jdXJv90qVz/dGjQf/9k="

    img = base64.decode(img_b64)
    seed = time.now().nanosecond
    random_number = generate_random_number(seed, 444423295)
    random_number_mod = random_number % 99  # noticed better randomness with 99 than 100
    selected_quote = quotes[random_number_mod]
    quote = selected_quote["quote"]

    return render.Root(
        child = render.Column(
            expanded = False,
            children = [
                render.Row(
                    children = [
                        render.Image(src = img),
                        render.Column(
                            expanded = False,
                            children = [
                                render.Text(
                                    font = "CG-pixel-3x5-mono",
                                    color = "#0a0",
                                    content = "Schopenhauer",
                                ),
                                render.Text(
                                    font = "CG-pixel-3x5-mono",
                                    color = "#0a0",
                                    content = " ",
                                ),
                                render.Text(
                                    font = "CG-pixel-3x5-mono",
                                    color = "#0a0",
                                    content = "Says:",
                                ),
                            ],
                        ),
                    ],
                ),
                render.Text(
                    font = "CG-pixel-4x5-mono",
                    color = "#0a0",
                    content = " ",
                ),
                render.Marquee(
                    width = 64,
                    height = 16,
                    child = render.WrappedText(
                        font = "CG-pixel-3x5-mono",
                        height = 16,
                        linespacing = -1,
                        content = ("%s" % quote),
                    ),
                ),
            ],
        ),
    )
