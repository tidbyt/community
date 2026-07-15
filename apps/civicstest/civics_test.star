"""
civics_test.star — USCIS Civics Test for Tidbyt (Pixlet / Starlark)

Displays one USCIS civics question per day (changes daily):
  1) Waving American flag (sine-wave pixel animation)
  2) "QUESTION" title card
  3) The question text (scrolls vertically if long)
  4) "ANSWER" title card
  5) The answer text (scrolls vertically if long)

Run locally:   pixlet serve civics_test.star
Render to web: pixlet render civics_test.star
Push to device:
  pixlet render civics_test.star
  pixlet push $TIDBYT_DEVICE_ID civics_test.webp --api-token $TIDBYT_API_KEY --installation-id civicstest
"""

load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# ---------------------------------------------------------------------------
# Data: 128 USCIS civics questions with one concise, screen-friendly answer.
# (Questions with "answers will vary" / "see uscis.gov" use a short stand-in.)
# ---------------------------------------------------------------------------
QUESTIONS = [
    ("What is the form of government of the United States?", "Republic"),
    ("What is the supreme law of the land?", "The U.S. Constitution"),
    ("Name one thing the U.S. Constitution does.", "Forms the government"),
    ("What does \"We the People\" mean?", "People govern themselves"),
    ("How are changes made to the U.S. Constitution?", "Amendments"),
    ("What does the Bill of Rights protect?", "Basic rights of Americans"),
    ("How many amendments does the U.S. Constitution have?", "Twenty-seven (27)"),
    ("Why is the Declaration of Independence important?", "It says all people are created equal"),
    ("What founding document said the colonies were free from Britain?", "Declaration of Independence"),
    ("Name two important ideas from the Declaration and Constitution.", "Liberty and equality"),
    ("\"Life, Liberty, and the pursuit of Happiness\" are in what document?", "Declaration of Independence"),
    ("What is the economic system of the United States?", "Capitalism / free market"),
    ("What is the rule of law?", "No one is above the law"),
    ("Many documents influenced the Constitution. Name one.", "Declaration of Independence"),
    ("There are three branches of government. Why?", "So one part doesn't get too powerful"),
    ("Name the three branches of government.", "Legislative, executive, judicial"),
    ("The President is in charge of which branch?", "Executive branch"),
    ("What part of the federal government writes laws?", "Congress"),
    ("What are the two parts of the U.S. Congress?", "Senate and House"),
    ("Name one power of the U.S. Congress.", "Writes laws"),
    ("How many U.S. senators are there?", "One hundred (100)"),
    ("How long is a term for a U.S. senator?", "Six (6) years"),
    ("Who is one of your state's U.S. senators now?", "(Varies) your state's senator"),
    ("How many voting members are in the House of Representatives?", "Four hundred thirty-five (435)"),
    ("How long is a term for a member of the House?", "Two (2) years"),
    ("Why do representatives serve shorter terms than senators?", "To follow public opinion more closely"),
    ("How many senators does each state have?", "Two (2)"),
    ("Why does each state have two senators?", "Equal representation"),
    ("Name your U.S. representative.", "(Varies) your representative"),
    ("Who is the Speaker of the House now?", "See uscis.gov/citizenship/testupdates"),
    ("Who does a U.S. senator represent?", "People of their state"),
    ("Who elects U.S. senators?", "Citizens of their state"),
    ("Who does a member of the House represent?", "People of their district"),
    ("Who elects members of the House?", "Citizens of their district"),
    ("Some states have more representatives than others. Why?", "Because of the state's population"),
    ("The President is elected for how many years?", "Four (4) years"),
    ("The President can serve only two terms. Why?", "Because of the 22nd Amendment"),
    ("What is the name of the President now?", "See uscis.gov/citizenship/testupdates"),
    ("What is the name of the Vice President now?", "See uscis.gov/citizenship/testupdates"),
    ("If the president can no longer serve, who becomes president?", "The Vice President"),
    ("Name one power of the president.", "Signs bills into law"),
    ("Who is Commander in Chief of the U.S. military?", "The President"),
    ("Who signs bills to become laws?", "The President"),
    ("Who vetoes bills?", "The President"),
    ("Who appoints federal judges?", "The President"),
    ("The executive branch has many parts. Name one.", "The Cabinet"),
    ("What does the President's Cabinet do?", "Advises the President"),
    ("What are two Cabinet-level positions?", "Secretary of State; Attorney General"),
    ("Why is the Electoral College important?", "It decides who is elected president"),
    ("What is one part of the judicial branch?", "Supreme Court"),
    ("What does the judicial branch do?", "Reviews laws"),
    ("What is the highest court in the United States?", "Supreme Court"),
    ("How many seats are on the Supreme Court?", "Nine (9)"),
    ("How many Supreme Court justices are usually needed to decide a case?", "Five (5)"),
    ("How long do Supreme Court justices serve?", "For life"),
    ("Supreme Court justices serve for life. Why?", "To be independent of politics"),
    ("Who is the Chief Justice of the United States now?", "See uscis.gov/citizenship/testupdates"),
    ("Name one power only for the federal government.", "Print money / declare war"),
    ("Name one power only for the states.", "Provide schooling / police"),
    ("What is the purpose of the 10th Amendment?", "Powers not given to the U.S. belong to the states/people"),
    ("Who is the governor of your state now?", "(Varies) your governor"),
    ("What is the capital of your state?", "(Varies) your state capital"),
    ("Describe one amendment about who can vote.", "Citizens 18 and older can vote"),
    ("Who can vote, run for federal office, and serve on a jury?", "U.S. citizens"),
    ("What are three rights of everyone living in the U.S.?", "Speech, religion, assembly"),
    ("What do we show loyalty to in the Pledge of Allegiance?", "The United States / the flag"),
    ("Name two promises new citizens make in the Oath of Allegiance.", "Defend the Constitution; obey U.S. laws"),
    ("How can people become United States citizens?", "Be born in the U.S. or naturalize"),
    ("What are two examples of civic participation?", "Vote; join a political party"),
    ("What is one way Americans can serve their country?", "Vote; pay taxes; obey the law"),
    ("Why is it important to pay federal taxes?", "Required by law; civic duty"),
    ("Why should men 18-25 register for Selective Service?", "Required by law"),
    ("The colonists came to America for many reasons. Name one.", "Freedom; religious freedom"),
    ("Who lived in America before the Europeans arrived?", "American Indians / Native Americans"),
    ("What group of people was taken and sold as slaves?", "Africans"),
    ("What war did Americans fight to win independence from Britain?", "American Revolution"),
    ("Name one reason Americans declared independence from Britain.", "Taxation without representation"),
    ("Who wrote the Declaration of Independence?", "(Thomas) Jefferson"),
    ("When was the Declaration of Independence adopted?", "July 4, 1776"),
    ("Name one important event of the American Revolution.", "Declaration of Independence"),
    ("There were 13 original states. Name five.", "Virginia, New York, Georgia, Delaware, Massachusetts"),
    ("What founding document was written in 1787?", "The U.S. Constitution"),
    ("Name one writer of the Federalist Papers.", "(James) Madison / (Alexander) Hamilton / (John) Jay"),
    ("Why were the Federalist Papers important?", "They helped people support the Constitution"),
    ("Benjamin Franklin is famous for many things. Name one.", "U.S. diplomat; first Postmaster General"),
    ("George Washington is famous for many things. Name one.", "First president of the United States"),
    ("Thomas Jefferson is famous for many things. Name one.", "Wrote the Declaration of Independence"),
    ("James Madison is famous for many things. Name one.", "\"Father of the Constitution\""),
    ("Alexander Hamilton is famous for many things. Name one.", "First Secretary of the Treasury"),
    ("What territory did the U.S. buy from France in 1803?", "Louisiana Territory"),
    ("Name one war fought by the U.S. in the 1800s.", "Civil War"),
    ("Name the U.S. war between the North and the South.", "The Civil War"),
    ("The Civil War had many important events. Name one.", "Emancipation Proclamation"),
    ("Abraham Lincoln is famous for many things. Name one.", "Freed the slaves; 16th president"),
    ("What did the Emancipation Proclamation do?", "Freed the slaves in the Confederacy"),
    ("What U.S. war ended slavery?", "The Civil War"),
    ("What amendment made people born in the U.S. citizens?", "14th Amendment"),
    ("When did all men get the right to vote?", "With the 15th Amendment (1870)"),
    ("Name one leader of the women's rights movement in the 1800s.", "Susan B. Anthony"),
    ("Name one war fought by the U.S. in the 1900s.", "World War II"),
    ("Why did the U.S. enter World War I?", "Germany attacked U.S. ships"),
    ("When did all women get the right to vote?", "1920 (19th Amendment)"),
    ("What was the Great Depression?", "Longest economic recession in modern history"),
    ("When did the Great Depression start?", "The stock market crash of 1929"),
    ("Who was president during the Depression and WWII?", "(Franklin) Roosevelt"),
    ("Why did the U.S. enter World War II?", "Japan attacked Pearl Harbor"),
    ("Dwight Eisenhower is famous for many things. Name one.", "General in WWII; 34th president"),
    ("Who was the U.S. main rival during the Cold War?", "Soviet Union / USSR"),
    ("During the Cold War, what was one main U.S. concern?", "Communism"),
    ("Why did the U.S. enter the Korean War?", "To stop the spread of communism"),
    ("Why did the U.S. enter the Vietnam War?", "To stop the spread of communism"),
    ("What did the civil rights movement do?", "Fought to end racial discrimination"),
    ("Martin Luther King, Jr. is famous for many things. Name one.", "Fought for civil rights"),
    ("Why did the U.S. enter the Persian Gulf War?", "To force Iraq's military out of Kuwait"),
    ("What major event happened on September 11, 2001?", "Terrorists attacked the United States"),
    ("Name one U.S. military conflict after 9/11.", "War in Afghanistan (War on Terror)"),
    ("Name one American Indian tribe in the United States.", "Cherokee, Navajo, Sioux, Apache, Hopi"),
    ("Name one example of an American innovation.", "The light bulb"),
    ("What is the capital of the United States?", "Washington, D.C."),
    ("Where is the Statue of Liberty?", "New York Harbor (Liberty Island)"),
    ("Why does the flag have 13 stripes?", "There were 13 original colonies"),
    ("Why does the flag have 50 stars?", "One star for each of the 50 states"),
    ("What is the name of the national anthem?", "The Star-Spangled Banner"),
    ("\"E Pluribus Unum\" means what?", "Out of many, one"),
    ("What is Independence Day?", "A holiday celebrating U.S. independence"),
    ("Name three national U.S. holidays.", "Independence Day, Thanksgiving, Memorial Day"),
    ("What is Memorial Day?", "Honors soldiers who died in service"),
    ("What is Veterans Day?", "Honors people who served in the military"),
]

# ---------------------------------------------------------------------------
# Colors
# ---------------------------------------------------------------------------
RED = "#b22234"
WHITE = "#ffffff"
NAVY = "#3c3b6e"
BLACK = "#000000"
GOLD = "#ffd24a"

FRAME_MS = 100
FPS = 1000 // FRAME_MS

DISPLAY_W = 64
DISPLAY_H = 32
CONTENT_W = DISPLAY_W - 2  # 1px padding each side
CONTENT_H = DISPLAY_H - 2

CANTON_W = 26
CANTON_H = 17

SCROLL_THRESHOLD = 60  # chars beyond which text scrolls instead of centers

TOTAL_S = 15  # total animation duration in seconds

# Percentage of TOTAL_S per section — must sum to 100
FLAG_PCT = 10  #  ~1.5s
LABEL_PCT = 5  #  ~0.75s each (applied twice)
Q_PCT = 40  #  ~6s
A_PCT = 40  #  ~6s

# ---------------------------------------------------------------------------
# Question pick — stable for the day, changes daily
# ---------------------------------------------------------------------------
def pick_question():
    day = int(time.now().format("20060102"))
    return QUESTIONS[day % len(QUESTIONS)]

# ---------------------------------------------------------------------------
# Flag rendering — pixel-column sine wave animation
# ---------------------------------------------------------------------------

# sin(2*pi*i/64) * 256 for i in 0..63 (integer lookup, no math lib needed)
SIN64 = [
    0,
    25,
    50,
    74,
    98,
    121,
    142,
    162,
    181,
    198,
    213,
    226,
    237,
    245,
    251,
    255,
    256,
    255,
    251,
    245,
    237,
    226,
    213,
    198,
    181,
    162,
    142,
    121,
    98,
    74,
    50,
    25,
    0,
    -25,
    -50,
    -74,
    -98,
    -121,
    -142,
    -162,
    -181,
    -198,
    -213,
    -226,
    -237,
    -245,
    -251,
    -255,
    -256,
    -255,
    -251,
    -245,
    -237,
    -226,
    -213,
    -198,
    -181,
    -162,
    -142,
    -121,
    -98,
    -74,
    -50,
    -25,
]

# Cumulative y-bounds for the 13 flag stripes (heights sum to 32px)
STRIPE_BOUNDS = [0, 3, 5, 8, 10, 13, 15, 18, 20, 23, 25, 28, 30, 32]
STRIPE_COLORS = [RED, WHITE, RED, WHITE, RED, WHITE, RED, WHITE, RED, WHITE, RED, WHITE, RED]

def stripe_color(y):
    for i in range(len(STRIPE_COLORS)):
        if y < STRIPE_BOUNDS[i + 1]:
            return STRIPE_COLORS[i]
    return RED

def flag_pixel(x, y):
    if y < 0 or y >= DISPLAY_H:
        return BLACK
    if x < CANTON_W and y < CANTON_H:
        # Canton: NAVY with a 4px-grid of white star dots (2px inset from top-left)
        cx = x - 2
        cy = y - 2
        if cx >= 0 and cy >= 0 and cx % 4 == 0 and cy % 4 == 0:
            return WHITE
        return NAVY
    return stripe_color(y)

def flag_column(x, frame):
    # 2 sine wavelengths across the 64px width; wave travels right each frame
    phase = (x * 2 - frame * 4) % 64
    d = SIN64[phase] * 3 // 256  # ±3px vertical offset
    boxes = []
    run_color = ""
    run_len = 0
    for r in range(DISPLAY_H):
        c = flag_pixel(x, r - d)
        if c == run_color:
            run_len += 1
        else:
            if run_len > 0:
                boxes.append(render.Box(width = 1, height = run_len, color = run_color))
            run_color = c
            run_len = 1
    if run_len > 0:
        boxes.append(render.Box(width = 1, height = run_len, color = run_color))
    return render.Column(children = boxes)

def flag_wave_frame(frame):
    columns = []
    for x in range(DISPLAY_W):
        columns.append(flag_column(x, frame))
    return render.Row(children = columns)

# ---------------------------------------------------------------------------
# Text screens
# ---------------------------------------------------------------------------
def label_screen(label, color):
    return render.Box(
        width = DISPLAY_W,
        height = DISPLAY_H,
        color = BLACK,
        child = render.Text(label, font = "tb-8", color = color),
    )

def content_screen(text, color):
    wrapped = render.WrappedText(content = text, width = CONTENT_W, font = "tom-thumb", color = color, align = "center")
    if len(text) <= SCROLL_THRESHOLD:
        # Short enough to fit: center vertically within the content area
        inner = render.Box(
            width = CONTENT_W,
            height = CONTENT_H,
            child = render.Column(
                main_align = "center",
                cross_align = "center",
                children = [wrapped],
            ),
        )
    else:
        # Too long to guarantee fit: scroll vertically
        inner = render.Marquee(height = CONTENT_H, scroll_direction = "vertical", child = wrapped)
    return render.Box(
        width = DISPLAY_W,
        height = DISPLAY_H,
        color = BLACK,
        child = render.Padding(pad = 1, child = inner),
    )

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def add_held_frames(frames, screen, count):
    for _ in range(count):
        frames.append(screen)

def main(_):
    if FLAG_PCT + LABEL_PCT * 2 + Q_PCT + A_PCT != 100:
        fail("Time percentages must sum to 100")

    q, a = pick_question()

    total_frames = TOTAL_S * FPS
    flag_frames = total_frames * FLAG_PCT // 100
    label_hold = total_frames * LABEL_PCT // 100
    q_hold = total_frames * Q_PCT // 100
    a_hold = total_frames * A_PCT // 100

    frames = []
    for f in range(flag_frames):
        frames.append(flag_wave_frame(f))

    add_held_frames(frames, label_screen("QUESTION", GOLD), label_hold)
    add_held_frames(frames, content_screen(q, WHITE), q_hold)
    add_held_frames(frames, label_screen("ANSWER", GOLD), label_hold)
    add_held_frames(frames, content_screen(a, WHITE), a_hold)

    return render.Root(
        delay = FRAME_MS,
        show_full_animation = True,
        child = render.Animation(children = frames),
    )

# ---------------------------------------------------------------------------
# Schema (configuration in the Tidbyt app)
# ---------------------------------------------------------------------------
def get_schema():
    return schema.Schema(version = "1", fields = [])
