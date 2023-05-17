"""
Applet: XScreenSaver
Summary: Hundreds of animations
Description: Shows two hundred and sixty-five different XScreenSaver animations, all scaled (way) down for the Tidbyt.
Author: Greg Knauss and XScreenSaver
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("time.star", "time")

TEST = False

FONT_NAME = "CG-pixel-3x5-mono"
FONT_ASCDES = 5 + 0
FONT_WIDTH = 4
GROUP_DEFAULT = "Default"
CACHE_SECONDS = 60
SECRET_ENCRYPTED = "AV6+xWcErarteHoMW1Ra85ucHYVzivFmMkqs8z/bLpwnLVWK66mPAY0FWu5bhkuLDQEBu5DckTDKeYHXTBTdBHqHU+B5d/rxzg0ArIA1wpoQjRi6lBMXwHYwC6wxxuyBvxPY5g8n/WzxfYz+huMqMtbn+lmVbOPzFRQ5L4gP6PvwBVF58RcbirV54oPdr9khhAKCisB3q+vj/wrmRdF2SvsRGK0iug=="
HACKS = [
    ["abstractile", "Abstractile", "Abstractile", "Mosaic patterns of interlocking tiles. Written by Steve Sundstrom; 2004.", True, ["Default", "Colorful", "All"]],
    ["anemone", "Anemone", "Anemone", "Wiggling tentacles.  Written by Gabriel Finch; 2002.", True, ["Default", "Jarring", "Weird", "All"]],
    ["anemotaxis", "Anemotaxis", "Anemotaxis", "Searches for a source of odor in a turbulent atmosphere. Written by Eugene Balkovsky; 2004.", True, ["Default", "Colorful", "All"]],
    ["ant", "Ant", "Ant", "A cellular automaton that is really a two-dimensional Turing machine: as the heads (\"ants\") walk along the screen, they change pixel values in their path. Written by David Bagley; 1997.", True, ["All"]],
    ["antinspect", "Ant Inspect", "Ant Inspect", "Ants move spheres around a circle. Written by Blair Tennessy; 2004.", False, ["All"]],
    ["antmaze", "Ant Maze", "Ant Maze", "Ants walk around a simple maze.  Written by Blair Tennessy; 2005.", False, ["All"]],
    ["antspotlight", "Ant Spotlight", "Ant Spotlight", "An ant walks over an image.  Written by Blair Tennessy; 2003.", False, ["All"]],
    ["apollonian", "Apollonian", "Apollonian", "A fractal packing of circles with smaller circles, demonstrating Descartes's theorem. Written by Allan R. Wilks and David Bagley; 2002.", True, ["Default", "Colorful", "All"]],
    ["apple2", "Apple ][", "Apple ][", "An Apple ][+ computer simulation, in all its 1979 glory. Written by Trevor Blackwell and Jamie Zawinski; 2003.", True, ["Default", "Colorful", "Nerdy", "All"]],
    ["atlantis", "Atlantis", "Atlantis", "Sharks, dolphins and whales.  Written by Mark Kilgard; 1998.", True, ["Soothing", "All"]],
    ["attraction", "Attraction", "Attraction", "Points attract each other and then repel, similar to the strong and weak nuclear forces. Written by Jamie Zawinski and John Pezaris; 1992.", True, ["Default", "All"]],
    ["atunnel", "Atunnel", "Atunnel", "Zooming through a textured tunnel. Written by Eric Lassauge and Roman Podobedov; 2003.", True, ["Default", "All"]],
    ["barcode", "Barcode", "Barcode", "Scrolling UPC-A, UPC-E, EAN-8 and EAN-13 barcodes. Written by Dan Bornstein and Jamie Zawinski; 2003.", True, ["Default", "Nerdy", "All"]],
    ["beats", "Beats", "Beats", "Draws figures that move around at a slightly different rate from each other, creating interesting chaotic and ordered patterns. Written by David Eccles; 2020.", True, ["Default", "Colorful", "All"]],
    ["binaryhorizon", "Binary Horizon", "Binary Horizon", "A system of path tracing particles evolves continuously from an initial horizon, alternating between colors. Written by Patrick Leiser, J. Tarbell and Emilio Del Tessandoro; 2021.", False, ["All"]],
    ["binaryring", "Binary Ring", "Binary Ring", "A system of path tracing particles evolves continuously from an initial creation, alternating dark and light colors. Written by J. Tarbell and Emilio Del Tessandoro; 2014.", True, ["Default", "Jarring", "All"]],
    ["blaster", "Blaster", "Blaster", "Flying space-combat robots (cleverly disguised as colored circles) do battle in front of a moving star field. Written by Jonathan Lin; 1999.", True, ["All"]],
    ["blinkbox", "Blink Box", "Blink Box", "A motion-blurred ball bounces inside a box whose tiles only become visible upon impact. Written by Jeremy English; 2003.", True, ["Default", "Colorful", "All"]],
    ["blitspin", "Blit Spin", "Blit Spin", "Repeatedly rotates an image by 90 degrees by using bitwise-logical operations. Written by Jamie Zawinski; 1992.", True, ["Default", "All"]],
    ["blocktube", "Block Tube", "Block Tube", "A swirling, falling tunnel of reflective slabs. Written by Lars R. Damerow; 2003.", True, ["Default", "All"]],
    ["boing", "Boing", "Boing", "A clone of the first graphics demo for the Amiga 1000. Written by Jamie Zawinski; 2005.", True, ["Default", "Classics", "All"]],
    ["bouboule", "Bouboule", "Bouboule", "A deforming balloon with varying-sized spots painted on its invisible surface. Written by Jeremie Petit; 1997.", True, ["Default", "All"]],
    ["bouncingcow", "Bouncing Cow", "Bouncing Cow", "A Cow. A Trampoline. Together, they fight crime. Written by Jamie Zawinski; 2003.", True, ["Default", "Weird", "All"]],
    ["boxed", "Boxed", "Boxed", "A box full of 3D bouncing balls that explode. Written by Sander van Grieken; 2002.", False, ["All"]],
    ["boxfit", "Box Fit", "Box Fit", "Packs the screen with growing squares or circles which grow until they touch, then stop. Written by Jamie Zawinski; 2005.", True, ["Default", "Colorful", "All"]],
    ["braid", "Braid", "Braid", "Inter-braided concentric circles. Written by John Neil; 1997.", True, ["Default", "Colorful", "All"]],
    ["bsod", "BSOD", "BSOD", "Blue Screen of Death: a large collection of simulated crashes from various other operating systems. Written by Jamie Zawinski; 1998.", True, ["Nerdy", "All"]],
    ["bubble3d", "Bubble 3D", "Bubble 3D", "Rising, undulating 3D bubbles, with transparency and specular reflections. Written by Richard Jones; 1998.", True, ["Default", "Soothing", "All"]],
    ["bubbles", "Bubbles", "Bubbles", "This simulates the kind of bubble formation that happens when water boils: small bubbles appear, and as they get closer to each other, they combine to form larger bubbles, which eventually pop. Written by James Macnicol; 1996.", True, ["Jarring", "All"]],
    ["bumps", "Bumps", "Bumps", "A spotlight roams across an embossed version of a loaded image. Written by Shane Smit; 1999.", False, ["All"]],
    ["cage", "Cage", "Cage", "Escher's \"Impossible Cage\". Written by Marcelo Vianna; 1998.", True, ["Default", "Nerdy", "All"]],
    ["carousel", "Carousel", "Carousel", "Loads several random images, and displays them flying in a circular formation. Written by Jamie Zawinski; 2005.", True, ["Default", "All"]],
    ["ccurve", "C Curve", "C Curve", "Generates self-similar linear fractals, including the classic \"C Curve\". Written by Rick Campbell; 1999.", True, ["Default", "Colorful", "Mathematical", "All"]],
    ["celtic", "Celtic", "Celtic", "Repeatedly draws random Celtic cross-stitch patterns. Written by Max Froumentin; 2005.", True, ["Default", "All"]],
    ["chompytower", "Chompy Tower", "Chompy Tower", "This tree's got teeth!  Written by Jamie Zawinski; 2022.", False, ["Weird", "All"]],
    ["circuit", "Circuit", "Circuit", "Electronic components float around. Written by Ben Buxton; 2001.", True, ["Nerdy", "All"]],
    ["cityflow", "City Flow", "City Flow", "Waves move across a sea of boxes. Written by Jamie Zawinski; 2014.", True, ["Default", "Jarring", "Soothing", "All"]],
    ["cloudlife", "Cloud Life", "Cloud Life", "Cloud-like formations based on a variant of Conway's Life. Written by Don Marti; 2003.", True, ["Default", "All"]],
    ["companioncube", "Companion Cube", "Companion Cube", "The symptoms most commonly produced by Enrichment Center testing are superstition, perceiving inanimate objects as alive, and hallucinations. Written by Jamie Zawinski; 2011.", True, ["Default", "Nerdy", "All"]],
    ["compass", "Compass", "Compass", "A compass, with all elements spinning about randomly, for that \"lost and nauseous\" feeling. Written by Jamie Zawinski; 1999.", True, ["Default", "Jarring", "All"]],
    ["coral", "Coral", "Coral", "Simulates colorful coral growth. Written by Frederick Roeber; 1997.", True, ["Default", "Colorful", "All"]],
    ["covid19", "COVID19", "COVID19", "SARS-CoV-2. Get vaccinated. Wear a mask. Written by Jamie Zawinski; 2020.", True, ["Jarring", "All"]],
    ["crackberg", "Crackberg", "Crackberg", "Flies through height maps, optionally animating the creation and destruction of generated tiles; tiles `grow' into place. Written by Matus Telgarsky; 2005.", True, ["Default", "Jarring", "All"]],
    ["crumbler", "Crumbler", "Crumbler", "Randomly subdivides a ball into voronoi chunks, then further subdivides one of the remaining pieces. Written by Jamie Zawinski; 2018.", True, ["Default", "All"]],
    ["crystal", "Crystal", "Crystal", "Moving polygons, similar to a kaleidoscope. Written by Jouk Jansen; 1998.", True, ["All"]],
    ["cube21", "Cube 21", "Cube 21", "The \"Cube 21\" Rubik-like puzzle, also known as \"Square-1\". Written by Vasek Potocek; 2005.", True, ["Default", "Colorful", "Nerdy", "All"]],
    ["cubenetic", "Cubenetic", "Cubenetic", "A cubist Lavalite, sort of. A pulsating set of overlapping boxes with ever-changing blobby patterns undulating across their surfaces. Written by Jamie Zawinski; 2002.", True, ["Default", "Jarring", "All"]],
    ["cubestack", "Cube Stack", "Cube Stack", "An endless stack of unfolding, translucent cubes. Written by Jamie Zawinski; 2016.", True, ["All"]],
    ["cubestorm", "Cube Storm", "Cube Storm", "Boxes change shape and intersect each other, filling space. Written by Jamie Zawinski; 2003.", True, ["All"]],
    ["cubetwist", "Cube Twist", "Cube Twist", "A series of nested cubes rotate and slide recursively. Written by Jamie Zawinski; 2016.", True, ["Default", "All"]],
    ["cubicgrid", "Cubic Grid", "Cubic Grid", "A rotating lattice of colored points. Written by Vasek Potocek; 2007.", True, ["Default", "Colorful", "All"]],
    ["cwaves", "C Waves", "C Waves", "A field of sinusoidal colors languidly scrolls. Written by Jamie Zawinski; 2007.", True, ["Default", "Soothing", "All"]],
    ["cynosure", "Cynosure", "Cynosure", "Random dropshadowed rectangles pop onto the screen in lockstep. Written by Ozymandias G. Desiderata, Jamie Zawinski, and Stephen Linhart; 1998.", True, ["Default", "All"]],
    ["dangerball", "Danger Ball", "Danger Ball", "A spiky ball. Ouch!  Written by Jamie Zawinski; 2001.", True, ["Default", "Jarring", "All"]],
    ["decayscreen", "Decay Screen", "Decay Screen", "Melts an image in various ways. Warning, if the effect continues after the screen saver is off, seek medical attention. Written by David Wald, Vivek Khera, Jamie Zawinski, and Vince Levey; 1993.", True, ["Default", "Jarring", "All"]],
    ["deco", "Deco", "Deco", "Subdivides and colors rectangles randomly, for a Mondrian-esque effect. Written by Jamie Zawinski and Michael Bayne; 1997.", True, ["Default", "Colorful", "Soothing", "All"]],
    ["deluxe", "Deluxe", "Deluxe", "Pulsing stars, circles, and lines. Written by Jamie Zawinski; 1999.", True, ["Default", "Colorful", "Jarring", "All"]],
    ["demon", "Demon", "Demon", "A cellular automaton that starts with a random field, and organizes it into stripes and spirals. Written by David Bagley; 1999.", True, ["Default", "Colorful", "Soothing", "All"]],
    ["discoball", "Discoball", "Discoball", "A dusty, dented disco ball. Woop woop. Written by Jamie Zawinski; 2016.", True, ["Default", "All"]],
    ["discrete", "Discrete", "Discrete", "Discrete map fractal systems, including variants of Hopalong, Julia, and others. Written by Tim Auckland; 1998.", True, ["Default", "All"]],
    ["distort", "Distort", "Distort", "Wandering lenses distort an image in various ways. Written by Jonas Munsin; 1998.", True, ["All"]],
    ["dnalogo", "DNA Logo", "DNA Logo", "DNA Lounge Restaurant -- Bar -- Nightclub -- Cafe -- Est. Written by Jamie Zawinski; 2001.", False, ["All"]],
    ["drift", "Drift", "Drift", "Drifting recursive fractal cosmic flames. Written by Scott Draves; 1997.", True, ["All"]],
    ["dymaxionmap", "Dymaxion Map", "Dymaxion Map", "Buckminster Fuller's map of the Earth projected onto the surface of an unfolded icosahedron. Written by Jamie Zawinski; 2016.", True, ["Default", "Nerdy", "All"]],
    ["endgame", "Endgame", "Endgame", "Black slips out of three mating nets, but the fourth one holds him tight! A brilliant composition! See also the \"Queens\" screen saver. Written by Blair Tennessy and Jamie Zawinski; 2002.", False, ["All"]],
    ["energystream", "Energy Stream", "Energy Stream", "A flow of particles which form an energy stream. Written by Eugene Sandulenko and Konrad \"Yoghurt\" Zagorowicz; 2016.", True, ["Default", "Colorful", "All"]],
    ["engine", "Engine", "Engine", "Internal combusion engines. Written by Ben Buxton, Ed Beroset and Jamie Zawinski; 2001.", False, ["All"]],
    ["epicycle", "Epicycle", "Epicycle", "A pre-heliocentric model of planetary motion. Written by James Youngman; 1998.", True, ["All"]],
    ["eruption", "Eruption", "Eruption", "Exploding fireworks. See also the \"Fireworkx\", \"XFlame\" and \"Pyro\" screen savers. Written by W.P. van Paassen; 2003.", True, ["Default", "Jarring", "All"]],
    ["esper", "Esper", "Esper", "\"Enhance 224 to 176. Pull out track right. Written by Jamie Zawinski; 2017.", True, ["Nerdy", "All"]],
    ["etruscanvenus", "Etruscan Venus", "Etruscan Venus", "A 3D immersion of a Klein bottle that smoothly deforms between the Etruscan Venus surface, the Roman surface, the Boy surface, and the Ida surface. Written by Carsten Steger; 2020.", True, ["Default", "Colorful", "Mathematical", "All"]],
    ["euler2d", "Euler 2D", "Euler 2D", "Simulates two dimensional incompressible inviscid fluid flow. Written by Stephen Montgomery-Smith; 2002.", False, ["All"]],
    ["extrusion", "Extrusion", "Extrusion", "Various extruded shapes twist and turn inside out. Written by Linas Vepstas, David Konerding, and Jamie Zawinski; 1999.", True, ["Default", "Colorful", "Mathematical", "All"]],
    ["fadeplot", "Fade Plot", "Fade Plot", "A waving ribbon follows a sinusoidal path. Written by Bas van Gaalen and Charles Vidal; 1997.", True, ["Default", "Colorful", "All"]],
    ["fiberlamp", "Fiber Lamp", "Fiber Lamp", "A fiber-optic lamp. Groovy.  Written by Tim Auckland; 2005.", True, ["Default", "Nerdy", "All"]],
    ["filmleader", "Film Leader", "Film Leader", "A looping countdown based on the SMPTE Universal Film leader on a simulation of an old analog television. Written by Jamie Zawinski; 2018.", True, ["Default", "Nerdy", "All"]],
    ["fireworkx", "Fireworkx", "Fireworkx", "Exploding fireworks. See also the \"Eruption\", \"XFlame\" and \"Pyro\" screen savers. Written by Rony B Chandran; 2004.", True, ["Default", "Colorful", "Jarring", "All"]],
    ["flag", "Flag", "Flag", "This draws a waving colored flag, that undulates its way around the screen. Written by Charles Vidal and Jamie Zawinski; 1997.", True, ["Default", "Colorful", "All"]],
    ["flame", "Flame", "Flame", "Iterative fractals.  Written by Scott Draves; 1993.", True, ["Jarring", "All"]],
    ["flipflop", "Flip Flop", "Flip Flop", "Colored tiles swap with each other. Written by Kevin Ogden and Sergio Gutierrez; 2003.", True, ["Default", "Colorful", "All"]],
    ["flipscreen3d", "Flip Screen 3D", "Flip Screen 3D", "Spins and deforms an image.  Written by Ben Buxton and Jamie Zawinski; 2001.", True, ["Default", "Jarring", "All"]],
    ["fliptext", "Flip Text", "Flip Text", "Successive pages of text flip in and out in a soothing 3D pattern. Written by Jamie Zawinski; 2005.", True, ["All"]],
    ["flow", "Flow", "Flow", "Strange attractors formed of flows in a 3D differential equation phase space. Written by Tim Auckland; 1998.", True, ["Default", "Colorful", "All"]],
    ["fluidballs", "Fluid Balls", "Fluid Balls", "A particle system of bouncing balls. Written by Peter Birtles and Jamie Zawinski; 2002.", True, ["Default", "All"]],
    ["flurry", "Flurry", "Flurry", "A colourful star(fish)like flurry of particles. Written by Calum Robinson and Tobias Sargeant; 2002.", True, ["Default", "Classics", "All"]],
    ["flyingtoasters", "Flying Toasters", "Flying Toasters", "A fleet of 3d space-age jet-powered flying toasters (and toast!) Inspired by the ancient Berkeley Systems After Dark flying toasters. Written by Jamie Zawinski and Devon Dossett; 2003.", True, ["Default", "Classics", "All"]],
    ["fontglide", "Font Glide", "Font Glide", "Puts text on the screen using large characters that glide in from the edges, assemble, then disperse. Written by Jamie Zawinski; 2003.", True, ["All"]],
    ["galaxy", "Galaxy", "Galaxy", "Spinning galaxies collide.  Written by Uli Siegmund, Harald Backert, and Hubert Feyrer; 1997.", True, ["Default", "All"]],
    ["gears", "Gears", "Gears", "Interlocking gears. See also the \"Pinion\" and \"Möbius Gears\" screen savers. Written by Jamie Zawinski; 2007.", False, ["All"]],
    ["geodesic", "Geodesic", "Geodesic", "A mesh geodesic sphere of increasing and decreasing complexity. Written by Jamie Zawinski; 2013.", True, ["Default", "Mathematical", "All"]],
    ["geodesicgears", "Geodesic Gears", "Geodesic Gears", "A set of meshed gears arranged on the surface of a sphere. Written by Jamie Zawinski; 2014.", False, ["All"]],
    ["gflux", "GFlux", "GFlux", "Undulating waves on a rotating grid. Written by Josiah Pease; 2000.", True, ["Default", "All"]],
    ["gibson", "Gibson", "Gibson", "Hacking the Gibson, as per the 1995 classic film, HACKERS. Written by Jamie Zawinski; 2020.", True, ["Default", "Nerdy", "All"]],
    ["glblur", "GL Blur", "GL Blur", "Flowing field effects from the vapor trails around a moving object. Written by Jamie Zawinski; 2002.", False, ["All"]],
    ["glcells", "GL Cells", "GL Cells", "Cells growing, dividing and dying on your screen. Written by Matthias Toussaint; 2007.", True, ["Default", "Jarring", "All"]],
    ["gleidescope", "Gleidescope", "Gleidescope", "A kaleidoscope that operates on a loaded image. Written by Andrew Dean; 2003.", True, ["Default", "Colorful", "Soothing", "All"]],
    ["glforestfire", "GL Forest Fire", "GL Forest Fire", "Draws an animation of sprinkling fire-like 3D triangles in a landscape filled with trees. Written by Eric Lassauge; 2002.", True, ["All"]],
    ["glhanoi", "GL Hanoi", "GL Hanoi", "Solves the Towers of Hanoi puzzle. Written by Dave Atkinson; 2005.", True, ["Default", "Colorful", "Soothing", "All"]],
    ["glitchpeg", "GlitchPEG", "GlitchPEG", "Loads an image, corrupts it, and then displays the corrupted version, several times a second. Written by Jamie Zawinski; 2018.", True, ["Default", "Colorful", "Jarring", "All"]],
    ["glknots", "GL Knots", "GL Knots", "Generates some twisting 3d knot patterns. Written by Jamie Zawinski; 2003.", True, ["Default", "Mathematical", "All"]],
    ["glmatrix", "GL Matrix", "GL Matrix", "The 3D \"digital rain\" effect, as seen in the title sequence of \"The Matrix\". Written by Jamie Zawinski; 2003.", True, ["Default", "Nerdy", "All"]],
    ["glplanet", "GL Planet", "GL Planet", "The Earth, bouncing around in space, rendered with satellite imagery of the planet in both sunlight and darkness. Written by David Konerding and Jamie Zawinski; 1998.", True, ["Default", "All"]],
    ["glschool", "GL School", "GL School", "A school of fish, using the classic \"Boids\" algorithm by Craig Reynolds. Written by David C. Lambert and Jamie Zawinski; 2006.", False, ["All"]],
    ["glslideshow", "GL Slideshow", "GL Slideshow", "Loads a random sequence of images and smoothly scans and zooms around in each, fading from pan to pan. Written by Jamie Zawinski and Mike Oliphant; 2003.", True, ["Default", "All"]],
    ["glsnake", "GL Snake", "GL Snake", "The \"Rubik's Snake\" puzzle. See also the \"Rubik\" and \"Cube21\" screen savers. Written by Jamie Wilkinson, Andrew Bennetts, and Peter Aylett; 2002.", True, ["Default", "Nerdy", "All"]],
    ["gltext", "GL Text", "GL Text", "A few lines of text spinning around in a solid 3D font. Written by Jamie Zawinski; 2001.", True, ["Nerdy", "All"]],
    ["goop", "Goop", "Goop", "Translucent amoeba-like blobs wander the screen. Written by Jamie Zawinski; 1997.", True, ["Default", "Colorful", "All"]],
    ["grav", "Grav", "Grav", "An orbital simulation, or perhaps a cloud chamber. Written by Greg Bowering; 1997.", False, ["All"]],
    ["gravitywell", "Gravity Well", "Gravity Well", "Massive objects distort space in a two dimensional universe. Written by Jamie Zawinski; 2019.", True, ["Default", "Nerdy", "All"]],
    ["greynetic", "Greynetic", "Greynetic", "Colored, stippled and transparent rectangles. Written by Jamie Zawinski; 1992.", True, ["Default", "Colorful", "Jarring", "All"]],
    ["halftone", "Halftone", "Halftone", "A halftone dot pattern in motion. Written by Peter Jaric; 2002.", True, ["Default", "All"]],
    ["halo", "Halo", "Halo", "Circular interference patterns. Written by Jamie Zawinski; 1993.", True, ["Default", "All"]],
    ["handsy", "Handsy", "Handsy", "A set of robotic hands communicate non-verbally. Written by Jamie Zawinski; 2018.", False, ["Weird", "All"]],
    ["headroom", "Headroom", "Headroom", "\"Back in my day, we used to say 'No future'. Written by Jamie Zawinski; 2020.", True, ["Jarring", "Nerdy", "Weird", "All"]],
    ["helix", "Helix", "Helix", "Spirally string-art-ish patterns. Written by Jamie Zawinski; 1992.", True, ["All"]],
    ["hexadrop", "Hexadrop", "Hexadrop", "A grid of hexagons or other shapes, with tiles dropping out. Written by Jamie Zawinski; 2013.", True, ["Default", "All"]],
    ["hexstrut", "Hex Strut", "Hex Strut", "A grid of hexagons composed of rotating Y-shaped struts. Written by Jamie Zawinski; 2016.", True, ["Default", "All"]],
    ["hextrail", "Hex Trail", "Hex Trail", "A network of colorful lines grows upon a hexagonal substrate. Written by Jamie Zawinski; 2022.", True, ["DefaultColorful", "All"]],
    ["hilbert", "Hilbert", "Hilbert", "The recursive Hilbert space-filling curve, both 2D and 3D variants. Written by Jamie Zawinski; 2011.", True, ["Default", "Colorful", "Mathematical", "All"]],
    ["hopalong", "Hopalong", "Hopalong", "Lacy fractal patterns based on iteration in the imaginary plane, from a 1986 Scientific American article. Written by Patrick Naughton; 1992.", True, ["Default", "All"]],
    ["hydrostat", "Hydrostat", "Hydrostat", "Wiggly squid or jellyfish with many tentacles. Written by Justin Windle and Jamie Zawinski; 2016.", True, ["Weird", "All"]],
    ["hyperball", "Hyperball", "Hyperball", "It has been replaced by the more general \"Polytopes\" screen saver, which can display this object as well as others. Written by Joe Keane; 2000.", True, ["Colorful", "All"]],
    ["hypercube", "Hypercube", "Hypercube", "It has been replaced by the more general \"Polytopes\" screen saver, which can display this object as well as others. Written by Joe Keane, Fritz Mueller, and Jamie Zawinski; 1992.", True, ["Default", "Colorful", "Mathematical", "All"]],
    ["hypertorus", "Hypertorus", "Hypertorus", "A Clifford Torus is a torus lying on the surface of a 4D hypersphere. Written by Carsten Steger; 2003.", True, ["Default", "Colorful", "Mathematical", "All"]],
    ["hypnowheel", "Hypnowheel", "Hypnowheel", "Overlapping, translucent spiral patterns. Written by Jamie Zawinski; 2008.", True, ["Default", "Soothing", "All"]],
    ["ifs", "IFS", "IFS", "Clouds of iterated function systems spin and collide. Written by Chris Le Sueur and Robby Griffin; 1997.", True, ["Default", "Jarring", "Mathematical", "All"]],
    ["imsmap", "IMS Map", "IMS Map", "Recursive cloud-like fractal patterns. Written by Juergen Nickelsen and Jamie Zawinski; 1992.", True, ["Default", "Colorful", "All"]],
    ["interaggregate", "Interaggregate", "Interaggregate", "Pale pencil-like scribbles slowly fill the screen. Written by Casey Reas, William Ngan, Robert Hodgin, and Jamie Zawinski; 2004.", True, ["Default", "Jarring", "All"]],
    ["interference", "Interference", "Interference", "Decaying sinusoidal waves make colors. Written by Hannu Mallat; 1998.", True, ["Default", "Colorful", "Soothing", "All"]],
    ["intermomentary", "Intermomentary", "Intermomentary", "Blinking dots interact with each other circularly. Written by Casey Reas, William Ngan, Robert Hodgin, and Jamie Zawinski; 2004.", True, ["Default", "All"]],
    ["jigglypuff", "Jiggly Puff", "Jiggly Puff", "Quasi-spherical objects are distorted. Written by Keith Macleod; 2003.", True, ["Colorful", "All"]],
    ["jigsaw", "Jigsaw", "Jigsaw", "Carves an image up into a jigsaw puzzle, shuffles it, and solves it. Written by Jamie Zawinski; 1997.", True, ["Default", "All"]],
    ["juggler3d", "Juggler 3D", "Juggler 3D", "A 3D juggling stick-person, with Cambridge juggling pattern notation used to describe the patterns juggled. Written by Tim Auckland and Jamie Zawinski; 2002.", True, ["Default", "Nerdy", "All"]],
    ["julia", "Julia", "Julia", "The Julia set is a close relative of the Mandelbrot set. Written by Sean McCullough; 1997.", True, ["Default", "Colorful", "Mathematical", "All"]],
    ["kaleidescope", "Kaleidescope", "Kaleidescope", "A simple kaleidoscope made of line segments. Written by Ron Tapia; 1997.", True, ["Default", "All"]],
    ["kaleidocycle", "Kaleidocycle", "Kaleidocycle", "Draw a ring composed of tetrahedra connected at the edges that twists and rotates toroidally. Written by Jamie Zawinski; 2013.", True, ["Soothing", "All"]],
    ["klein", "Klein", "Klein", "A Klein bottle is the 4D analog of a möbius strip. Written by Carsten Steger; 2008.", True, ["Mathematical", "All"]],
    ["kumppa", "Kumppa", "Kumppa", "Spiraling, spinning, and very, very fast splashes of color rush toward the screen. Written by Teemu Suutari; 1998.", True, ["Default", "Jarring", "All"]],
    ["lament", "Lament", "Lament", "Lemarchand's Box, the Lament Configuration. Written by Jamie Zawinski; 1998.", True, ["Default", "Nerdy", "All"]],
    ["laser", "Laser", "Laser", "Moving radiating lines, that look vaguely like scanning laser beams. Written by Pascal Pensa; 1997.", True, ["Default", "Colorful", "All"]],
    ["lavalite", "Lavalite", "Lavalite", "Blobs of a mysterious substance are heated, slowly rise to the top of the bottle, and then drop back down as they cool. Written by Jamie Zawinski; 2002.", True, ["Default", "Nerdy", "Soothing", "All"]],
    ["lcdscrub", "LCD Scrub", "LCD Scrub", "Repairs burn-in on LCD monitors. Written by Jamie Zawinski; 2008.", True, ["Default", "Soothing", "All"]],
    ["lightning", "Lightning", "Lightning", "Crackling fractal lightning bolts. Written by Keith Romberg; 1997.", True, ["Jarring", "All"]],
    ["lisa", "Lisa", "Lisa", "Lissajous loops. Written by Caleb Cullen; 1997.", True, ["Default", "Colorful", "Jarring", "All"]],
    ["lissie", "Lissie", "Lissie", "Lissajous loops. This one draws the progress of circular shapes along a path. Written by Alexander Jolk; 1997.", True, ["All"]],
    ["lmorph", "LMorph", "LMorph", "This generates random spline-ish line drawings and morphs between them. Written by Sverre H. Huseby and Glenn T. Lines; 1995.", True, ["Default", "Mathematical", "All"]],
    ["lockward", "Lockward", "Lockward", "A translucent spinning, blinking thing. Written by Leo L. Schwab; 2007.", True, ["Default", "All"]],
    ["loop", "Loop", "Loop", "A cellular automaton that generates loop-shaped colonies that spawn, age, and eventually die. Written by David Bagley; 1999.", True, ["All"]],
    ["m6502", "m6502", "m6502", "Emulates a 6502 microprocessor, and runs some example programs on it. Written by Stian Soreng and Jeremy English; 2007.", True, ["Nerdy", "All"]],
    ["mapscroller", "Map Scroller", "Map Scroller", "A slowly-scrolling map of a random place on Earth. Written by Jamie Zawinski; 2022.", True, ["Default", "All"]],
    ["marbling", "Marbling", "Marbling", "Marble-like or cloud-like patterns generated using Perlin Noise and Fractal Brownian Motion. Written by Jamie Zawinski and Dave Odell; 2021.", True, ["Default", "Soothing", "All"]],
    ["maze", "Maze", "Maze", "Generates random mazes, with three different algorithms: Kruskal, Prim, and a depth-first recursive backtracker. Written by Martin Weiss, Dave Lemke, Jim Randell, Jamie Zawinski, Johannes Keukelaar, and Zack Weinberg; 1985.", True, ["Default", "All"]],
    ["maze3d", "Maze 3D", "Maze 3D", "A re-creation of the 3D Maze screensaver from Windows 95. Written by Sudoer; 2018.", True, ["All"]],
    ["memscroller", "Mem Scroller", "Mem Scroller", "Scrolls a dump of its own memory in three windows at three different rates. Written by Jamie Zawinski; 2004.", True, ["Nerdy", "All"]],
    ["menger", "Menger", "Menger", "The Menger Gasket is a cube-based recursive fractal object analogous to the Sierpinski Tetrahedron. Written by Jamie Zawinski; 2001.", True, ["Default", "Nerdy", "All"]],
    ["metaballs", "Meta Balls", "Meta Balls", "2D meta-balls: overlapping and merging balls with fuzzy edges. Written by W.P. van Paassen; 2003.", True, ["Default", "Jarrying", "All"]],
    ["mirrorblob", "Mirror Blob", "Mirror Blob", "A wobbly blob distorts images behind it. Written by Jon Dowdall; 2003.", True, ["All"]],
    ["moebius", "Möbius", "Mobius", "M. C. Escher's \"Möbius Strip II\", an image of ants walking along the surface of a möbius strip. Written by Marcelo F. Vianna; 1997.", True, ["Mathematical", "All"]],
    ["moebiusgears", "Möbius Gears", "Mobius Gears", "An interlinked loop of rotating gears. Written by Jamie Zawinski; 2007.", False, ["All"]],
    ["moire", "Moiré", "Moire", "When the lines on the screen Make more lines in between, That's a moiré! Written by Jamie Zawinski and Michael Bayne; 1997.", True, ["Default", "Colorful", "All"]],
    ["moire2", "Moiré 2", "Moire 2", "Generates fields of concentric circles or ovals, and combines the planes with various operations. Written by Jamie Zawinski; 1998.", True, ["Default", "Jarring", "All"]],
    ["molecule", "Molecule", "Molecule", "Some interesting molecules. Several molecules are built in, and it can also read PDB (Protein Data Bank) files as input. Written by Jamie Zawinski; 2001.", True, ["Default", "Nerdy", "All"]],
    ["morph3d", "Morph 3D", "Morph 3D", "Platonic solids that turn inside out and get spikey. Written by Marcelo Vianna; 1997.", True, ["Default", "Colorful", "All"]],
    ["mountain", "Mountain", "Mountain", "3D plots that are vaguely mountainous. Written by Pascal Pensa; 1997.", False, ["All"]],
    ["munch", "Munch", "Munch", "DATAI 2 ADDB 1,2 ROTC 2,-22 XOR 1,2 JRST . Written by Jackson Wright, Tim Showalter, Jamie Zawinski and Steven Hazel; 1997.", True, ["Default", "Colorful", "Jarring", "All"]],
    ["nakagin", "Nakagin", "Nakagin", "The Nakagin Capsule Tower was demolished in 2022, but this version will continue to grow forever. Written by Jamie Zawinski; 2022.", True, ["Weird", "All"]],
    ["nerverot", "Nerve Rot", "Nerve Rot", "Nervously vibrating squiggles.  Written by Dan Bornstein; 2000.", True, ["Default", "Jarring", "All"]],
    ["noof", "Noof", "Noof", "Flowery, rotatey patterns.  Written by Bill Torzewski; 2004.", True, ["Default", "Colorful", "Soothing", "All"]],
    ["noseguy", "Nose Guy", "Nose Guy", "A little man with a big nose wanders around your screen saying things. Written by Dan Heller and Jamie Zawinski; 1992.", False, ["All"]],
    ["pacman", "Pac-Man", "Pac-Man", "Simulates a game of Pac-Man on a randomly-created level. Written by Edwin de Jong and Jamie Zawinski; 2004.", True, ["Default", "Nerdy", "All"]],
    ["pedal", "Pedal", "Pedal", "The even-odd winding rule. Written by Dale Moore; 1995.", True, ["All"]],
    ["peepers", "Peepers", "Peepers", "Floating eyeballs. Anatomically correct, and they also track the pointer. Written by Jamie Zawinski; 2018.", True, ["Default", "Weird", "All"]],
    ["penetrate", "Penetrate", "Penetrate", "Simulates (something like) the classic arcade game Missile Command. Written by Adam Miller; 1999.", True, ["Jarring", "All"]],
    ["penrose", "Penrose", "Penrose", "Quasiperiodic tilings. In April 1997, Sir Roger Penrose, a British math professor who has worked with Stephen Hawking on such topics as relativity, black holes, and whether time has a beginning, filed a copyright-infringement lawsuit against the Kimberly-Clark Corporation, which Penrose said copied a pattern he created (a pattern demonstrating that \"a nonrepeating pattern could exist in nature\") for its Kleenex quilted toilet paper. Written by Timo Korvola; 1997.", True, ["Default", "Soothing", "All"]],
    ["petri", "Petri", "Petri", "Colonies of mold grow in a petri dish. Written by Dan Bornstein; 1999.", True, ["Default", "All"]],
    ["phosphor", "Phosphor", "Phosphor", "An old terminal with large pixels and long-sustain phosphor. Written by Jamie Zawinski; 1999.", True, ["Default", "Nerdy", "All"]],
    ["photopile", "Photo Pile", "Photo Pile", "Loads images as polaroids and drops them in a pile. Written by Jens Kilian and Jamie Zawinski; 2008.", True, ["Default", "All"]],
    ["piecewise", "Piecewise", "Piecewise", "Moving circles switch from visibility to invisibility at intersection points. Written by Geoffrey Irving; 2003.", True, ["Default", "All"]],
    ["pinion", "Pinion", "Pinion", "A gear system marches across the screen. Written by Jamie Zawinski; 2004.", True, ["Default", "All"]],
    ["pipes", "Pipes", "Pipes", "A growing plumbing system, with bolts and valves. Written by Marcelo Vianna and Jamie Zawinski; 1997.", False, ["Classics", "All"]],
    ["polyhedra", "Polyhedra", "Polyhedra", "The 75 uniform polyhedra and their duals, plus 5 prisms and antiprisms, and some information about each. Written by Dr. Zvi Har'El and Jamie Zawinski; 2004.", True, ["Default", "Colorful", "Mathematical", "All"]],
    ["polyominoes", "Polyominoes", "Polyominoes", "Repeatedly attempts to completely fill a rectangle with irregularly-shaped puzzle pieces. Written by Stephen Montgomery-Smith; 2002.", True, ["All"]],
    ["polytopes", "Polytopes", "Polytopes", "The six regular 4D polytopes rotating in 4D. Written by Carsten Steger; 2003.", True, ["Default", "Colorful", "All"]],
    ["pong", "Pong", "Pong", "The 1971 Pong home video game, including artifacts of an old color TV set. Written by Jeremy English, Trevor Blackwell and Jamie Zawinski; 2003.", False, ["Nerdy", "All"]],
    ["popsquares", "Pop Squares", "Pop Squares", "A pop-art-ish looking grid of pulsing colors. Written by Levi Burton; 2003.", True, ["Soothing", "All"]],
    ["projectiveplane", "Projective Plane", "Projective Plane", "A 4D embedding of the real projective plane. Written by Carsten Steger; 2014.", True, ["Default", "Colorful", "Mathematical", "All"]],
    ["providence", "Providence", "Providence", "\"A pyramid unfinished. In the zenith an eye in a triangle, surrounded by a glory, proper. Written by Blair Tennessy; 2004.", True, ["Weird", "All"]],
    ["pulsar", "Pulsar", "Pulsar", "Intersecting planes, with alpha blending, fog, textures, and mipmaps. Written by David Konerding; 1999.", True, ["Default", "Colorful", "Jarring", "All"]],
    ["pyro", "Pyro", "Pyro", "Exploding fireworks. See also the \"Fireworkx\", \"Eruption\", and \"XFlame\" screen savers. Written by Jamie Zawinski; 1992.", False, ["All"]],
    ["qix", "Qix", "Qix", "Bounces a series of line segments around the screen with various presentations. Written by Jamie Zawinski; 1992.", True, ["Nerdy", "All"]],
    ["quasicrystal", "Quasi-Crystal", "Quasi-Crystal", "A quasicrystal is a structure that is ordered but aperiodic. Written by Jamie Zawinski; 2013.", True, ["Default", "Soothing", "All"]],
    ["queens", "Queens", "Queens", "The N-Queens problem: how to place N queens on an NxN chessboard such that no queen can attack a sister? See also the \"Endgame\" screen saver. Written by Blair Tennessy and Jamie Zawinski; 2002.", False, ["All"]],
    ["raverhoop", "Raver Hoop", "Raver Hoop", "Simulates an LED hula hoop in a dark room. Written by Jamie Zawinski; 2016.", True, ["Default", "Colorful", "All"]],
    ["razzledazzle", "Razzle Dazzle", "Razzle Dazzle", "Generates an infinitely-scrolling sequence of dazzle camouflage patterns. Written by Jamie Zawinski; 2018.", True, ["Default", "Nerdy", "All"]],
    ["rdbomb", "RD-Bomb", "RD-Bomb", "Reaction-diffusion: draws a grid of growing square-like shapes that, once they overtake each other, react in unpredictable ways. Written by Scott Draves; 1997.", True, ["Default", "Colorful", "Soothing", "All"]],
    ["ripples", "Ripples", "Ripples", "Rippling interference patterns reminiscent of splashing water distort a loaded image. Written by Tom Hammersley; 1999.", True, ["All"]],
    ["rocks", "Rocks", "Rocks", "An asteroid field zooms by.  Written by Jamie Zawinski; 1992.", True, ["All"]],
    ["romanboy", "Roman Boy", "Roman Boy", "A 3D immersion of the real projective plane that smoothly deforms between the Roman surface and the Boy surface. Written by Carsten Steger; 2014.", True, ["Default", "Colorful", "Mathematical", "All"]],
    ["rorschach", "Rorschach", "Rorschach", "Inkblot patterns via a reflected random walk. Written by Jamie Zawinski; 1992.", True, ["Default", "All"]],
    ["rotor", "Rotor", "Rotor", "Draws a line segment moving along a complex spiraling curve. Written by Tom Lawrence; 1997.", True, ["All"]],
    ["rotzoomer", "Rot Zoomer", "Rot Zoomer", "Distorts an image by rotating and scaling random sections of it. Written by Claudio Matsuoka and Jamie Zawinski; 2001.", True, ["Default", "All"]],
    ["rubik", "Rubik", "Rubik", "A Rubik's Cube that repeatedly shuffles and solves itself. Written by Marcelo Vianna; 1997.", True, ["Default", "Colorful", "Nerdy", "All"]],
    ["rubikblocks", "Rubik Blocks", "Rubik Blocks", "The \"Rubik's Mirror Blocks\" puzzle. Written by Vasek Potocek; 2009.", True, ["Default", "Nerdy", "All"]],
    ["sballs", "SBalls", "SBalls", "Textured balls spinning like crazy. Written by Eric Lassauge; 2002.", True, ["Default", "All"]],
    ["scooter", "Scooter", "Scooter", "Zooming down a tunnel in a star field. Written by Sven Thoennissen; 2001.", True, ["Jarring", "All"]],
    ["shadebobs", "Shade Bobs", "Shade Bobs", "Oscillating oval patterns that look something like vapor trails or neon tubes. Written by Shane Smit; 1999.", True, ["Default", "All"]],
    ["sierpinski", "Sierpinski", "Sierpinski", "The 2D Sierpinski triangle fractal. Written by Desmond Daignault; 1997.", True, ["All"]],
    ["sierpinski3d", "Sierpinski 3D", "Sierpinski 3D", "The recursive Sierpinski tetrahedron fractal. Written by Jamie Zawinski and Tim Robinson; 1999.", True, ["Default", "Mathematical", "All"]],
    ["skytentacles", "Sky Tentacles", "Sky Tentacles", "There is a tentacled abomination in the sky. Written by Jamie Zawinski; 2008.", True, ["Default", "Jarring", "Weird", "All"]],
    ["slidescreen", "Slide Screen", "Slide Screen", "A \"fifteen puzzle\" variant, dividing the image into a grid and shuffling. Written by Jamie Zawinski; 1994.", True, ["Default", "All"]],
    ["slip", "Slip", "Slip", "A jet engine consumes the image, then puts it through a spin cycle. Written by Scott Draves and Jamie Zawinski; 1997.", True, ["Jarring", "All"]],
    ["sonar", "Sonar", "Sonar", "A sonar display pings (get it?) the hosts on your local network, and plots their distance (response time) from you. Written by Jamie Zawinski and Stephen Martin; 1998.", True, ["Default", "Nerdy", "All"]],
    ["speedmine", "Speed Mine", "Speed Mine", "Simulates speeding down a rocky mineshaft, or a funky dancing worm. Written by Conrad Parker; 2001.", True, ["Jarring", "All"]],
    ["sphere", "Sphere", "Sphere", "Draws shaded spheres in multiple colors. Written by Tom Duff and Jamie Zawinski; 1982,", True, ["Colorful", "All"]],
    ["sphereeversion", "Sphere Eversion", "Sphere Eversion", "Turns a sphere inside out: a smooth deformation (homotopy). Written by Carsten Steger; 2020.", True, ["Default", "Colorful", "Mathematical", "All"]],
    ["spheremonics", "Spheremonics", "Spheremonics", "These closed objects are commonly called spherical harmonics, although they are only remotely related to the mathematical definition found in the solution to certain wave functions, most notably the eigenfunctions of angular momentum operators. Written by Paul Bourke and Jamie Zawinski; 2002.", True, ["Default", "All"]],
    ["spiral", "Spiral", "Spiral", "Moving circular moiré patterns.  Written by Peter Schmitzberger; 1997.", True, ["All"]],
    ["splitflap", "Split-Flap", "Split-Flap", "Simulates a split-flap display, an old style of electromechanical sign as seen in airports and train stations, and commonly used in alarm clocks in the 1960s and 1970s. Written by Jamie Zawinski; 2015.", True, ["Nerdy", "All"]],
    ["splodesic", "Splodesic", "Splodesic", "A geodesic sphere experiences a series of eruptions. Written by Jamie Zawinski; 2016.", True, ["Default", "Jarring", "All"]],
    ["spotlight", "Spotlight", "Spotlight", "A spotlight scanning across a black screen, illuminating a loaded image when it passes. Written by Rick Schultz and Jamie Zawinski; 1999.", True, ["Default", "All"]],
    ["sproingies", "Sproingies", "Sproingies", "Slinky-like creatures walk down an infinite staircase and occasionally explode! Written by Ed Mackey; 1997.", True, ["Jarring", "Weird", "All"]],
    ["squiral", "Squiral", "Squiral", "Square-spiral-producing automata. Written by Jeff Epler; 1999.", True, ["Default", "Colorful", "All"]],
    ["squirtorus", "Squirtorus", "Squirtorus", "A scrolling landscape vents toroidal rainbows into the sky. Written by Jamie Zawinski; 2022.", True, ["Weird", "All"]],
    ["stairs", "Stairs", "Stairs", "Escher's infinite staircase. Written by Marcelo Vianna and Jamie Zawinski; 1998.", True, ["Default", "Nerdy", "All"]],
    ["starfish", "Starfish", "Starfish", "Undulating, throbbing, star-like patterns pulsate, rotate, and turn inside out. Written by Jamie Zawinski; 1997.", True, ["Default", "All"]],
    ["starwars", "Star Wars", "Star Wars", "A stream of text slowly scrolling into the distance at an angle, over a star field, like at the beginning of the movie of the same name. Written by Jamie Zawinski and Claudio Matsuoka; 2001.", True, ["Default", "Nerdy", "All"]],
    ["stonerview", "Stoner View", "Stoner View", "Chains of colorful squares dance around in spirals. Written by Andrew Plotkin; 2001.", True, ["Default", "All"]],
    ["strange", "Strange", "Strange", "Strange attractors: a swarm of dots swoops and twists around. Written by Massimino Pascal; 1997.", False, ["All"]],
    ["substrate", "Substrate", "Substrate", "Crystalline lines grow on a computational substrate. Written by J. Tarbell and Mike Kershaw; 2004.", True, ["Default", "All"]],
    ["superquadrics", "Superquadrics", "Superquadrics", "Morphing 3D shapes.  1997. Written by Ed Mackey; 1987,", True, ["Default", "Colorful", "Mathematical", "All"]],
    ["surfaces", "Surfaces", "Surfaces", "Parametric surfaces. Written by Andrey Mirtchovski and Carsten Steger; 2003.", True, ["Default", "Colorful", "Mathematical", "All"]],
    ["swirl", "Swirl", "Swirl", "Flowing, swirly patterns. Written by M. Written by M.  Dobie and R. Taylor; 1997.", True, ["Default", "Soothing", "All"]],
    ["t3d", "T3D", "T3D", "Draws a working analog clock composed of floating, throbbing bubbles. Written by Bernd Paysan; 1999.", True, ["All"]],
    ["tangram", "Tangram", "Tangram", "Solves tangram puzzles. Written by Jeremy English; 2005.", True, ["Default", "Nerdy", "All"]],
    ["tessellimage", "Tessellimage", "Tessellimage", "Converts an image to triangles using Delaunay tessellation, or to polygons using Voronoi tesselation, and animates the result at various depths. Written by Jamie Zawinski; 2014.", True, ["All"]],
    ["thornbird", "Thornbird", "Thornbird", "This fractal is among those generated by \"Discrete\". Written by Tim Auckland; 2002.", True, ["All"]],
    ["timetunnel", "Time Tunnel", "Time Tunnel", "An animation similar to the title sequence of Dr. Written by Sean P. Brennan; 2005.", True, ["Default", "Nerdy", "All"]],
    ["topblock", "Top Block", "Top Block", "Creates a 3D world with dropping blocks that build up and up. Written by rednuht; 2006.", True, ["Default", "Colorful", "Nerdy", "All"]],
    ["triangle", "Triangle", "Triangle", "Generates random mountain ranges using iterative subdivision of triangles. Written by Tobias Gloth; 1997.", True, ["All"]],
    ["tronbit", "Tron Bit", "Tron Bit", "The character \"Bit\" from the film, \"Tron\". Written by Jamie Zawinski; 2011.", True, ["Default", "Nerdy", "All"]],
    ["truchet", "Truchet", "Truchet", "Line- and arc-based truchet patterns that tile the screen. Written by Adrian Likins; 1998.", True, ["Default", "Jarring", "All"]],
    ["twang", "Twang", "Twang", "Divides the screen into a grid, and plucks them. Written by Dan Bornstein; 2002.", True, ["Jarring", "All"]],
    ["unicrud", "Unicrud", "Unicrud", "Chooses a random Unicode character and displays it full screen, along with some information about it. Written by Jamie Zawinski; 2016.", True, ["Nerdy", "All"]],
    ["unknownpleasures", "Unknown Pleasures", "Unknown Pleasures", "PSR B1919+21 (AKA CP 1919) was the first pulsar ever discovered: a spinning neutron star emitting a periodic lighthouse-like beacon. Written by Jamie Zawinski; 2013.", True, ["Nerdy", "All"]],
    ["vermiculate", "Vermiculate", "Vermiculate", "Squiggly worm-like paths.  Written by Tyler Pierce; 2001.", True, ["Default", "Colorful", "Jarring", "All"]],
    ["vfeedback", "VFeedback", "VFeedback", "Simulates video feedback: pointing a video camera at an NTSC television. Written by Jamie Zawinski; 2018.", True, ["Default", "All"]],
    ["vidwhacker", "Vid Whacker", "Vid Whacker", "Distorts an image using a random series of filters: edge detection, subtracting the image from a rotated version of itself, etc. Written by Jamie Zawinski; 1998.", True, ["All"]],
    ["vigilance", "Vigilance", "Vigilance", "Security cameras keep careful track of their surroundings. Written by Jamie Zawinski; 2017.", True, ["All"]],
    ["vines", "Vines", "Vines", "Generates a continuous sequence of small, curvy geometric patterns. Written by Tracy Camp and David Hansen; 1997.", True, ["Default", "Colorful", "Jarring", "All"]],
    ["voronoi", "Voronoi", "Voronoi", "A Voronoi tessellation. Periodically zooms in and adds new points. Written by Jamie Zawinski; 2007.", True, ["Default", "Soothing", "All"]],
    ["wander", "Wander", "Wander", "A colorful random-walk. Written by Rick Campbell; 1999.", True, ["Default", "Colorful", "All"]],
    ["webcollage", "Web Collage", "Web Collage", "This is what the Internet looks like. Written by Jamie Zawinski; 1998.", True, ["Default", "All"]],
    ["whirlwindwarp", "Whirlwind Warp", "Whirlwind Warp", "Floating stars are acted upon by a mixture of simple 2D force fields. Written by Paul 'Joey' Clark; 2001.", True, ["Colorful", "All"]],
    ["whirlygig", "Whirlygig", "Whirlygig", "Zooming chains of sinusoidal spots. Written by Ashton Trey Belew; 2001.", True, ["Default", "Colorful", "All"]],
    ["winduprobot", "Windup Robot", "Windup Robot", "A swarm of wind-up toy robots wander around the table-top, bumping into each other. Written by Jamie Zawinski; 2014.", True, ["Default", "Nerdy", "All"]],
    ["worm", "Worm", "Worm", "Draws multicolored worms that crawl around the screen. Written by Brad Taylor, Dave Lemke, Boris Putanec, and Henrik Theiling; 1991.", True, ["Default", "Colorful", "All"]],
    ["wormhole", "Wormhole", "Wormhole", "Flying through a colored wormhole in space. Written by Jon Rafkind; 2004.", True, ["Default", "All"]],
    ["xanalogtv", "XAnalogTV", "XAnalogTV", "An old TV set, including artifacts like snow, bloom, distortion, ghosting, and hash noise. Written by Trevor Blackwell; 2003.", True, ["Default", "All"]],
    ["xflame", "XFlame", "XFlame", "Pulsing fire. It can also take an arbitrary image and set it on fire too. Written by Carsten Haitzler and many others; 1999.", True, ["Default", "All"]],
    ["xjack", "XJack", "XJack", "A novel by Jack Torrance.  Written by Jamie Zawinski; 1997.", True, ["All"]],
    ["xlyap", "XLyap", "XLyap", "The Lyapunov exponent makes pretty fractal pictures. Written by Ron Record; 1997.", True, ["Default", "Soothing", "All"]],
    ["xmatrix", "XMatrix", "XMatrix", "The \"digital rain\" effect, as seen on the computer monitors in \"The Matrix\". Written by Jamie Zawinski; 1999.", True, ["Default", "Nerdy", "All"]],
    ["xrayswarm", "XRaySwarm", "XRaySwarm", "Worm-like swarms of particles with vapor trails. Written by Chris Leger; 2000.", True, ["Default", "Jarring", "All"]],
    ["xspirograph", "XSpirograph", "XSpirograph", "Simulates that pen-in-nested-plastic-gears toy from your childhood. Written by Rohit Singh; 2000.", True, ["All"]],
    ["zoom", "Zoom", "Zoom", "Fatbits! Zooms in on a part of an image and scrolls, distorting each pixel with its own lens. Written by James Macnicol; 2001.", True, ["Default", "All"]],
]

def main(config):
    # If anything goes wrong, we can always show the first hack
    hack = 0

    # If we were sent a hack...
    if config.get("hack"):
        # ...by number on the command-line, always render it
        hacks = []
        for _ in HACKS:
            hacks.append(([_[0], _[1], _[2]]))
        hack = int(config.get("hack"))

    elif config.get("hackname"):
        # ...by name on the command-line, always render it
        hacks = []
        index = 0
        for _ in HACKS:
            hacks.append(([_[0], _[1], _[2]]))
            if config.get("hackname") == _[0]:
                hack = index
            index += 1

    else:
        # If we weren't sent a hack, assemble the list of enabled hacks by group
        hacks = []
        for _ in HACKS:
            if (TEST and _[0] == config.get("show", HACKS[0][0])) or \
               (not TEST and (config.get("group", GROUP_DEFAULT) in _[5]) and config.bool("hack_" + _[0], _[4])):
                hacks.append(([_[0], _[1], _[2]]))

        # If there are none, show an error message and tell the user how to fix it
        if len(hacks) == 0:
            return render.Root(
                child = render.WrappedText(
                    content = "XScreenSaver: Nothing is enabled. Add some!",
                    align = "left",
                ),
            )

        # Randomly pick a hack every X seconds
        random.seed(time.now().unix // CACHE_SECONDS)
        hack = random.number(0, len(hacks) - 1)

    # If we're running from the command line, give some feedback on what we're running
    if (config.get("hack") or config.get("hackname")):
        print("Hack %s: %s" % (hack, hacks[hack]))

    # Check to see if the animation is cached (we cache by name because the number means something different depending on what's enabled)
    gif = cache.get("gif_%s" % (hacks[hack][0]))
    if gif != None:
        # If so, decode and use it
        gif = base64.decode(gif)

    else:
        # If not, pull the GIF from the remote source
        response = http.get(
            "https://xscreensaver.eod.com/" + config.get("hackfile", hacks[hack][0]) + ".gif",
            headers = {"X-XScreenSaver-Token": secret.decrypt(SECRET_ENCRYPTED) or config.get("SECRET_LOCAL")},
        )

        # If something went wrong, show an error
        if response.status_code != 200:
            return render.Root(
                child = render.WrappedText(
                    content = "XScreenSaver: %d for %s. That's bad." % (response.status_code, hacks[hack][2]),
                    align = "left",
                ),
            )

        # Otherwise, cache the result
        gif = response.body()

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set("gif_%s" % (hacks[hack][0]), base64.encode(gif), ttl_seconds = CACHE_SECONDS)

    # Render the GIF
    children = [
        render.Image(
            src = gif,
        ),
    ]

    # If they want a name over it, add that
    if config.bool("name", False):
        # Decide if the name is too big and we need to scroll it
        scroll = True if len(hacks[hack][2]) >= (64 / FONT_WIDTH) else False

        # Render an outline in black and the name itself in white
        name = []
        for x in [0, 1, 2]:
            for y in [0, 1, 2]:
                name.append(
                    render.Padding(
                        pad = (64 + x, 32 - 3 - FONT_ASCDES + y, 0, 0) if scroll else (x, 32 - 3 - FONT_ASCDES + y, 0, 0),
                        child = render.Text(
                            content = hacks[hack][2],
                            font = FONT_NAME,
                            color = "#000",
                        ),
                    ),
                )
        name.append(
            render.Padding(
                pad = (64 + 1, 32 - 3 - FONT_ASCDES + 1, 0, 0) if scroll else (0 + 1, 32 - 3 - FONT_ASCDES + 1, 0, 0),
                child = render.Text(
                    content = hacks[hack][2],
                    font = FONT_NAME,
                    color = "#FFF",
                ),
            ),
        )

        # If we're scrolling the name...
        if scroll:
            # Do it
            children.append(
                render.Marquee(
                    width = 64,
                    child = render.Stack(
                        children = name,
                    ),
                ),
            )

        else:
            # Otherwise, show it in the right-lower corner
            children.append(
                render.Row(
                    main_align = "end",
                    expanded = True,
                    children = [
                        render.Stack(
                            children = name,
                        ),
                    ],
                ),
            )

    # And render the full display, GIF with optional name on top
    return render.Root(
        # HACK: Set the animation speed from the GIF, otherwise it's hard-coded at 50ms per frame;
        # this has the unhappy side effect of moving any scrolled names at different speeds, but...
        delay = children[0].delay,
        child = render.Stack(
            children = children,
        ),
    )

def group_test(group):
    # Build a dropdown for all the hacks in the current group

    hacks = []
    for _ in HACKS:
        if group in _[5]:
            hacks.append(
                schema.Option(
                    display = _[1],
                    value = _[0],
                ),
            )

    return [
        schema.Dropdown(
            id = "show",
            name = "Animation",
            desc = "Select an animation to run.",
            icon = "ballotCheck",
            options = hacks,
            default = hacks[0].value,
        ),
    ]

def group_real(group):
    # Build toggles for all the hacks in the current group

    toggles = []
    for _ in HACKS:
        if group in _[5]:
            toggles.append(
                schema.Toggle(
                    id = "hack_" + _[0],
                    name = _[1],
                    desc = _[3],
                    icon = "display",
                    default = _[4],
                ),
            )
    return toggles

def get_schema():
    # Build a list of all the groups
    groups = []
    for _ in ["All", "Default", "Classics", "Colorful", "Jarring", "Mathematical", "Nerdy", "Soothing", "Weird"]:
        groups.append(
            schema.Option(
                display = _,
                value = _,
            ),
        )

    # The collection of settable options, starting with whether to show the hack's name
    fields = [
        schema.Toggle(
            id = "name",
            name = "Name",
            desc = "Show the name of the animation.",
            icon = "signature",
            default = False,
        ),
    ]

    # If we're in test mode...
    if TEST:
        fields += [
            schema.Dropdown(
                id = "group",
                name = "Group",
                desc = "Select the animations from a pre-defined group.",
                icon = "layerGroup",
                options = groups,
                default = GROUP_DEFAULT,
            ),
            schema.Generated(
                id = "hacks",
                source = "group",
                handler = group_test,
            ),
        ]

    else:
        fields += [
            schema.Dropdown(
                id = "group",
                name = "Group",
                desc = "Select the animations from a pre-defined group.",
                icon = "layerGroup",
                options = groups,
                default = GROUP_DEFAULT,
            ),
            schema.Generated(
                id = "hacks",
                source = "group",
                handler = group_real,
            ),
        ]

    # And hand the options to the system
    return schema.Schema(
        version = "1",
        fields = fields,
    )
