"""
Applet: Dothraki WotD
Summary: Dothraki word of the day
Description: Display a random Dothraki word of the day.
Author: tavdog
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("html.star", "html")
load("http.star", "http")
load("render.star", "render")
load("time.star","time")
load("random.star","random")

date_int = int(str(time.now())[0:10].replace('-',''))

random.seed(int(str(time.now())[0:10].replace('-','')))

# regex to conert tsv to array
# ^(\w+)\t(\w+.)\t(.*$)
# ['$1','$2','$3'],

word_array = [  ["k'athsavari",	'adv.',	'often'],
                ['anha','pron.','I'],
                ['yer','pron.','you (informal)'],
                ['shafka','pron.','you (formal)'],
                ['me','pron.','she, he, it'],
                ['kisha','pron.','we'],
                ['yeri','pron.','you (plural)'],
                ['mori','pron.','they'],
                ['fin','pron.','who'],
                ['fini','pron.','what'],
                ['finne','adv.','where'],
                ['affin','adv.','when'],
                ['kifindirgi','adv.','why'],
                ['kifinosi','adv.','how'],
                ['finsanneya','pron.','how many'],
                ['akkate','adv.','both'],
                ['akka','adv.','also'],
                ['alle','adv.','further'],
                ['atte','adv.','first'],
                ['check','adv.','well'],
                ['disse','adv.',''],
            ]

def render_error():
    return render.Root(
        render.WrappedText("Something went wrong getting today's word!"),
    )

def main():
    print("Starting")

#    word_index = random.number(0,len(word_array))
    word_index = len(word_array)
    word = word_array[word_index][0]
    definition = word_array[word_index][1] + ' ' + word_array[word_index][2]

    return render.Root(
        child = render.Column(
            children = [
                render.Marquee(
                    child = render.Column(
                        children = [
                            render.WrappedText(
                                content = word,
                                color = "#00eeff",
                                font = "5x8",
                            ),
                            render.WrappedText(
                                content = definition,
                                font = "5x8",
                            ),
                        ],
                    ),
                    height = 25,
                    offset_start = 23,
                    scroll_direction = "vertical",
                ),
                render.Box(
                    height = 1,
                    color = "#fa0",
                ),
                render.Text(
                    content = "Dothraki WotD",
                    height = 6,
                    font = "CG-pixel-3x5-mono",
                ),
            ],
        ),
        delay = 140,
    )
