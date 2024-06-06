"""
Applet: Friends Quotes
Summary: Displays Friends quotes
Description: Displays a random quote from the hit TV sitcom, Friends.
Author: kaffolder7
"""

### Special thanks to Marc ten Bosch for lobster facts code template

load("encoding/base64.star", "base64")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

THE_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAALCAYAAADP9otxAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAABZRJREFUeNrclntM01cUx++Pvl+0tFALA0FdmLGgvCyIDCa+ionObLgFkMxFUNHhGBFxataC6GDiHxp1GQYfJBtLmIaBJiNDFoxRBJRF2DpQoT4GQwtr65wT2v72vbVu2OnmsixZ9ks+6e93zrnn3Mc555ZwOByGZdl40M4+fIZ6e3snkf/Yk52dnXj27Nmt/4pzLPqyZ/Ffgs3Dw8OCifrk5GThzZs3nwMJ4BAoKyoqUj3J14EDB/jQv4wxwU+L193drYFNBOA8y/zgSzwyMlJRV1dX763DPHzhRwtC0tLS/ta6zWazlHR2dkbSldtsNmNQUJACELVa/Zjh7Nmzo2BiAhZwh2KxWPbm5eVxvZ0eP36cZtOAXq9f6K1rbGwkHR0dJdD3ADOo8rbRaDTURlBTUxM/Ib4Wtl/V1tbmeduXl5dnQdcPhm/cuHEdYy+DxQkJCU9d+OnTp4WwOUTnyY2NjZ1PhUKh8Oru3bv1eNXdGhr6vnjTpj1UPjMiguzbt4+e5nRwEIyBApVKNTU6Otrl7Xzc4aR2YS6XS+CtS0xMTFYqlWvxSkusD/TW19fLly9fbntkIxYKZXFxcRXw/UJ/f/8So9H4APFnQDXZ39//DxkwOjpKdfTEakJCQsZAOt53IY6Z+p9oW334MAnw91+Rmpq6AZ8poJl4ToI+t8BVcBS8uYcjCM4RSeImJ79IbYrBA1AJToFPT5w4ER8eHu52zMxd6ssYq4KJ5nlSe+zILuhvL1q0yH2CxZliRZVRzhch2QcGzDXs78/Pnr5T6y4dlZpsl8oJ4XIneWKx9+7dy0Ha0/jVXV1drZg4maPlCap2KeSLYwhJeilNcOnSpUboa/bv3y9DCYhaW1tpRv+A+Mvcc1uxUcS8WxVGfATEbrW+7VmjHewE0TSFxWCEZmhJScl3+P1CbbePFgZoNl13jsfrpL50R+lK+YCengO8JZPJLigUiodbG5Uyj8nLzWc/Opjzi+3HEEjO0RKjqlV60fvTF0t4a4y2HIfDqfMcxjegk2aBwWAY5zEMb71CefAuj3dGmLvqa08sq1gsNqanp0/B+5y+vr66lpYWsnaZKDU3X7p+sMdabAmc60KmhEFvwonfDQ0NJRhD18Ojrc29AQszVpF5CZlsxTt6LoeTAdE0zxxCwRt0AzocDocdO5iHdHuULcLgwBBLModzS8PhTvJsgBXYgQysXrBgQbzJZKptb28/T1xODjtCuCnZK4O00bE0wCkej3eHOnI4WT8yauMXrHndX6GQ+0F0HZwHNO3NpaWln0gYRkhcrF4il9/fVlho82zyXkD7CO38FoFAYKL+XC7iR8bJNPz6IENiPOW0JCMjgwcYz5gWxO9xr8Tp4MObkMikwtIdOz5UKJVnCgoKpPD3GrQqml7n4Gi1d22JGYbsFMt40lkzZ9IysVqt2xoaGl7t6ek5gu9uKkPP2PBwlzMl5L06WdOdB8G0WSItM3Eybj8frJMGNBgIl2V/on7ug2ugC7hAK7XhM4xPnTpw/mfaWRGQrQTOsbExSXNzc4QnlqmpqcldUqkxfHXDIWX4K3MIWb9x6w5POdno9Y25XcYcj4HAR/GZ1QYfprJBQwKC+FqtlkRFRU222+3LYP85uEA3YMjpdKY8sV2KRGRd7pqluCG+LSsrc4uSkpJol1aBMNwCwonmhi2bRZAbIiMjY7xdXb02MA2x2ugGoJ5h1rEdPDaeKOT0ikyBzfnq6mq3CDY6UFRZWSn29lliNNDedHtwcHALbKLp3P7iusdBsJ1g5OLFi0cxZioVsleuXJnypAHo2jyoi06ePNn+T/9roDn5466eAcL+zM7X15fgJCXP4jM/Pz8F/jZkZWX5PYt9W1ubH+zLQcBvQtS/42kDdDqdCBtQiPT7mPxPn18FGACEBg1sXYG5OwAAAABJRU5ErkJggg==
""")

QUOTES = {
    "Joey": [
        "How you doin'?",
        "JOEY DOESN'T SHARE FOOD!",
        "Here come the meat sweats...",
        "Could I BE wearing any more clothes?",
        "You can't just give up. Is that what a dinosaur would do?",
        "Some girl ate Monica!",
        "...this is all a moo point. Yeah, it's like a cow's opinion. It just doesn't matter. It's moo.",
        "That's right, I stepped up! She's my friend and she needed help. If I had to, I'd pee on any one of you!",
        "Grab a spoon!",
        "You don't own a TV? What's all your furniture pointed at?",
        "What's not to like? Custard: good. Jam: good. Meat: good!",
        "Well, given that he's desperately in love with you, he probably wouldn't mind getting a cup of coffee or something.",
        "Well, the fridge broke, so I had to eat everything.",
        "That's a great story. Can I eat it?",
        "You hung up on the pizza place? I don't hang up on your friends.",
        "We can stay up late talking and watching movies. And you know about naked Thursdays, right?",
        "You've been BAMBOOZLED!",
        "I swear to god, Dad. That's not how they measure pants!",
        "Phoebe:\n\"Je m'appelle Claude.\"\nJoey:\n\"Jet aplee blooo.\"",
        "Paper! Snow! A Ghost!",
        "Joey:\n\"Man this is weird. You ever realize Captain Crunch's eyebrows are actually on his hat?\"\nChandler:\n\"You think that's weird? Joey, the man's been captain of a cereal for the last 40 years.\"",
        "Joey:\n\"Hey, Ross, I got a science question: If the Homo sapiens were, in fact, HOMO sapiens... is that why they're extinct?\"\nRoss:\n\"Joey, Homo sapiens are PEOPLE.\"\nJoey:\n\"Hey, I'm not judgin'!\"",
    ],
    "Chandler": [
        "I'm not so good with the advice... Can I interest you in a sarcastic comment?",
        "Wah-pah!",
        "Dear God, this parachute is a knapsack!",
        "I'm hopeless and awkward and desperate for love!",
        "Hi, I'm Chandler. I make jokes when I'm uncomfortable.",
        "I'm sorry, it was a one-time thing. I was very drunk, and it was someone else's subconscious.",
        "So it seems like this Internet thing's here to stay.",
        "I say more dumb things before 9 a.m. than most people say all day.",
        "Janice:\n\"What a small world.\"\nChandler:\n\"And yet I never run into Beyoncé.\"",
        "I have no idea what's going on, but I am excited.",
        "I had a very long, hard day.",
        "Oh, come on tell me. I could use another reason why women won't look at me.",
        "You know, on second thought, gum would be perfection.",
        "Oh, yeah... gym member. I try to go four times a week, but I've missed the last... twelve-hundred times.",
        "When I first meet somebody it's usually panic, anxiety, and a great deal of sweating.",
        "Oh, I know. This must be so hard. 'Oh, no! Two women love me. They're both gorgeous and sexy. My wallet's too small for my fifties and my diamond shoes are too tight!'",
        "Shut up! Shut up! SHUT UP!",
        "Until the age of 25, I thought the only response to 'I love you' was 'oh, crap.'",
        "Okay, you have to stop the Q-Tip when there's resistance.",
        "Chandler:\n\"Condoms?\"\nJoey:\n\"We don't know how long we're gonna be stuck here. We might have to repopulate the world.\"\nChandler:\n\"And condoms are the way to do that?\"",
        "Ross:\n\"Chandler entered a Vanilla Ice lookalike contest and WON!\"\nChandler:\n\"Ross came fourth and CRIED!\"",
        "Joanna:\n\"Wait, what are you doing?\"\nChandler:\n\"Getting dressed.\"\nJoanna:\n\"Why?\"\nChandler:\n\"Well, when I walk outside naked, people throw garbage at me.\"",
        "All right, kids, I gotta get to work. If I don't input those numbers... it doesn't make much of a difference.",
        "You're so far past the line, you can't even see the line. The line is a dot to you.",
        "Rachel:\n\"Guess what, guess what, guess what?!\"\nChandler:\n\"Um, OK. The fifth dentist caved and now they're ALL recommending Trident?\"",
        "Look around you guys this was your first home and it was a happy place filled with love and laughter, but more importantly because it was rent- controlled, it was a freakin' steal!",
    ],
    "Ross": [
        "We were on a break!",
        "'Unagi.' I'm always aware.",
        "Ross:\n\"Chandler. I sensed it was you.\"\nChandler:\n\"What?\"\nRoss:\n\"'Unagi.' I'm always aware.\"\nChandler:\n\"Are you aware that unagi is an eel?\"",
        "Pivot! PIVOT!",
        "I'm gonna go out on a limb and say no divorces in '99!",
        "Ugly baby judges you!",
        "No more falafel for you!",
        "I'm the holiday armadillo!",
        "I grew up with Monica. If you didn't eat fast, you didn't eat.",
        "Monica:\n\"Where've you been?\"\nRoss:\n\"Emotional hell.\"",
        "I am this close to tugging on my testicles again.",
        "You're over me? When were you... under me?",
        "You-you- you-you- threw my sandwich away? My sandwich? MY SANDWICH?!",
        "Yes, Rachel is my good friend. And I have loved her in the past, but now, she is just my wife.",
        "Take it from me. As the groom, all you have to do is show up and try to say the right name.",
        "A no-sex pact, huh? I actually have one of those going on with every woman in America.",
        "They're still not coming on, man! And the lotion and the powder have made a paste!",
        "Ross:\n\"Okay, is everybody clear? We're gonna pick it up and move it. All we need is teamwork, okay? We're gonna lift the car... and slide it out. Lift... and slide.\"\nRachel:\n\"Ross, I really don't think...\"\nRoss:\n\"Lift... and slide.\"",
        "Ross:\n\"So, uh, what did the insurance company say?\"\nChandler:\n\"Oh, they said uh, 'You don't have insurance here so stop calling us.\"",
        "I'm Fiiine!",
    ],
    "Phoebe": [
        "He's her lobster.",
        "She's your lobster. It's a known fact that lobsters fall in love and mate for life. You can actually see old lobster couples walking around their tank, holding claws.",
        "Come on, Ross, you're a paleontologist. Dig a little deeper.",
        "Oh, I wish I could, but I don't want to.",
        "Your collective dating record reads like a who's who of human crap.",
        "Monica:\n\"Do you have a plan?\"\nPhoebe:\n\"I don't even have a 'pla.'\"",
        "They don't know that we know they know we know.",
        "That is brand-new information!",
        "Oh you like that? You should hear my phone number.",
        "Something is wrong with the left phalange.",
        "He may not be my soulmate, but a girl's gotta eat.",
        "Meet Princess Consuela Banana Hammock.",
        "Oh, my God! Well, the idea - a woman flirting with a single man? We must alert the church elders!",
        "Boyfriends and girlfriends are gonna come and go but this is for life.",
        "Smelly cat, smelly cat, what are they feeding you? Smelly cat, smelly cat, it's not your fault.",
        "Nestlé Toulouse.",
        "Phoebe:\n\"I remember the day I got my first paycheck, there was a cave-in in one of the mines.\"\nChandler:\n\"Phoebe, you worked in a mine?\"\nPhoebe:\n\"No I worked in a Dairy Queen.\"",
        "Phoebe:\n\"Yeah, I definitely don't like the name Ross.\"\nRoss:\n\"What a weird way to kick me when I'm down.\"",
        "When I was growing up, I didn't have a normal mom and dad, or a regular family like everybody else, and I always knew that something was missing. But now I'm standing here today, knowing that I have everything I'm ever gonna need... You are my family.",
    ],
    "Rachel": [
        "Well, maybe I don't need your money. Wait, wait, I said maybe!",
        "Isn't that just kick-you-in- the-crotch, spit-on- your-neck fantastic?",
        "Ross:\n\"You got a job?\"\nRachel:\n\"Are you kidding? I'm trained for nothing!\"",
        "I got off the plane.",
        "He's so pretty, I want to cry.",
        "No uterus, no opinion.",
        "Oh I'm sorry. Did my back hurt your knife?",
        "It's like all of my life everyone has always told me 'You're a shoe! You're a shoe! You're a shoe! You're a shoe!' Well, what if I don't want to be a shoe? What if I wanna be a purse or a hat?",
        "Monica:\n\"You can't live off your parents your whole life.\"\nRachel:\n\"I know that, that's why I was getting married.\"",
        "Today, it's like there's rock bottom, 50 feet of crap, then me.",
        "Hey, just so you know: it's NOT that common, it DOESN'T 'happen to every guy,' and it IS a big deal!",
        "We are dessert stealers. We are living outside the law.",
        "Everyone is getting married or pregnant or promoted and I'm getting coffee! And it's not even for me!",
        "Oh, are you setting Ross up with someone? Does she have a wedding dress?",
        "Who's FICA? Why's he getting all my money?",
        "Why can't parents just stay parents? You know? Why do they have to become people?",
        "I just shouldn't be able to make decisions anymore.",
        "I wasn't supposed to put beef in the trifle?!",
    ],
    "Monica": [
        "And I have to live with a boy!",
        "Is it me? Is it like I have some sort of beacon that only dogs and men with severe emotional problems can hear?",
        "I've got this uncontrollable need to please people.",
        "I KNOW!",
        "Remember, if I am harsh with you, it is only because you're doing it wrong.",
        "Guys can fake it? Unbelieveable! The one thing that's ours!",
        "I'm gonna love you so much that no woman is ever gonna be good enough for you.",
        "It's baby time. Pants off, Bing.",
        "I can't believe my parents are actually pressuring me to find one of you people.",
        "Welcome to the real world! It sucks. You're gonna love it.",
        "Why didn't you make a copy and keep it in a fireproof box and keep it at least a hundred yards from the original?",
        "Damn the jellyfish. Damn all the jellyfish!",
        "I would get a room with this cake. I think I could show this cake a good time.",
        "Lips moving, still talking!",
        "Seven!",
        "Your little Harmonica is hammered.",
        "Monica:\n\"Okay, everybody relax. This is not even a date. It's just two people going out to dinner and not having s**.\"\nChandler:\n\"Sounds like a date to me.\"",
        "Fine! Judge all you want, but: married a lesbian, left a man at the altar, fell in love with a gay ice dancer, threw a girl's wooden leg in a fire, LIVE IN A BOX!",
    ],
    "Mike H.": [
        "You're a strange kind of grown-up.",
    ],
    "Janice": [
        "Oh. My. God.",
        "Well, I got to buy a vowel because... 'oh my god.'",
    ],
    "Frank Jr.": [
        "My sister's gonna have my baby!",
    ],
}

def main(config):
    random.seed(time.now().unix)
    animation_style = config.get("animationStyle", "style1")
    font_style = config.get("fontStyle", "tb-8")
    quotes_list, root = [], ""

    for person in QUOTES:
        if config.get("enableQuotesBy" + person.replace(".", "").replace(" ", ""), True) == "true":
            for quote in QUOTES[person]:
                quote_str = quote if "\"" in quote else ("\"" + quote + "\"\n-" + person)
                quotes_list.append(quote_str)

    idx = random.number(0, len(quotes_list) - 1) if len(quotes_list) > 0 else 0
    current_quote = quotes_list[idx] if len(quotes_list) > 0 else ""

    style1 = render.Padding(
        pad = 1,
        child = render.Marquee(
            height = 30,
            child = render.Column(
                cross_align = "center",
                children = [
                    render.Image(src = THE_LOGO, width = 52),
                    render.Box(height = 4),
                    render.WrappedText(current_quote, font = "tom-thumb", width = 62, linespacing = 2, align = "center") if font_style == "tom-thumb" else render.WrappedText(current_quote, width = 62, align = "center"),
                ],
            ),
            scroll_direction = "vertical",
        ),
    )

    style2 = render.Padding(
        pad = 1,
        child = render.Column(
            children = [
                render.Row(
                    children = [
                        render.Image(src = THE_LOGO, width = 52),
                    ],
                    main_align = "center",
                    expanded = True,
                ),
                render.Box(height = 3),
                render.Marquee(
                    height = 19,
                    child = render.WrappedText(current_quote, font = "tom-thumb", width = 62, linespacing = 2, align = "center") if font_style == "tom-thumb" else render.WrappedText(current_quote, width = 62, align = "center"),
                    scroll_direction = "vertical",
                ),
            ],
            expanded = True,
        ),
    )

    if animation_style == "style1":
        root = render.Root(
            child = style1,
        )
    elif animation_style == "style2":
        root = render.Root(
            child = style2,
        )
    return root

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "animationStyle",
                name = "Animation style",
                desc = "Choose your preferred animation style",
                icon = "brush",
                default = "style1",
                options = [
                    schema.Option(
                        display = "Default",
                        value = "style1",
                    ),
                    schema.Option(
                        display = "Static logo",
                        value = "style2",
                    ),
                ],
            ),
            schema.Dropdown(
                id = "fontStyle",
                name = "Font style",
                desc = "Choose your preferred font style",
                icon = "font",
                default = "tb-8",
                options = [
                    schema.Option(
                        display = "tb-8",
                        value = "tb-8",
                    ),
                    schema.Option(
                        display = "tom-thumb",
                        value = "tom-thumb",
                    ),
                ],
            ),
            schema.Toggle(
                id = "enableQuotesByJoey",
                name = "Joey",
                desc = "Displays quotes by Joey",
                icon = "gear",
                default = True,
            ),
            schema.Toggle(
                id = "enableQuotesByChandler",
                name = "Chandler",
                desc = "Displays quotes by Chandler",
                icon = "gear",
                default = True,
            ),
            schema.Toggle(
                id = "enableQuotesByRoss",
                name = "Ross",
                desc = "Displays quotes by Ross",
                icon = "gear",
                default = True,
            ),
            schema.Toggle(
                id = "enableQuotesByPhoebe",
                name = "Phoebe",
                desc = "Displays quotes by Phoebe",
                icon = "gear",
                default = True,
            ),
            schema.Toggle(
                id = "enableQuotesByRachel",
                name = "Rachel",
                desc = "Displays quotes by Rachel",
                icon = "gear",
                default = True,
            ),
            schema.Toggle(
                id = "enableQuotesByMonica",
                name = "Monica",
                desc = "Displays quotes by Monica",
                icon = "gear",
                default = True,
            ),
            schema.Toggle(
                id = "enableQuotesByMikeH",
                name = "Mike H.",
                desc = "Displays quotes by Mike H.",
                icon = "gear",
                default = False,
            ),
            schema.Toggle(
                id = "enableQuotesByJanice",
                name = "Janice",
                desc = "Displays quotes by Janice",
                icon = "gear",
                default = False,
            ),
            schema.Toggle(
                id = "enableQuotesByFrankJr",
                name = "Frank Jr.",
                desc = "Displays quotes by Frank Jr.",
                icon = "gear",
                default = False,
            ),
        ],
    )
