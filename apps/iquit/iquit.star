"""
Applet: HAIM's I Quit
Summary: HAIM's I Quit
Description: Based on the HAIM band's I Quit album cover
Author: Kyle Stark @kaisle51
"""

load("encoding/base64.star", "base64")
load("render.star", "render")

def main():
    def getFrames(animationName):
        FRAMES = []
        for i in range(0, len(animationName[0])):
            FRAMES.extend([
                render.Column(
                    children = [
                        render.Box(
                            width = animationName[1],
                            height = animationName[2],
                            child = render.Image(base64.decode(animationName[0][i]), width = animationName[1], height = animationName[2]),
                        ),
                    ],
                ),
            ])
        return FRAMES

    def getIQuit(animationName):
        setDelay(animationName)
        return render.Padding(
            pad = (animationName[3], animationName[4], 0, 0),
            child = render.Animation(
                getFrames(animationName),
            ),
        )

    def setDelay(animationName):
        FRAME_DELAY = animationName[5]
        return FRAME_DELAY

    def action():
        return IQUIT

    return render.Root(
        delay = setDelay(action()),
        child = render.Stack(
            children = [
                render.Box(
                    width = 64,
                    height = 32,
                ),
                getIQuit(action()),
            ],
        ),
    )

# Animation frames:
FRAME_1 = """iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAAAAXNSR0IArs4c6QAAAOVJREFUaIHtmUEOhCAMRT9kzuHepfc/hEv3XsRZNWEI6Yi2TJ32JSYqBGn5pY0AzkkAsE3L0Wqc9zXR/b/2CbxC6nhxjYBduZyZI/XhbMj1YN5oKuAJSClT3AG1muZ9TZxctdvK55bTMm9OH61Qsh5eYgqwZCitNLfy9E5lD/gmSUtkwG6qG4HoHvAkSJVuHUC4L4TUFdDj3LLvqEURywJlwdMz+bpQ0jB8WCHE5VuJsdTQlts2LQddmt+5QmQBIAohl1gMx6F8VIKeveE2BIhwwK8nYILYAwK/nPp3Z/lwMw5Jb/IGUMSsHEeuzXUAAAAASUVORK5CYII="""
FRAME_2 = """iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAAAAXNSR0IArs4c6QAAAOJJREFUaIHtmU0OhCAMhavxHO5dev9DsHTvRZyNTQghODr9G3lfYqLQxEcptASizhn4ZZvXo2aw7On1NqB7yjDZ5vXgx0vTFd9obPVz+6gl8F+YvAU8RWoTE3dAGXLLnoa8rRSu3Zd/15wmugRq6y3yPkIkGAGRBsoz3Zp5Zroy+EUAE8k5DGvsPgvAAUQxQ1QbFEIn6g64E125rVVUiqXBvOC5I74slDQGblYI1X7wNMWante1wy3i6ZK1mHi5Vbd7gyzgLSAEkdamFSiETuAAbwHewAHeAgDwJeyFJS5HjfgArAyxPyp1MC4AAAAASUVORK5CYII="""
FRAME_3 = """iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAAAAXNSR0IArs4c6QAAAOdJREFUaIHtmUEOhDAIRanpOdy79P6HcOneizgLJWEaxlEDLQovcVFtIvwCRQvgnEQHcz+u3KRhmdLb5/jml0IeyNxNKojVMDljI8458qGTN+0ZoDhsBDwBqcgUF6CsJ8MypaNw1X5Gx5xooinAFVPrBTYDyISTJUfRnzNFUKUG/AtJS7jdBXCROgDbK6SN2whA3AqAUa8uwJX0onNrpaXYLkAbnivGl42ShuPVGiHuBXd7DKsfYbeY+3HFq7UtSLUaYB23AkQjRPEsgNsUiCK4EwK0NiBoRNSAYOPr52GJ5cPMOBQV4gOAiKwcBRPc3wAAAABJRU5ErkJggg=="""
FRAME_4 = """iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAAAAXNSR0IArs4c6QAAAPFJREFUaIHtmUESgyAMRQPTc7Bnyf0PwZI9F6GbpgMMWqWkjSZvxoWSwRD/fKICCMf0F5ILZRToczR3i3mPb01wZ5o1SywA8hhdrAtSy4gTR3LEmL012PWpXYuhAq7At8pMLhSfo1legN5PfI5mT67UY/X5qGh2a2CGkZlyN9hlCuC0UHygR0yQxAM+SZITFoB3gtSI3QZRpWILgGgBqG9wxl/qWGpfwvmX7QJ1w3Mm+b5Rolj4zxqh0Tyzc3N9CZsiuVDw+HcuCOaiJgigjZBIGo9RBQhGbAF0F5COKuCFFgBA9jbYfDys4fQTkypGAYAnmie2Q+ZyMzoAAAAASUVORK5CYII="""
FRAME_5 = """iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAAAAXNSR0IArs4c6QAAAO5JREFUaIHtmTsShSAMRYPjOuwt3f8iLO3diDbE4TnIEwwkmpwZGwhwjSF8BFCOAwBYhmkb19lh4TJMW8z4azZH3VXjL4Pv3HEL4aaPFYYREYaQJO5oRJtYPZZZBHALKIUqMpOhUzJQLNOm+qtdd9YS2ozr7EinQGxg6SsM2RSQ9KL4pVNJEOnRkDLb3w1JCahfBcwB3AK4sI2Qp7oDchJgaNsqcXYANLuq8yYDn5x2Ydunev71WeU0mDp0UPT1WnIiohU/ESBJWGtsFeAWIAKbAopR7wC12LW4xxwAYKuAao5L0atrZuk/OEttDM8OhFG6Q/1nhKYAAAAASUVORK5CYII="""
FRAME_6 = """iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAAAAXNSR0IArs4c6QAAAPdJREFUaIHtmUsOhCAMQIvxHO5Zev9DsHTPRZzN1NSmToYZStHyEhcFDaX2JwI4JwAAbMu6AwDEnAJO4BjnSfcc41cPPhnc82StiDWzNCi6SWd8o6MU2hy3HoBGmalwJ2rpLIbAP/CEGnMKn9xVe47KktGqhoBUTXqtMKcqUEPJnjYacwr0bXOZUj0EcEEq92QcjtsqgAwDWCtgjVsDYJ6aqKBBSQKk97ZKnNWqAG14SpTnjZLGxps1QtICv3qXdnt+MrS2u23LuuOluU4J4zzgzTCAtQLWqHwLcLo/b+gpOQ0GgyZUPxG6K+7LoHsDHH2A1x+k7nkBaeG5sLFT+zgAAAAASUVORK5CYII="""
FRAME_7 = """iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAAAAXNSR0IArs4c6QAAAPVJREFUaIHtmcEOgyAMhgvZc3Dn6Ps/BEfuvAi7iCOszuEoZZQvMREEKbWUPwggHAUA4M0WU4UNTqX7vD5nljZH3VmnmUlz1tyGcPPAKs+WxEh8Y+NbqCPoqwazg0bAP/DrR0v9mzugTKg2OPUpXKmf5WXMaRrrcBfsPaPvMM12gZEmaoNT+dcuywAve0lywFVIjoR4HbAcwG0AN+KFEHkE1CTAvC114mwuhHLBU2N8KZQoJt5NCGED3F1eXZcldbh5s8V0UY5TwzoP2FkO4DaAmy7nAZJ1xrCMlJAX7EgOB7G7wBJCO+IdcOgAb7bI/bOSs41YnmnhubBL+J9zAAAAAElFTkSuQmCC"""
FRAME_8 = """iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAAAAXNSR0IArs4c6QAAAPFJREFUaIHtWUkOgzAMHFDf0XuP/f8jOPbej7SXGIUo0ITGi7BHQoJsdsJ4HALgHBMAvO7PT174eC8T3Zd1V2qzPu91uDJozrO2I9q4AVtqAFtGlHVW0OIjtTmaQzBA24GzGMXMNQvsqWivoVpGORqPu670pSwbGgI1w9YzzLAQsDRRetMtIsiiAa2U1ASFvfssEAsA2N3sSCAYwG2gRwDztlLCOY8yVm6k6Orpl/f9159fY5LdoQyoaclZfRHVJW669TBCGm5FMA5EEtwvgFtECCS4XwAANj9XpeCeAbEA2g5oIbJAQvVM0OKPTM42rvEFn6G4aC/aMCsAAAAASUVORK5CYII="""
FRAME_9 = """iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAAAAXNSR0IArs4c6QAAAPxJREFUaIHtmUEOhCAMRT/Gc7h36f0P4dK9F3EWk06AKUQdCh3LS0w0NNCW8mkiYBwHANu0HPHAvK+O3rnxJ9h8SBk/GYsxB1ACxtwgkCgZBZzxkWxyMQzlXfsvRuCdKa07naKUv+wR+IVYXOZ9dblylR7zv7mkFT0CnLJqVVtKRrEK0BQoBXdGBIsfAW5BTcmJMXsL0KYMgN67vgZmK4DoCQBkRerK3L5tLeEsdgv4Dc8V5+NGSSLwao0Qt8BdgZUW5mB+6XLbpuWgR3KdO3QRbO1AK3ojZJ2gAiwj3ghpx3wFAOgVYJqegNYOtIKO/VcDpO0HpqRNbwABvABfAbZDBwg6zwAAAABJRU5ErkJggg=="""

# Animations list: [[frames], width, height, xPosition, yPosition, frameMilliseconds]
IQUIT = [
    [FRAME_1, FRAME_2, FRAME_3, FRAME_4, FRAME_5, FRAME_6, FRAME_7, FRAME_8, FRAME_9],
    64,
    32,
    0,
    0,
    100,
]
