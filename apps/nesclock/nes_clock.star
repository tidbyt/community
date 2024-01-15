"""
Applet: NES Clock
Summary: NES Game Themed Clock
Description: Short animimations of various Nintendo characters with a clock in the background.
Author: hx009
"""

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("math.star", "math")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

FRAME_HEIGHT = 32
FRAME_WIDTH = 64
DEFAULT_HAS_LEADING_ZERO = False
DEFAULT_IS_24_HOUR_FORMAT = False
DEFAULT_LOCATION = {
    "lat": 41.505550,
    "lng": -81.691498,
    "locality": "Cleveland, OH",
}
DEFAULT_GAME = "0"
DEFAULT_SPEED = "30"
DEFAULT_TIMEZONE = "US/Eastern"
SPEED_LIST = {
    "Snail": "50",
    "Slow": "40",
    "Medium": "30",
    "Fast": "20",
    "Turbo": "10",
    "Random": "-1",
}

GAME_LIST = {
    "Random": "0",
    "Kirby's Adventure": "3",
    "Mega Man": "2",
    "Super Mario Bros. 3": "1",
}

MM_RUN_R_01 = """iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAMAAADXqc3KAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAASUExURQAAAADo2ABw7PzkoPz8/AAAAO8UHAIAAAAGdFJOU///////ALO/pL8AAAAJcEhZcwAADsMAAA7DAcdvqGQAAACgSURBVChTjZHbDsMgDENz4/9/ebYDW6q20vxQwIckFrX1or+B2XauALZ7WxdgEXHIBPRButsDcA+4A5gLoOQBZFVF1AQMRN8sbQDGdLsDjiVJtsrKAxQHvnsyLP0f4AwoMgknQCoKbp8I9HQWmI4SaQPc0UWSCViLl9B3SzPkM+1edvdu1I6CsU8DjtYAbln1BVr7lxL09oCWCshu4GitD/uQBuB2YZXNAAAAAElFTkSuQmCC"""
MM_RUN_R_02 = """iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAMAAADXqc3KAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAASUExURQAAAADo2ABw7PzkoPz8/AAAAO8UHAIAAAAGdFJOU///////ALO/pL8AAAAJcEhZcwAADsMAAA7DAcdvqGQAAACSSURBVChTbZJZDsAgCAXZvP+VywOs0Er8MDNhs6U1g6jIFI6ZEw1BIrJNF+BustpFMIvTJohDeMpFqJmJ2BA+EDiR0hCY5iacQ6CUmh4BHgbDgneBYooIVuJdOiJA4BS+QRYE3AIGB3yKytlP1UTmUL16F9jdR/uLaL0/4LdH9I04l8mnqIEi2m2mHIFf5E1Z6wHrlQeqWUG/UwAAAABJRU5ErkJggg=="""
MM_RUN_R_03 = """iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAMAAADXqc3KAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAASUExURQAAAADo2ABw7PzkoPz8/AAAAO8UHAIAAAAGdFJOU///////ALO/pL8AAAAJcEhZcwAADsMAAA7DAcdvqGQAAACmSURBVChTjZBRDgMgCENB9P5XXlsQyZIl40NjX8GqnR/1HzB7xwEgu/d5WNZagzwHdJCe9g3cV0q1YrwAWgbQpQCx915rN4BHALpZWIObZgAmwMwGHBU7JIFxPUkYNmrGA27BMq8ODYSJhIU9rQyQ3ZAAS8+4fJYKP8UHyS2zCP3q51pxYdUt79cFyq17mygV3Xdm6UpVcwnqAkq1p84qZYBbPJzzAVOBBm9yUgVbAAAAAElFTkSuQmCC"""
MM_BG_IMG = """iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAAAAXNSR0IArs4c6QAAAI5JREFUaEPt17EJgDAQheF3lQ7nAG6gI2UAxQUcxhEcIV0EQbAIaBven/pS5HF3HwmdR5HxCQKgAxgBdoDxDhRLEAVQAAVQAAWME4BBGIRBGIRBYwT4DMEgDMIgDMKgNYOlFO8OGHMigGcEtm7SGqE9p8+pqNW2eD/eHTD08/3wPwHUalu8H4vkPQIyD+AC4U+KUvuYVnUAAAAASUVORK5CYII="""
MM_SPRITE_WIDTH = 24
MM_MAX_X = FRAME_WIDTH
MM_DIST_BETWEEN_SPRITES = 60
MM_MIN_X = -(MM_SPRITE_WIDTH + MM_DIST_BETWEEN_SPRITES + MM_SPRITE_WIDTH)
MM_MOVE_SPEED = 2
MM_FRAMES_PER_CALL = (MM_MAX_X - MM_MIN_X) // MM_MOVE_SPEED
# How many app frames before we increase the sprite frame
MM_FRAMES_PER_FRAME = 1
MM_MEGAMANS = [MM_RUN_R_01, MM_RUN_R_02, MM_RUN_R_03]

KIRBY_RUN_R_01 = """iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAMUExURQQCBPxuzPzC5AAAAHHu1hwAAAAEdFJOU////wBAKqn0AAAACXBIWXMAAA7CAAAOwgEVKEqAAAAAYklEQVQoU22PQQ4AMQgCUf//52Ww7WlpYhUVogYIJBs+qbq7lnJICSpdxg/R7GWcEfmVw2tDEH6IOES3SlgttaB8rt7A1/2rwkAWHmOJaKCV0tkh/GG3JbfkCG7Y45xRBzMf0+EBhzj2w3oAAAAASUVORK5CYII="""
KIRBY_RUN_R_02 = """iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAMUExURQQCBPxuzPzC5AAAAHHu1hwAAAAEdFJOU////wBAKqn0AAAACXBIWXMAAA7BAAAOwQG4kWvtAAAAWElEQVQoU22PCw7AIAhDrdz/zusH3LJYI6FPEVz1U8CyktpiUzBhiJV8+vEDxmmpvn0Az68AG91HgOl7i0BdAhgNZi5Ko7l1E4/qzcfOZxJAER/Aor5Q9QAApQHH/bXo5wAAAABJRU5ErkJggg=="""
KIRBY_RUN_R_03 = """iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAMUExURQQCBPxuzPzC5AAAAHHu1hwAAAAEdFJOU////wBAKqn0AAAACXBIWXMAAA7BAAAOwQG4kWvtAAAAX0lEQVQoU1WPAQ7AIAwCAf//5wGtSyRG7YFacSJE3Z0sACVxkKeWEet6bC0N+ANCiMGWD2Dpk4DoowN6x2IDK9bAAjeE8duIAe/D7TVgiWtHcmkPWbY2lE/FWHCVEM4H7RQBnYG2LTcAAAAASUVORK5CYII="""
KIRBY_RUN_R_04 = """iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAMUExURQQCBPxuzPzC5AAAAHHu1hwAAAAEdFJOU////wBAKqn0AAAACXBIWXMAAA7CAAAOwgEVKEqAAAAAWElEQVQoU22PCw7AIAhDrdz/zusH3LJYI6FPEVz1U8CyktpiUzBhiJV8+vEDxmmpvn0Az68AG91HgOl7i0BdAhgNZi5Ko7l1E4/qzcfOZxJAER/Aor5Q9QAApQHH/bXo5wAAAABJRU5ErkJggg=="""
KIRBY_BG_IMG = """iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgBAMAAABQs2O3AAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAPUExURby8vACoAECI/Pz8/AAAACIqD1IAAAAJcEhZcwAADsIAAA7CARUoSoAAAACISURBVDjLzZHbDYAwCEUxXUCcQJ2ABDeQ/WeyL7U+74fGeP4oJ3DbElHFzE2f6DgR6pYi6i4FUU8WsjH3Y50Fl4RorP1QtyLFhHBS9n3tJzgVLMwrmHvekldAYVlxoN5lOBPghA+EQcfimkdBTA0LtyueC9u/OMtAb2T4wzsYAAsKwALkPoHZBAq2b/W6zH+xAAAAAElFTkSuQmCC"""
KIRBY_SPRITE_WIDTH = 16
KIRBY_MAX_X = FRAME_WIDTH
KIRBY_DIST_BETWEEN_SPRITES = 5
KIRBY_MIN_X = -(KIRBY_SPRITE_WIDTH + KIRBY_DIST_BETWEEN_SPRITES + KIRBY_SPRITE_WIDTH)
KIRBY_MOVE_SPEED = 2
KIRBY_FRAMES_PER_CALL = (KIRBY_MAX_X - KIRBY_MIN_X) // KIRBY_MOVE_SPEED

# How many app frames before we increase the sprite frame
KIRBY_FRAMES_PER_FRAME = 1
KIRBY_KIRBYS = [KIRBY_RUN_R_01, KIRBY_RUN_R_02, KIRBY_RUN_R_03, KIRBY_RUN_R_04]

SMB3_SPRITE_WIDTH = 16
SMB3_MAX_X = FRAME_WIDTH
SMB3_DIST_BETWEEN_SPRITES = 10
SMB3_MIN_X = -(SMB3_SPRITE_WIDTH + SMB3_DIST_BETWEEN_SPRITES + SMB3_SPRITE_WIDTH)
SMB3_MARIO_MOVE_SPEED = 1
SMB3_FRAMES_PER_CALL = (SMB3_MAX_X - SMB3_MIN_X) // SMB3_MARIO_MOVE_SPEED

# How many app frames before we increase the sprite frame
SMB3_MARIO_FRAMES_PER_FRAME = 1
MAX_SPEED = 10
MIN_SPEED = 50
SECONDS_TO_RENDER = 15
SMB3_COLON_IMG = """iVBORw0KGgoAAAANSUhEUgAAAAMAAAAHCAYAAADNufepAAAAAXNSR0IArs4c6QAAABhJREFUGFdjZEACjNg4/xkYGBhJlAGbAwBZvwIImajg6gAAAABJRU5ErkJggg=="""
SMB3_DESERT_BG_IMG = """iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAAAAXNSR0IArs4c6QAAAVJJREFUaEPtmVEKwjAMhjvZLbyFIEzPMnwTfNhx9rBn8SwqyLyGlygqGaRkte0yQaRp97JuK9n+L3+zjBV1q19K2Hbc3tSjb1iqihQALPe9F4Y4AJB93MAFIP55v6jFajPawxw4JwYAFU4BwDgpB4Bg2wWhYiDGAbZILgSxAGwnwLHrzZAUANdSSALA7rw22u1iKRYACKXCafYRAlwXCyBU+ZMHQOEk6YAMgBDIDvB9DZ6a0llH6lazPjNjmfThABSuu8qpoTxch/NSQIwAgHifcJsGgJAAwQCYIx5hSIAQBAAC0RF0LA6AL/tTAABE7C4YHPCN/aW4IAPIDshLIPEaoJQyf4agsfG1wNzWNrYYhe6qAQC2uDAOtcFTfQGCiiWGAeDKsKv54TqBvia57bUv9i+fYwSAe6PQvNhiBB0wN9sxzmcB8GWVm22sMa6l8O8Yb56mP6oG3pCsAAAAAElFTkSuQmCC"""
SMB3_LAND_BG_IMG = """iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAAAAXNSR0IArs4c6QAAAWtJREFUaEPtlyEOAkEMRWeD4BwIEgwGNJIDoBAcAM9B8BwAgSLBYkjQYDAkCC6BWUEgneRPujMdWNvdrtxZxHvT/pZiX74/rsVPYQKsAqwFLANanIHOQtCmgE0BmwLJFJh1O0ku7st3Y7KS8yUhSIer+9zD3i7XAH1cPFwTJMR8FQH8kF83RGiXIPGJAtaDXVLu023fv9MsAQI4XxBAhwRJgPTEbUDvca6xFXJ8FQEcPNcCWiUg+HCx4KsIiA/xEc8AzQIkPlHApLdx5+cyFAEXgJfa2oAHIOfzAuJDQMYSkAPawvAXXyKA4OIKwE5AAqiMqCI0TYN4/P2sgNy6R9DD8aiyIGmRkNtvCKZwzn0QDtLNS0I0LUa53g9TAAIIXup9qSU0Csjx/a0A6YcaBeSyzQug2Y7+lkqet4a2P0jYAHN8YQpg16/7n1dLABIPJEhsvgLqQjfxu+J1OpiAJt5sXSargNa3QNtD8AtPNFLEW9t33AAAAABJRU5ErkJggg=="""
SMB3_MARIO_SWM_R_01 = """iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAALZJREFUOE+dk8EJgDAMRdVJXEHw5giO4NkRxQm8Ca7gJFYSmvpNvyj2YkmT19/8WBZ8BRIuWSoLhqmps9x+2y12q/EAWoy0CEp1GcCSj3XRbdV2hezlC4sCAhZJshVa3AARphBUQAGo4g0g59p9vNFJzxpJXfCS2c3UElFgFoJttHkMkFloEIF6+xCQmifBeRz0DBX8Bjj/H0eZzf3Xsdc5eGucn5cbPAG+dt1LU0AM0jfyv/2Knn5bVRFWGIrGAAAAAElFTkSuQmCC"""
SMB3_MARIO_SWM_R_02 = """iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAALxJREFUOE+Vk9ENwjAMRFsm6QpI/DEB6oh8MwIj8IfECkxC0FmxdXUuKeQnkXN+sXzOPOlVRHhWUhUs9+PSaNfX22ObnAyQyUyroMhrAC7+PB92PJzOE87YaUlA4SSIPdHjDqgwg3AFEsBV7AFwb93nF1PpTSOlCxmiXpaW1KCaga7eK4gkngH3HrFsHxPDe4ggvlxv4Rh68Bdg0MTuKG8q6PyNbHnIQDUAzfqvf8Z0BqgZssRBRQHY0wzvv19XThEU4DxwAAAAAElFTkSuQmCC"""
SMB3_MARIO_SWM_R_03 = """iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAALNJREFUOE+tk8sNgDAMQ4FJWAGJGyMwLyNwQ2IFJqEoEa5Maj4HegGl8UsUp3WlTxLhWqWqYJq6tsgd1w2xiyYCpJhpJyjrCgCS92X236YfKvu3Lx0JSCyyZAgRB+CEOYQ7kADu4g1g9z59rhhaLwYpXYgth8oXhwBQvssNid0ZIFsHr9UeGM3ufwPACdmBVXvZxuxgBtCq3jwPDxdDdwAqPkDkQ2KiDzIAbkVqp2HjJxEDDvQcWA6ewAySAAAAAElFTkSuQmCC"""
SMB3_MARIO_SWM_R_04 = """iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAALNJREFUOE+Nk80NgCAMhcFJXMHEmyM4ryN4M3EFJxHThpLSvga5QMrrR+lPTngVYM5IiozlWGan3e9HbJ2PBUBnTaug5ucAIn6vk4/TuiU6064WBBTtRGJxFLsAKowhOgII0FGMAHTP2dcvmtBdImEVbMj68xYYJjHoDxedALrGQX1AQCqh/R4BWu2lWf4ApBIQQK8NurFVMAQEOXBJbwDV639nhnUMqB5w2qJqwMkaidH9ByHuUQ5fGfU8AAAAAElFTkSuQmCC"""
SMB3_MARIO_WLK_R_01 = """iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAK5JREFUOE+lk8EJgDAMRauTuILgzREcwbMjihN4E1zBSaykNCUmP1iwF0vMfwk/aRN+nsbRRydu8hEgrn0H9dN5cbzoNMAVS2IGJa0BcOJ97OnaDmOgO33FgR1EKaJkFnKcARlmOoAA2cUXgP4n92VF1fqniRCCKhtSDpQp8Mh4pNJ56Ca1r+dfA5FjdAFqq16jN3uADFR7UAfYlrkUFitslq/6LdSYyBW9l4hWPzxYX1ERBp7bCQAAAABJRU5ErkJggg=="""
SMB3_MARIO_WLK_R_02 = """iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAANFJREFUOE+Fk8ENwjAMRRsm6QpI3JgAdQTOTMWZERAT9IbECkxCkKN869v5lFwaufaL879TJr2qCBeVqoL1vp+H3OX15pjXZYAszrQOa7UDAMmf59q2u8Nxsr19ackOKhdZMgoRB6DDhg4kgLv4B7D/TX0+MbUOxm8RswZ8cW49k9rJbB9sQ2zLRr/743IOjimIAbONDrBqQNKJDjbA6XqDrQViDA6wFhCSbYUePEhq/sOVkh5hDnyEt1oHTY1yeAOcYLMh3NGjrGa9x/h64f18ARRDbBFCmAfSAAAAAElFTkSuQmCC"""
SMB3_MARIOS = [SMB3_MARIO_WLK_R_01, SMB3_MARIO_WLK_R_02, SMB3_MARIO_SWM_R_01, SMB3_MARIO_SWM_R_02, SMB3_MARIO_SWM_R_03, SMB3_MARIO_SWM_R_04]
SMB3_NUMBER_IMGS = [
    """iVBORw0KGgoAAAANSUhEUgAAAAgAAAAHCAYAAAA1WQxeAAAAAXNSR0IArs4c6QAAAC5JREFUGFdjZICA/1AanWJkhEn+/4+qhhEsxcAAVgCThAki86mkAOxKPG7A6wsAobUfA63wQV8AAAAASUVORK5CYII=""",
    """iVBORw0KGgoAAAANSUhEUgAAAAYAAAAHCAYAAAArkDztAAAAAXNSR0IArs4c6QAAADNJREFUGFdjZGBg+M+ACRgZQRL//yPkGMFCDBAJEAsmiSwBFYfoIqSDAcMOmC64HegOAwD8YhYFYzLgfAAAAABJRU5ErkJggg==""",
    """iVBORw0KGgoAAAANSUhEUgAAAAgAAAAHCAYAAAA1WQxeAAAAAXNSR0IArs4c6QAAAD1JREFUGFdjZICA/1AanWJkBEn+/48pzwiWYmAAK0DXBtMAUgRRhsUUqAmoVsCMRTYRpxvA9kOtwOUDsEEAn+gWAwlpBhYAAAAASUVORK5CYII=""",
    """iVBORw0KGgoAAAANSUhEUgAAAAgAAAAHCAYAAAA1WQxeAAAAAXNSR0IArs4c6QAAADdJREFUGFeFjzESACAIw9L/P7oeoIvKwUqaggDTjxSA/TLKFSRwC04goMI+lm2oiskw3pAVzSNab/UWBA+1ZjYAAAAASUVORK5CYII=""",
    """iVBORw0KGgoAAAANSUhEUgAAAAgAAAAHCAYAAAA1WQxeAAAAAXNSR0IArs4c6QAAADZJREFUGFdjZGBg+M+AGzAyghT8/w9RwwjmggVgbMoVMKBYge4UkJVgBcgS6O6BuAoVIGtgBAC4Gx8FwM39MAAAAABJRU5ErkJggg==""",
    """iVBORw0KGgoAAAANSUhEUgAAAAgAAAAHCAYAAAA1WQxeAAAAAXNSR0IArs4c6QAAADZJREFUGFdjZGBg+M+AGzAyghT8/4+phhEsxYCqACqIbB5BExjAVqA7AWYlyERCbsBuApKJjAC0qBYFBg944wAAAABJRU5ErkJggg==""",
    """iVBORw0KGgoAAAANSUhEUgAAAAgAAAAHCAYAAAA1WQxeAAAAAXNSR0IArs4c6QAAADlJREFUGFdjZICA/1AanWJkBEn+/48pzwiWYkAogAqQbAIDihUwU2BWgvhgBWBXorkDphjsEny+AAC3vxkFFemrKAAAAABJRU5ErkJggg==""",
    """iVBORw0KGgoAAAANSUhEUgAAAAgAAAAHCAYAAAA1WQxeAAAAAXNSR0IArs4c6QAAADxJREFUGFd9jkkOACAIA9v/PxpTWYJE7YFLhwECMHxCAWZ3hiQ2MAW5kEDvy6ZS8ek5TgUQ2KPshvlHmRdPZxYE6CoPYQAAAABJRU5ErkJggg==""",
    """iVBORw0KGgoAAAANSUhEUgAAAAgAAAAHCAYAAAA1WQxeAAAAAXNSR0IArs4c6QAAACpJREFUGFdjZICA/1AanWJkhEn+/4+qhhEsxcAAVgCThAki8+lkAl5fAABLphwD4rXoBgAAAABJRU5ErkJggg==""",
    """iVBORw0KGgoAAAANSUhEUgAAAAgAAAAHCAYAAAA1WQxeAAAAAXNSR0IArs4c6QAAADhJREFUGFd9T0EKADAI0v8/2oGb0Bqri6QmRuzRwQ5kROn20BJgQ8SQdf8m+Jp0wtOhJ9gwdRi/WCyrGQO85BJQAAAAAElFTkSuQmCC""",
]
SMB3_WATER_BG_IMG = """iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAAAAXNSR0IArs4c6QAAALRJREFUaEPtl8sNgCAQRJfEAjxYAGVYkGVZkGVYgAcKINGgLlG0Adi3N1kuM5kPujmGXQyPgwAUgAVeGTB1fU6EOYZPOrS2zxmgwPy4ZdDrMoiS0OreicipAAWeQOukM/1ude/8uJ0ElED1rAReKqT2/UcBpen/iHneqX2fFWD1LQQBmgEowCgDWAAL3O8Aow4QLIAFsMD1L2B1yAAygAwgAwhBqw2QcNMCtAAtQAvQApZb4ACVJQZcANljHgAAAABJRU5ErkJggg=="""

def main(config):
    # Get the current time in 24 hour format
    location = config.get("location")
    loc = json.decode(location) if location else DEFAULT_LOCATION
    timezone = loc.get("timezone", config.get("$tz", DEFAULT_TIMEZONE))  # Utilize special timezone variable
    now = time.now()

    # Because the times returned by this API do not include the date, we need to
    # strip the date from "now" to get the current time in order to perform
    # acurate comparissons.
    # Local time must be localized with a timezone
    current_time = time.parse_time(now.in_location(timezone).format("3:04:05 PM"), format = "3:04:05 PM", location = timezone)

    # Get config values
    is_24_hour_format = config.bool("is_24_hour_format", DEFAULT_IS_24_HOUR_FORMAT)
    has_leading_zero = config.bool("has_leading_zero", DEFAULT_HAS_LEADING_ZERO)

    print_time = current_time

    speed = int(config.str("speed", DEFAULT_SPEED))
    if speed < 0:
        speed = rand(MIN_SPEED + MAX_SPEED + 1) + MAX_SPEED

    speed = speed * 5
    delay = speed * time.millisecond

    selectedGame = int(config.str("game", DEFAULT_GAME))
    levelNumber = 1
    if selectedGame == 0:
        selectedGame = random.number(1, 1)

    if selectedGame == 1:  # super mario 3 has 3 level options
        levelNumber = random.number(1, 3)

    timeBox = get_bg_image(selectedGame, levelNumber, print_time, is_24_hour_format = is_24_hour_format, has_leading_zero = has_leading_zero, has_seperator = True)

    app_cycle_speed = SECONDS_TO_RENDER * time.second
    num_frames = math.ceil(app_cycle_speed // delay)

    allFrames = []
    frames = render.Text(content="")

    for _ in range(1, 1000):
        if selectedGame == 1:
            frames = mario_get_frames(levelNumber, timeBox)
        elif selectedGame == 2:
            frames = megaman_get_frames(timeBox)
        elif selectedGame == 3:
            frames = kirby_get_frames(timeBox)

        allFrames.extend(frames)

        if len(allFrames) >= num_frames:
            break

    return render.Root(
        delay = delay.milliseconds,
        child = render.Animation(allFrames),
    )

def get_num_image(num):
    return render.Box(
        width = 8,
        height = 7,
        child = render.Image(src = base64.decode(SMB3_NUMBER_IMGS[int(num)])),
    )

def get_bg_image(game, levelNumber, t, is_24_hour_format = True, has_leading_zero = False, has_seperator = True):
    hh = t.format("03")  # Format for 12 hour time
    if is_24_hour_format == True:
        hh = t.format("15")  # Format for 24 hour time
    mm = t.format("04")  # Format for minutes
    # ss = t.format("05")  # Format for seconds

    seperator = render.Box(
        width = 3,
        height = 7,
        child = render.Image(src = base64.decode(SMB3_COLON_IMG)),
    )

    if not has_seperator:
        seperator = render.Box(
            width = 3,
        )

    hh0 = get_num_image(int(hh[0]))
    if int(hh[0]) == 0 and has_leading_zero == False:
        hh0 = render.Box(
            width = 7,
        )

    bgImg = get_smb3_bg(levelNumber)

    if game == 2:
        bgImg = render.Image(base64.decode(MM_BG_IMG))
    elif game == 3:
        bgImg = render.Image(base64.decode(KIRBY_BG_IMG))

    return render.Stack(
        children = [
            bgImg,
            render.Box(
                child = render.Row(
                    cross_align = "center",
                    children = [
                        hh0,
                        get_num_image(int(hh[1])),
                        seperator,
                        get_num_image(int(mm[0])),
                        get_num_image(int(mm[1])),
                    ],
                ),
            ),
        ],
    )

def get_smb3_bg(selectedLevel):
    if selectedLevel == 1:
        return render.Image(base64.decode(SMB3_LAND_BG_IMG))
    elif selectedLevel == 2:
        return render.Image(base64.decode(SMB3_DESERT_BG_IMG))
    else:
        return render.Image(base64.decode(SMB3_WATER_BG_IMG))

def rand(ceiling):
    return random.number(0, ceiling - 1)

def megaman_get_frames(timeBox):
    yPos = 2
    beginX = MM_MIN_X
    endX = MM_MAX_X
    step = MM_MOVE_SPEED

    frames = [
        megaman_get_frame(timeBox, xPos, yPos)
        for xPos in range(beginX, endX, step)
    ]

    return frames

def megaman_get_frame(timeBox, xPos, yPos):
    frameIndex = xPos // MM_MOVE_SPEED
    megamanFrameIndex = (frameIndex // MM_FRAMES_PER_FRAME) % 3
    megamanImage = MM_MEGAMANS[megamanFrameIndex]

    return render.Stack(
        children = [
            timeBox,
            render.Padding(
                pad = (xPos, yPos, 0, 0),
                child =
                    render.Row(
                        expanded = True,
                        children = [
                            render.Image(base64.decode(megamanImage)),
                        ],
                    ),
            ),
        ],
    )

def kirby_get_frames(timeBox):
    yPos = 11
    beginX = KIRBY_MIN_X
    endX = KIRBY_MAX_X
    step = KIRBY_MOVE_SPEED

    frames = [
        kirby_get_frame(timeBox, xPos, yPos)
        for xPos in range(beginX, endX, step)
    ]

    return frames

def kirby_get_frame(timeBox, xPos, yPos):
    frameIndex = xPos // KIRBY_MOVE_SPEED
    kirbyFrameIndex = (frameIndex // KIRBY_FRAMES_PER_FRAME) % 4
    kirbyImage = KIRBY_KIRBYS[kirbyFrameIndex]

    return render.Stack(
        children = [
            timeBox,
            render.Padding(
                pad = (xPos, yPos, 0, 0),
                child =
                    render.Row(
                        expanded = True,
                        children = [
                            render.Image(base64.decode(kirbyImage)),
                        ],
                    ),
            ),
        ],
    )

def mario_get_frames(levelNumber, timeBox):
    yPos = 10
    beginX = SMB3_MIN_X
    endX = SMB3_MAX_X
    step = SMB3_MARIO_MOVE_SPEED

    frames = [
        mario_get_frame(levelNumber, timeBox, xPos, yPos)
        for xPos in range(beginX, endX, step)
    ]

    return frames

def mario_get_frame(levelNumber, timeBox, xPos, yPos):
    frameIndex = xPos // SMB3_MARIO_MOVE_SPEED

    if levelNumber == 3:
        marioFrameIndex = (frameIndex // SMB3_MARIO_FRAMES_PER_FRAME) % 4
        marioImage = SMB3_MARIOS[marioFrameIndex + 2]
    else:
        marioFrameIndex = (frameIndex // SMB3_MARIO_FRAMES_PER_FRAME) % 2
        marioImage = SMB3_MARIOS[marioFrameIndex]

    return render.Stack(
        children = [
            timeBox,
            render.Padding(
                pad = (xPos, yPos, 0, 0),
                child =
                    render.Row(
                        expanded = True,
                        children = [
                            render.Image(base64.decode(marioImage)),
                        ],
                    ),
            ),
        ],
    )

def get_schema():
    speed_options = [
        schema.Option(display = key, value = value)
        for key, value in SPEED_LIST.items()
    ]

    game_options = [
        schema.Option(display = key, value = value)
        for key, value in GAME_LIST.items()
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "speed",
                name = "Speed",
                desc = "Change the speed of the animation.",
                icon = "gear",
                default = DEFAULT_SPEED,
                options = speed_options,
            ),
            schema.Dropdown(
                id = "game",
                name = "Game",
                desc = "Change the game displayed",
                icon = "gear",
                default = DEFAULT_GAME,
                options = game_options,
            ),
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location defining time to display and daytime/nighttime colors",
                icon = "locationDot",
            ),
            schema.Toggle(
                id = "is_24_hour_format",
                name = "24 hour format",
                icon = "clock",
                desc = "Display the time in 24 hour format.",
                default = DEFAULT_IS_24_HOUR_FORMAT,
            ),
            schema.Toggle(
                id = "has_leading_zero",
                name = "Add leading zero",
                icon = "creativeCommonsZero",
                desc = "Ensure the clock always displays with a leading zero.",
                default = DEFAULT_HAS_LEADING_ZERO,
            ),
        ],
    )
