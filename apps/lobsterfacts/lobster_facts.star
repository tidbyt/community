"""
Applet: Lobster Facts
Summary: Random Lobster Facts
Description: Displays a random lobster fact.
Author: Marc ten Bosch
"""

load("encoding/base64.star", "base64")
load("random.star", "random")
load("render.star", "render")
load("time.star", "time")

THE_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABgAAAAVCAYAAABc6S4mAAABUElEQVQ4ja1VPU8DMQx10lv4EDOia4XE1LFi7MDQH8DPut/TkbFi7IoEMxsVe9XqRXL06sZJQPVyPvvs9+zYuTCOo0BWm/Vh/bwKeOIdenJ0CsdpLrwnAHVCvj9+0/P+8a4bBPEcp4L4yE4Y9APYGLg3uZLS+MjMtTRm8dfkbIMMtQQJVE7PhsvvIVEFYBBmldgXbE0ATcY2lA77cvue3t/mi6zL64swiG0PJNqee6xCCEXdEmRiyH2yBzY5T1RJPD9PU25ROkjTHgTiY22TB26njgdg8BxiDpJBrF6bqOoUcVXMlPXWuMaa084+Ep+N66a+7W4FfGFBL203+71K3ApKwVxB783bbBEn0okq+TzJe9AS3ZP97USmDzeXu4uYIZ9D74+pCsDb/RMHeZpdJ/3zayfxEORqH/Jt++8KVJA8H3znTdoE4EVjlp79TETkCC/EGgFV8sV4AAAAAElFTkSuQmCC
""")

FACTS = [
    "Male European lobsters live to 31 years old, and females to 54. One particularly long-lived female had was found to be 72 years old",
    "Lobsters' leg and feet hairs identify food. Small antennae in front of their eyes are used for tracking down food that’s farther away.",
    "Lobsters claws can exert pressure of up to 100 pounds per square inch.",
    "Lobster fishermen throw back lobsters that are too small and lobsters that are too big. The small ones need to grow, while the large ones add vigor to the gene pool.",
    "Lobsters can swim forward and backward. When they’re alarmed, they scoot away in reverse by rapidly curling and uncurling their tails.",
    "Spiny Caribbean lobsters have no claws. Instead, they have many spines on their carapace and two long antennae on their heads for protection.",
    "Lobsters were once so plentiful that after a storm they would wash ashore in deep piles.",
    "When lobsters mate, the eggs aren’t fertilized right away. The female carries the male’s sperm and chooses when to fertilize her eggs.",
    "Lobsters can spend a limited amount of time outside of the water, and survive up to 36 hours.",
    "Lobsters can grow back lost limbs. For bigger limbs such as their claws, it can take the lobster years to regain them completely.",
    "While our eyes perceive our surroundings by refracting light, the lobsters’ eyes reflect light. Generally, lobsters only detect motion instead of seeing actual images.",
    "Lobsters have bands that show how old they are, like tree rings. You can find these bands on the lobsters’ antennae and in their stomachs.",
    "Female Lobsters tend to have bigger tails than males, since they carry their eggs in their tails. Male Lobsters also have slender and hard swimmerets, while females have flattened or feathery swimmerets.",
    "Lobsters share the same gender names as chickens. Fishermen call male lobsters cocks and female lobsters hens.",
    "Female lobsters get ready to mate once they molt. When a female lobster molts its shell, she also releases a chemical that signals male lobsters that she’s ready to lay her eggs. This chemical draws them to her, in order to fertilize her eggs.",
    "Female lobsters can lay up to 12,000 eggs at a time, sometimes fathered by multiple lobsters.",
    "Lobsters start molting while still in their eggs. Inside their eggs, lobsters actually molt no less than 6 times before hatching. Once they hatch, the larvae only measure about 1/4th of an inch.",
    "Eating their own shells has benefits for lobsters. Their shells have plenty of calcium, which the lobster gets back when they eat their old shell. This additional calcium also helps their new shells grow and harden faster than they otherwise would.",
    "Lobsters keep their teeth in their stomachs, called a gastric mill. You can find this chamber in their stomach, averaging around the size of a walnut.",
    "Lobsters sometimes walk holding claws with each other. Scientists still aren’t sure why they do it. Cases of lobster hand-holding usually involves older lobster guiding a younger lobster along.",
    "Live lobsters are not red in color. They turn red only when you cook them. Usually, lobsters are olive green or greenish brown in color. You can also find orange, dark green, reddish, or black speckles on the body of this crustacean, blue color at its joints.",
    "Blue lobsters are quite rare. The source of their distinctive blue color is a genetic mutation that leads to the overproduction of a protein called crustacyanin.",
    "An average lobster molts 44 times before it turns one-year-old. Up to seven years, lobsters molt once in a year. After it turns seven, a lobster molts once in two or three years growing larger in size after shedding its exoskeleton.",
    "Records reveal that the fishermen caught the largest lobster, popular as ‘Big George’ in 1974 in Cape Cod, which was about 2.1 feet in length and 37.4 pounds in weight. Later, the fishermen caught the biggest lobster of 3.5 feet long in Nova Scotia in 1977, and its weight was 44 pounds and six ounces.",
    "Lobsters generally move slowly, but when in danger, they can move at 16 feet per second.",
    "Lobsters can recognize other lobsters, recall past companions, and have intricate mating rituals.",
    "Most lobsters live in oceans but some can be found in brackish water or freshwater. Lobsters are bottom dwellers, meaning they live on the ocean floor.",
    "Lobster do not have a central nervous system like mammals, instead their nervous system is similar to a grasshoppers or ants.",
    "Lobsters can travel huge distances; one deep-water lobster was recorded traveling 225 miles across the seafloor.",
    "Lobsters are very sensitive to changes in water temperatures, and this can cause lobsters to move areas.",
    "Just after they molt, lobsters are soft and fragile until their new shell has hardened, and they are known as new shell or soft shell lobsters. After their new shell hardens, they are known as hard shell lobsters.",
    "Dalí wrote of lobsters and telephones in his book The Secret Life of Salvador Dalí, which contains the following: I do not understand why, when I ask for a grilled lobster in a restaurant, I am never served a cooked telephone; I do not understand why champagne is always chilled and why on the other hand telephones, which are habitually so frightfully warm and disagreeably sticky to the touch, are not also put in silver buckets with crushed ice around them.",
    "The lobster, which has changed little over the last 100 million years, is known for its unusual anatomy. Its brain is located in its throat, its nervous system in its abdomen, teeth in its stomach and kidneys in its head.",
    "Lobster foreplay is elaborate, beginning with a mock boxing match and ending with the male 'tenderly' stroking the female.",
]

def main():
    random.seed(time.now().unix)

    idx = random.number(0, len(FACTS) - 1)
    current_fact = FACTS[idx]

    return render.Root(
        child = render.Padding(
            pad = 1,
            child = render.Marquee(
                height = 30,
                child = render.Column(
                    cross_align = "center",
                    children = [
                        render.Image(src = THE_ICON),
                        render.WrappedText(current_fact, width = 62),
                    ],
                ),
                offset_start = 8,
                offset_end = 0,
                scroll_direction = "vertical",
            ),
        ),
    )
