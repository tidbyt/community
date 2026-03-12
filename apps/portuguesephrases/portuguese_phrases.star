"""
Applet: Portuguese Phrases
Summary: European Portuguese phrases
Description: Cycles through common European Portuguese (PT-PT) phrases with English translations.
Author: Joey Spooner
"""

load("render.star", "render")
load("time.star", "time")

# Generated from data/phrases.csv. Do not edit by hand.
PHRASES = [
    {
        "pt": "SE CALHAR",
        "en": "maybe / perhaps",
    },
    {
        "pt": "JÁ VOU",
        "en": "I'm coming",
    },
    {
        "pt": "COM LICENÇA",
        "en": "excuse me",
    },
    {
        "pt": "ESTÁ TUDO BEM?",
        "en": "all good?",
    },
    {
        "pt": "LOGO SE VÊ",
        "en": "we'll see",
    },
    {
        "pt": "NÃO FAZ MAL",
        "en": "no problem",
    },
    {
        "pt": "ATÉ JÁ",
        "en": "see you soon",
    },
    {
        "pt": "QUE GIRO!",
        "en": "how nice!",
    },
    {
        "pt": "TENHO SONO",
        "en": "I'm sleepy",
    },
    {
        "pt": "TENHO FOME",
        "en": "I'm hungry",
    },
    {
        "pt": "BOM DIA",
        "en": "good morning",
    },
    {
        "pt": "BOA TARDE",
        "en": "good afternoon",
    },
    {
        "pt": "BOA NOITE",
        "en": "good evening",
    },
    {
        "pt": "OLÁ",
        "en": "hello",
    },
    {
        "pt": "ADEUS",
        "en": "goodbye",
    },
    {
        "pt": "ATÉ LOGO",
        "en": "see you later",
    },
    {
        "pt": "ATÉ AMANHÃ",
        "en": "till tomorrow",
    },
    {
        "pt": "POR FAVOR",
        "en": "please",
    },
    {
        "pt": "OBRIGADO",
        "en": "thank you (m)",
    },
    {
        "pt": "OBRIGADA",
        "en": "thank you (f)",
    },
    {
        "pt": "DE NADA",
        "en": "you're welcome",
    },
    {
        "pt": "DESCULPE",
        "en": "sorry / pardon",
    },
    {
        "pt": "COM CERTEZA",
        "en": "of course",
    },
    {
        "pt": "CLARO",
        "en": "of course",
    },
    {
        "pt": "TALVEZ",
        "en": "maybe",
    },
    {
        "pt": "QUE PENA!",
        "en": "what a shame!",
    },
    {
        "pt": "QUE FIXE!",
        "en": "how cool!",
    },
    {
        "pt": "BORA!",
        "en": "let's go!",
    },
    {
        "pt": "PRONTO",
        "en": "okay / done",
    },
    {
        "pt": "ENTÃO?",
        "en": "so? / well?",
    },
    {
        "pt": "OLHA",
        "en": "hey / look",
    },
    {
        "pt": "NÃO SEI",
        "en": "I don't know",
    },
    {
        "pt": "JÁ SEI",
        "en": "I got it",
    },
    {
        "pt": "TÁ BEM",
        "en": "okay / alright",
    },
    {
        "pt": "A SÉRIO?",
        "en": "seriously?",
    },
    {
        "pt": "FORÇA!",
        "en": "go for it!",
    },
    {
        "pt": "VÁ LÁ",
        "en": "come on",
    },
    {
        "pt": "ESPERA",
        "en": "wait",
    },
    {
        "pt": "DEIXA ESTAR",
        "en": "never mind",
    },
    {
        "pt": "SAUDADE",
        "en": "longing",
    },
    {
        "pt": "ANDA CÁ",
        "en": "come here",
    },
    {
        "pt": "POIS",
        "en": "yeah / right",
    },
    {
        "pt": "POIS É",
        "en": "right / indeed",
    },
    {
        "pt": "BOA!",
        "en": "nice! / great!",
    },
    {
        "pt": "EPÁ!",
        "en": "wow / hey",
    },
    {
        "pt": "FICA BEM",
        "en": "take care",
    },
    {
        "pt": "COM PRAZER",
        "en": "with pleasure",
    },
    {
        "pt": "QUE SAUDADE!",
        "en": "I miss it so!",
    },
    {
        "pt": "É MESMO!",
        "en": "for real!",
    },
    {
        "pt": "SAÚDE!",
        "en": "cheers!",
    },
]

def _frame_colored(pt, en):
    return render.Box(
        child = render.Column(
            main_align = "center",
            cross_align = "center",
            expanded = True,
            children = [
                render.Text(content = pt, font = "6x13", color = "#00CC00"),
                render.Text(content = en, font = "tom-thumb", color = "#5BC8F5"),
            ],
        ),
    )

def _frame_green_bg(pt, en):
    return render.Box(
        color = "#006600",
        child = render.Column(
            main_align = "center",
            cross_align = "center",
            expanded = True,
            children = [
                render.Text(content = pt, font = "6x13", color = "#FFF"),
                render.Text(content = en, font = "tom-thumb", color = "#FFF"),
            ],
        ),
    )

def main():
    if len(PHRASES) == 0:
        return render.Root(
            child = render.Text(
                content = "No phrases",
                font = "5x7",
            ),
        )

    idx = (time.now().unix // 3) % len(PHRASES)
    p = PHRASES[idx]
    pt = p["pt"]
    en = p["en"].upper()

    return render.Root(
        delay = 2000,
        child = render.Animation(
            children = [
                _frame_colored(pt, en),
                _frame_green_bg(pt, en),
            ],
        ),
    )
