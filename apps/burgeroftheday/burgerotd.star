"""
Applet: Burger of the Day
Summary: Shows Burger of the Day
Description: Display the set Burger of the Day, show a random burger every time, or enter your own custom burger. Burgers courtesy of Bob's Burgers. Use the "Show logo" and "Scroll speed" options to fit your Tidbyt.
Author: Kyle Stark @kaisle51
Thanks: @whyamihere @dinotash @inxi @J.R. @Milx
"""

load("encoding/base64.star", "base64")
load("render.star", "render")
load("schema.star", "schema")
load("math.star", "math")
load("time.star", "time")
load("random.star", "random")

#64 x 19
BOBS_LOGO = base64.decode("""
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
""")

#insert image base64 in empty line below
#64 x 21
BURGER_TEXT = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAVCAYAAAD2KuiaAAAAAXNSR0IArs4c6QAAAVJJREFUWIXtV8sOwzAIa6r9/y9np1SUGuM8umlafZlGEjAOkG3b/hzl2wTuQq21RmullCPvV68je3gVqchnFJslZ/cxv23tIkCWcFu3dnTG2tp3hVBkUy8iE8fzOQRAibHDyO4JRHsZoeZjptIQovxOFYCCIuWzG1WIsHheTBZHEbj5RHvpDMjKcBRKZVjSas/7swqXkwBMcUvijhKNoMRRK0VqMZ+ovwF0G2idfXof0d4s4YyDcpa2wExpqT4Z2LAdAeKf/g6ISK1qgUxUNoOiSsiGq0WXAJ7MrAiKDzsM0V7lhWAv166QRH2rvvERKesj8qMOwMyHFcLvowI0xayCGSEFXgRP1gqTtUfDaPzdGrPpqQRSfiQpYo4kpsSjQ5C9/z0vQi/xTDS01vPU2RgXexQgc6wMRGtHvS+TXFQJCFSAHjKfJr4K9P/1LyTw4MEc3v0o5AJHTjj7AAAAAElFTkSuQmCC
""")

BURGER_LIST = ['"New bacon-ings"','Never Been Feta','Foot Feta-ish Burger','The Life of the Parsley Burger','Sweet Chili O\' Mine Burger','Itsy Bitsy Teeny Weenie Yellow Polka-Dot Zucchini Burger','Hit Me With Your Best Shallot Burger','Focaccia red handed burger','So Many Fennel So Little Thyme Burger','THE FINDERS CAPERS BURGER','Emergency Eggs-it Burger','Sweet Home Avocado Burger','The stayin\' a chive burger','Let\'s Give \'em Something Shiitake \'bout Burger','Chile Relleno- You-Didn\'t Burger','Pear Goes the Neighborhood','Salvador Cauliflower Burger','Fig Lebowski Burger','Cole came, cole slaw, cole conquered Burger','Breaking Radish Burger','Captain Pepper Jack Marrow Burger','Little Swiss Bunshine Burger','Take A Leek Burger','The ber-gouda triangle burger','The little sprouts on the prairie burger','She\'s a Super Leek Burger','Use It Or Bleus It Burger','THE HICKORY CHICORY GUAC BURGER','Chorizo Your Own Adventure Burger','Chard To A Crisp Burger','THE SEALED WITH A SWISS BURGER','Topless the Morning To You Burger','50 Ways to Leave Your Guava Burger','THE I LOVE YOU JUST THE WHEY YOU ARE BURGER','The eggplant one on me burger','Every Breath You Tikka Masala Burger','Nothing Compares 2 Bleu (Cheese) Burger','The Here I Am Broccoli Like a Hurricane Burger','Better cauliflower saul burger','Don\'t Go Brocking My Heart Burger','I Heartichoke You Burger','The Shut Up and Swiss Me Burger','A Good Manchego is Hard to Find Burger','MY BLOODY KALE-ENTINE BURGER','Be My Valen-thyme Burger','THE I HATE TO SEE YOU BRIE-VE BUT I LOVE TO WATCH YOU GO BURGER','Step up 2: the beets burger','Girls Just Wanna Have Fennel Burger','Don\'t You Four Cheddar \'Bout Me Burger','The Don\'t Get Creme Fraiche With Me Burger','Curry On My Wayward Bun Burger','Nice guys spinach last burger','The marvelous mrs. basil burger','Parme- jean-claude van hamburger','Bruschetta Bout It Burger','Tarragon in Sixty Seconds Burger','Poutine on the Ritz Burger','The Oh Con-Pear Burger','Say It Ain\'t Cilantro Burger','Chevre Which Way But Loose Burger','THE TWO LEFT BEET BURGER','The Older with More Eggs- perience Burger','Eggers Can\'t Be Cheesers Burger','Edamame Dearest Burger','Pickle My Funny Bone Burger','The I\'m Getting Too Old For This Shishito Burger','Burger A La Mode','Open Sesame Burger','THE FIGGY SMALLS BURGER','A wrinkle in thyme burger','Chipotle Off the Old Block Burger','Don\'t Give Me No Chive Burger','Frisee It, Don\'t Spray It Burger','Turn the Other Leek Burger','Where Have You Bean All My Life Burger','The into thin heirloom burger','The happy paint patty\'s day burger','I Mint to Do That Burger','Totally Radish Burger','Mushroom With A View Burger','It\'s Only Sourdough Burger','Cajun Gracefully Burger','The Hand That Rocks the Bagel Burger','Olive And Let Die Burger','Wasabi My Guest Burger','THE COLBY BY YOUR NAME BURGER','The creme fraiche prince of bell peppers burger','The Garden of E-dumb Burger','What\'s The Worce- stershire That Could Happen Burger','To Err Is Cumin Burger','The you can lead a horseradish to watercress burger','Take Me Out To The Burger','National Pass-Thyme Burger','A Leek of Their Own Burger','Put Me in Poached Burger','Fig-eta Bout It Burger','Pepper Don\'t Preach Burger','Creminis and Misdemeanies Burger','Poblano Picasso Burger','Enoki Dokie Burger','MediterrAin\'t Misbehavin\' Burger','Sharp Cheddar Dressed Man BURGER','Barley Davidson Burger','The green a little bean of me burger','Sprouts! Sprouts! Sprouts It All Out! Burger','Snipwrecked Burger','THE DILL CRAZY AFTER ALL THESE GRUYERES BURGER','The Choys are Bok in Town Burger','Papaya Was A Rolling Stone Burger','These Collards Don\'t Run Burger','Do the Brussel Burger','Onion Ring Around the Rosemary Burger','The oaxaca waka waka burger','Parma Parma Parma Chameleon Burger','The mo, larry, and curry burger','Curd-fect Strangers Burger','Peas and Thank You Burger','THE WHAT IF PEAPOD WAS ONE OF US BURGER','Knife to Beet You Burger','Is This Your Chard Burger','The Glass Fromagerie Burger','Citizen Kale Burger','The should I sautee or should i mango burger','Total Eclipse of the Havarti Burger','Shoestring Around the Rosey Burger','Mission A-Corn- Plished Burger','Scent of a Cumin Burger','Baby got bak choy burger','The Grand Brie Burger','Parm-pit Burger','If You\'ve Got It, Croissant It Burger','Last of the Mo-Jicama Burger','Endive Had the Time of My Life Burger','Not If I Can Kelp It Burger','The mama said there\'d be glaze like this burger','Sit and Spinach Burger','All In A Glaze Work Burger','Weekend at Bearnaise Burger','I Know Why the Cajun Burger Sings','The Stop or My Mom Will Shoots Burger','Thank God It\'s Fried Egg Burger','The Sun\'ll Come Out To-Marrow Burger','If Looks Could Kale Burger','If At First You Sesame Seed, Thai, Thai, Again Burger','The Saffron Saff-off Burger','Gourdon- Hamsey Burger','Sympathy for the Deviled Egg Burger','Onion-tended Consequences Burger','The rye of the storm burger','Who Wants To Be A Scallionaire Burger?','The bustle and flow burger','Bet it all on black garlic burger','Teriyaki a New One Burger','THE CHEVRE LITTLE THING SHE DOES IS MAGIC BURGER','The twisted swiss-ster burger','My Farro Lady Burger','Woulda Coulda Gouda Burger','You Gouda Be Kidding Me Burger','As Gouda As It Gets Burger','Gouda Gouda Gumdrops Burger','A Few Gouda Men Burger','Gouda Gouda Two Shoes Burger','Gouda Day Sir Burger','Parsnips- Vous Francais Burger','Sweaty Palms Burger','Tangled Up in Blueberry Burger','The Gouda Wife Burger','Take a bite out of lime burger','This is what it sounds like when cloves fry burger','Do Fry for Me Argentina Burger','The fleetwood jack burger','The deep blue brie burger','Summer Thyme Burger','I Know What You Did Last Summer Squash Burger','The 500 Glaze of Summer Burger','It\'s My Havarti and I\'ll Rye If I Want To burger','Bleu is the Warmest Cheese Burger','The Blanc Canvas Burger','Blondes Have More Fun-gus Burger','We\'re Here We\'re Gruyere, Get Used to It Burger','Free To Brie You and Me Burger','Chili Wonka Burger','Glory Glory Jalapeño Burger','Fingerling Brothers and Barnum and Bay Leaves Burger','The for butter or for wurst burger','View to a Kielbasa Dog','The Heirloom Where it Happens Burger','TURMERIC-A THE BEAUTIFUL BURGER','Freedom of Choys Burger','The Six Scallion Dollar Man Burger','The if it\'s yellow let it portobello burger','The Full Head of Heir-loom Tomato Burger','We Bought a Zucchini Burger','The Olive What She\'s Having Burger','Son of a peach-er man burger','You Won\'t Believe It\'s Not Butternut- squash Burger','Bright leeks, big city burger','It\'s chive o\'clock some-pear burger','The Paprika Smurf Burger','THE ALL HOT AND COLLARD BURGER','Edward James Olive-most Burger','The Rosemary\'s Baby Spinach Burger','Shishito Corleone Burger','The you had me at hellokra burger','Do the cremini, do the thyme burger','Portobello the Belt Burger','THE AROUND THE WORLD IN EIGHTY DATES BURGER','Full nettle jacket burger','Step Into the Okra-tagon Burger','Medium Snare Burger','I\'d Be Cheddar Off Literally Anywhere But Here Burger!','Beet-er Late Than Never','Throw cardamom-ma from the train burger','The fifty glaze to eat your burger','To Thine Own Self be Bleu Burger','Corned Identity Burger','THE MUSH-AROOM ABOUT NOTHING BURGER','It Takes Two to Mango burger','THE DRAGONFRUIT ME TO HELL BURGER','THE LAND OF THE SLAW-ST BURGER','The throw your hands in the heirloom burger','The pea-brie\'s big adventure burger','Aw Nuts Burger','When Harry Met Salami Burger','Krauted House Burger','Asiago for broke burger','Top Bun Burger','The Say Cheese Burger','It Takes Bun to Know Bun Burger','Heads Shoulders Knees and Tomatoes Burger','I\'m Picklish Burger','Runny Out of Thyme Burger','Chutney the Front Door Burger','The fleetwood jack burger','The straight and marrow burger','The Gorgon-baby -gone burger','The Final Kraut Down Burger','THE THROW YOUR HANDS IN THE GRUYERE BURGER','The One Yam Band Burger','The \'shroom where it happens burger','Walk This Waioli Burger','The thin red pepper burger','Ready or not here i plum burger','THE JUDGE BRINE-HOLD BURGER','She\'ll be Coming \'round the Plantain Burger','The hawk and chickpeas burger','Happy banana- versary burger','The bleu collard burger','The easy come, asiago burger','The guac! or my mom will shoot burger','The Don\'t Dream It\'s Okra Burger','The rib long and prosper burger','The Longest Chard Burger','Smells Like Bean Spirit Burger','The Troy Oinkman Burger','The thousand chard stare burger','Cloves encounters burger','Kale Mary Burger','The random jacks of chive-ness burger','I\'m Gonna Get You Succotash Burger','The Frankie goes to hollandaise burger','The ruth tomater ginsburger','The Wasabi with You Burger','Take a picture fig\'ll last longer','Judy Garlic Burger','The almond butters band burger','The glazed and infused burger','One Fish, Two Fish, Red Fish Hamburger','THE COPS AND RABE-ERS BURGER','Shake Your Honeymaker Burger','Beets of Burden Burger','I bean of greenie burger','The unbreakable kimchi schmidt burger','Avoca-don\'t you want me baby? burger','The Jack-O-Lentil Burger','THE HUNT FOR RED ONION-TOBER BURGER','Onion Burger - Grilled...  To Death!','Muenster Under the Bun Burger','The pecorino on someone your own size burger','Two Karat Burger','The chimichurri up and wait burger','Rest in Peas Burger','Butterface Burger','LITTLE CHOP OF HORSERADISH BURGER','The 28 maize later burger','The corn-juring two burger','Texas Chainsaw Massa-curd Burger','The if I \nhad a (pumper) nickel burger','Kales From the Crypt Burger','THE DEVIL\'S AVOCADO-CATE BURGER','It\'s fun to eat at the rYe MCA Burger','The Human Polenta-pede Burger','Riding in Cars with \nBok Choys','Grandpa Muenster Burger','Caper the Friendly Goat Cheese Burger','Grin and carrot burger','The chili-delphia story burger','Paranormal Pepper Jack-tivity Burger','The leek-y cauldron burger','Shoot out at the Okra Corral Burger','MURDER, KIMCHI WROTE BURGER','I\'ve Created a Muenster Burger','The night-pear \non elm beet burger','The Cauli- flower\'s Cumin from Inside the House Burger','The what we dill in the shadows burger','Corn This Way Burger','Ruta-Bag-A Burger','Livin\' on a pear burger','The Baby You Can Chive My Car Burger','You Spinach Me Right Round Spinach Burger','The chimi-churri you can\'t be serious burger','The what\'s the matter-horn burger','THE ABSENTEE SHALLOT BURGER','Camembert-ly Legal Burger','The groove is in the chard burger','Burger she goat','The goat tell it on the mountain burger','Band On The Bun Burger','House of 1000 pork-ses burger','Sub- conscious Burger','The lost in yam-slation burger','The Mad Flax Curry Road burger','In ricotta da vida burger','ONE FLEW OKRA THE COUSCOUS NEST BURGER','Only the Provolonely Burger','Stilton crazy after all these gruyeres burger','The Sound & The Curry Burger','You\'re Kimchi the Best Burger','Bohemian Radishy Burger','The Catch Me If You Cran Burger','I stilton haven\'t found what thyme looking for burger','Graters of the sauced havart(i) burger','The tikka look at me now burger','Charbroil Fair Burger','The Yam Ship Burger','One Horse Open Slaw Burger','Jingle bell peppers rock burger','Let it snow peas Burger','I Fought the Slaw Burger','Walking in a Winter Comes-with- cran Burger','It came upon a midnight gruyere burger','Bleu by You Burger','The What\'s Kala-mata with You Burger','Santa Claus Is Cumin to Town Burger','The hollandaise ro-o-oh-o-oh- o-oh-oh-oh- oll burger','The Ebeneezer Bleu-ge Burger','THE SMILLA\'S SENSE OF SNOWPEAS BURGER','Winter Muensterland Burger with Muenster cheese','Passion of the Cress Burger','You cheddar watch out, you cheddar on rye burger','Jingle Bell Pepper Burger','Away in a Mango Burger','Home for the Challah-Days Burger','You can\'t fight City Challa Burger','Your cress is on my list burger','The challah and the chive-y burger','The Silentil Night Burger','THE SANTA SLAWS IS COMING TO TOWN BURGER','Twas the Nut Before Christmas Burger','Cheeses is Born Burger','The Pear Tree Burger','The fried off into the sunset burger','Good Night and Good Leek Burger','Fifth Day of Christmas Burger','Celery-brate good times, come on! burger','Havarti Like It\'s 1999 Burger']

BURGER_PAR_LIST = ['(comes with bacon)','','','','','','','(on focaccia with beets)','(comes with lots of fennel, no thyme)','','','','','','','(comes with a side of pear salad)','','','','(comes with a slice of Radish)','','(Comes on a buttered bun)','(Comes with sautéed leeks)','','','(Comes with braised leeks)','(Comes with Bleu Cheese)','','','','','','','','','','','','','(with broccoli and artichoke hearts)','','','','','','','','','(Comes with four kinds of cheddar)','','','','','','','','(Comes with poutine fries)','','(Doesn\'t come with cilantro. Because cilantro is terrible.)','','','(aged burger with a fried egg on top)','(with fried egg and cheese)','(comes with edamame)','','','(Comes with ice cream - Not on top)','(Served open-faced on a sesame seed bun)','','','','(served with no chives)','','','(Comes with Baked Beans)','','(whiskey brushed patty)','(Comes with mint relish)','(Comes with Radish)','(Porcini on a double decker)','(But I Like It)','','(comes with an everything bagel)','','','','','(Served with Crapple)','','','','(Comes with Peanuts and Crackerjacks)','','','(comes with a poached egg)','','','(comes with cremini mushrooms)','','(Comes with enoki mushrooms)','','(Comes with sharp cheddar)','(comes on a barley roll)','','','(comes with parsnips)','','','','','(Comes with brussel sprouts)','','(comes with oaxaca cheese)','(with Parmesan crisp)','','(Comes with cheese curds)','','','(with Thinly Sliced Beets)','','','','(comes with sauteed onions and mango salsa)','','','(Comes with Corn Salsa)','','','','(Comes with Parmesan)','','(Comes with Jicama)','','','(comes with a wor- cestershire glaze)','','(Served with Balsamic Glaze)','','','(comes with pea shoots)','','(comes with bone marrow)','','','','(Comes with squash and ham)','','','(served with a balsamic drizzle on a rye bun)','','(served with Brussel sprouts)','','','','','','','','','','','(It comes with shoes)','','','(Comes with hearts of palm)','(comes with a blueberry compote)','(comes with Mature Gouda)','(with lime chutney)','(with fried garlic cloves)','','(comes with sweet little fries pies, jack cheese)','(comes with blue cheese and brie)','','','(comes with Pomegranate Glaze)','','','(comes with a fromage blanc)','(Comes with mushrooms)','','','','','','(with butter pickles and sausage)','','','','(comes with bok choy)','','(with yellow peppers and portobello mushrooms)','','','','(comes with peach glaze)','(served with zucchini)','(comes with grilled leeks)','','(comes with blue potato fries)','','','','(comes with shishito peppers)','','','','','(comes with sauteed nettles)','','','(comes with aged cheddar)','','','','(served with bleu cheese)','(comes with corned beef)','','','','(Comes with pickle slaw)','','(pea protein burger w/Brie)','(comes with peanut butter)','','','','(comes on our best seven-grain bun)','','(comes on a fancy bun)','','(comes with pickles)','(comes with a runny fried egg)','(Comes with Mango Chutney)','(comes with sweet little pies, jack cheese)','(comes with marrow)','(comes with gorgonzola cheese)','(Comes with sauerkraut)','','(Comes with yams)','','(comes with wasabi aioli)','','','','','','(9 is divisible by 3)','','','','','','','','(Served with bacon)','(comes with thousand island dressing and swiss chard)','','(served with kale)','(with monterrey jack cheese and chives)','','','(comes with heirloom tomatoes and pickled ginger)','','','','(comes with toasted almond butter)','(bourbon glazed and infused with bacon)','','(Topped with Broccoli Rabes)','(Comes with Honey Mustard)','','(comes with black bean parsley puree)','','','','','','','(comes with pecorino crisps)','(Comes with two carrots)','','','(served with butter lettuce)','','(comes with corn salsa)','(comes with even more corn salsa)','','','','','(Comes on Rye w/ Mustard, Cheese & Avocado)','','','(10% Senior Discount)','(served with capers & feta)','','','','','','','','(comes with pear and beet relish)','(Comes with cauliflower and cumin)','','','','','','','','(with swiss cheese crisps)','(Comes with crispy shallots)','','','(comes with goat cheese)','(comes with goat cheese)','(Comes with Wings)','(topped with ham and bacon)','(on a sub roll)','','','','','(Comes with provolone)','','','','','(served with cranberry sauce)','','','','(Comes with Parlsey, Sage, Rosemary, and Thyme)','(comes with yams)','(Comes with slaw, no horse)','','','(And the Slaw Won)','(comes with cranberry sauce)','','(with locally sourced bleu cheese)','','(with cumin)','(comes with hollandaise sauce on a kaiser roll)','','','(Side of snow peas)','','','','','(Comes on a challah roll)','(comes on a Challah roll)','(comes with watercress)','','(Comes with lentils)','','(comes with walnut aioli)','(Comes with baby swiss)','(with sliced pears - partridge not included)','(comes with a fried egg)','','(Comes with five golden rings of onion)','','']

DEFAULT_BURGER_NAME = "New bacon-ings"
DEFAULT_BURGER_PAR = "Comes with bacon"
BURGER_NAME = ""
BURGER_PAR = ""
YEAR = time.now().year

#remove leap day burger from lists if it's not a leap year
def checkIfNotLeapYear():
    if (YEAR % 4 != 0) or (YEAR % 100 == 0):
        BURGER_LIST.pop(59)
        BURGER_PAR_LIST.pop(59)

checkIfNotLeapYear()

def main(config):
    def showBobsLogo():
        if config.bool("show_logo", True):
            return render.Padding(
                render.Image(
                    src = BOBS_LOGO,
                    width = 62,
                    height = 20
                ),
                pad = 1
            )
        else:
            return 

    TIME_ZONE = config.get("$tz", "America/New_York")
    DEFAULT_TIME = time.now().in_location(TIME_ZONE).format("2006-01-02T15:04:05Z07:00")
    CURRENT_YEAR = str(time.now().year)
    FIRST_DAY = time.parse_time(CURRENT_YEAR + "-01-01T01:01:01Z")
    DAYS_SINCE_JAN1 = time.now().in_location(TIME_ZONE) - FIRST_DAY
    DAYS_NUMBER = math.floor(DAYS_SINCE_JAN1.hours / 24)
    RANDOM_NUMBER = random.number(0, 365)
    BURGER_SHOWN = config.get("burger_shown", "daily")
    SCROLL_SPEED = config.str("scroll_speed", "60")

    if BURGER_SHOWN == "random":
        BURGER_NAME = BURGER_LIST[RANDOM_NUMBER]
        BURGER_PAR = BURGER_PAR_LIST[RANDOM_NUMBER]
    elif BURGER_SHOWN == "daily":
        BURGER_NAME = BURGER_LIST[DAYS_NUMBER]
        BURGER_PAR = BURGER_PAR_LIST[DAYS_NUMBER]
    elif BURGER_SHOWN == "custom":
        BURGER_NAME = config.str("custom_name", DEFAULT_BURGER_NAME)
        BURGER_PAR = config.str("custom_ingredients", DEFAULT_BURGER_PAR)
    else:
        BURGER_NAME = DEFAULT_BURGER_NAME
        BURGER_PAR = DEFAULT_BURGER_PAR

    return render.Root(
        delay = int(SCROLL_SPEED),
        child = render.Column(
            children = [
                render.Marquee(
                    offset_start = 32,
                    offset_end = 32,
                    width = 64,
                    height = 32,
                    scroll_direction = "vertical",
                    child = 
                        render.Column(
                            children = [
                                showBobsLogo(),
                                render.Padding(
                                    render.Image(
                                        src = BURGER_TEXT,
                                        width = 64,
                                        height = 21
                                    ), pad = (0, 3, 0, 0)
                                ),
                                render.Box(
                                    render.Row(
                                        expanded = True,
                                        main_align="space_evenly",
                                        children = [
                                            render.Text(
                                                content = 'OF THE DAY',
                                                color = "#fff",
                                            ),
                                        ],
                                    ),
                                    width = 64,
                                    height = 8,
                                ),
                                render.Box(
                                    color = "#000",
                                    child = render.Box(
                                        width = 38,
                                        height = 1,
                                        color="#fff",
                                    ),
                                    width = 64,
                                    height = 3,
                                ),
                                render.Padding(
                                    render.WrappedText(
                                        content = BURGER_NAME.upper(),
                                        width = 60,
                                        color = "#fff",
                                    ), pad = (3, 6, 3, 1)
                                ),
                                render.Padding(
                                    render.WrappedText(
                                        content = BURGER_PAR.lower(),
                                        width = 60,
                                        color = "#fff", 
                                    ), pad = (3, 0, 3, 2)
                                ),
                                render.Box(
                                    render.Row(
                                        expanded = True,
                                        main_align="space_evenly",
                                        children = [
                                            render.Text(
                                                content = '$5.95',
                                                font = "6x13",
                                            ),
                                        ],
                                    ),
                                    width = 64,
                                    height = 13,
                                ),
                            ],
                        ), 
                ),
            ]
        ),
    )

def get_schema():
    scroll_speed = [
        schema.Option(display = "Slow", value = "200"),
        schema.Option(display = "Normal", value = "100"),
        schema.Option(display = "Fast (Default)", value = "60"),
        schema.Option(display = "Faster", value = "30"),
    ]
    burger_shown = [
        schema.Option(display = "Daily", value = "daily"),
        schema.Option(display = "Random", value = "random"),
        schema.Option(display = "Custom", value = "custom"),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "show_logo",
                name = "Show logo",
                desc = "Show or hide the Bob's Burgers show logo",
                icon = "sign-hanging",
                default = True,
            ),
            schema.Dropdown(
                id = "burger_shown",
                name = "Burger shown",
                desc = "Burgers to show",
                icon = "burger",
                default = burger_shown[0].value,
                options = burger_shown,
            ),
            schema.Text(
                id = "custom_name",
                name = "Custom burger",
                desc = "Custom burger",
                icon = "pencil",
                default = DEFAULT_BURGER_NAME,
            ),
            schema.Text(
                id = "custom_ingredients",
                name = "Custom ingredients",
                desc = "Custom ingredients",
                icon = "pencil",
                default = DEFAULT_BURGER_PAR,
            ),
            schema.Dropdown(
                id = "scroll_speed",
                name = "Scroll speed",
                desc = "Text scrolling speed",
                icon = "person-running",
                default = scroll_speed[2].value,
                options = scroll_speed,
            ),
        ],
    )