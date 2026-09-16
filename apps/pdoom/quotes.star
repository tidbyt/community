"""
p(DOOM) quote dataset.

EVERY ENTRY IN THIS FILE IS A REAL, ATTRIBUTED QUOTATION.
NOTHING IN THIS FILE MAY BE INVENTED, PARAPHRASED OR "IMPROVED".

Fields
------
text          The quotation as published, with one mechanical change: any
              non-ASCII punctuation is flattened to its ASCII equivalent
              (entry 14's em dash becomes a hyphen), because this dataset is
              ASCII-only. Every such change is recorded in QUOTES.md. Never
              shown on the display; it exists so the entry can be audited.
display       The Tidbyt-safe rendering of the quotation. ASCII only.
              Where the quotation had to be shortened to fit a 64x32
              screen, the cut is marked with "..." and the meaning of
              the remaining words is unchanged. Where "display" begins
              mid-sentence, the first letter may be capitalised.
speaker       The person or document the quotation belongs to.
speaker_short The attribution shown on the display. ASCII, <= 13 chars, so
              that "- " plus the name fits 64px at 4px per glyph.
source        The publication, event or document it comes from.
url           Where a human can go to check it.
date          Date of the source, ISO-8601, or "c.YYYY" when the
              original is undated.

Verification of each entry, and the candidates that were REJECTED for
insufficient verification, are recorded in QUOTES.md and in
../../evidence/quote-verification-log.md. Verification was done with
web search corroboration of the exact wording; this sandbox's network
policy blocked direct fetching of the primary pages, so the URLs are
recorded for a human audit pass rather than claimed as retrieved.
"""

QUOTES = [
    {
        "text": "Mitigating the risk of extinction from AI should be a global priority alongside other societal-scale risks such as pandemics and nuclear war.",
        "display": "Mitigating the risk of extinction from AI should be a global priority alongside other societal-scale risks such as pandemics and nuclear war.",
        "speaker": "Statement on AI Risk, signed by Geoffrey Hinton, Yoshua Bengio, Sam Altman, Demis Hassabis, Dario Amodei and hundreds of others",
        "speaker_short": "CAIS 2023",
        "source": "Center for AI Safety, Statement on AI Risk",
        "url": "https://safe.ai/work/statement-on-ai-risk",
        "date": "2023-05-30",
    },
    {
        "text": "Many researchers steeped in these issues, including myself, expect that the most likely result of building a superhumanly smart AI, under anything remotely like the current circumstances, is that literally everyone on Earth will die.",
        "display": "Many researchers... expect that the most likely result of building a superhumanly smart AI... is that literally everyone on Earth will die.",
        "speaker": "Eliezer Yudkowsky",
        "speaker_short": "E. YUDKOWSKY",
        "source": "TIME, 'Pausing AI Developments Isn't Enough. We Need to Shut it All Down'",
        "url": "https://time.com/6266923/ai-eliezer-yudkowsky-open-letter-not-enough/",
        "date": "2023-03-29",
    },
    {
        "text": "Success in creating AI would be the biggest event in human history. Unfortunately, it might also be the last, unless we learn how to avoid the risks.",
        "display": "Success in creating AI would be the biggest event in human history. Unfortunately, it might also be the last, unless we learn how to avoid the risks.",
        "speaker": "Stephen Hawking, Stuart Russell, Max Tegmark and Frank Wilczek",
        "speaker_short": "HAWKING ET AL",
        "source": "The Independent, 'Transcendence looks at the implications of artificial intelligence - but are we taking AI seriously enough?' (first published in the Huffington Post, 2014-04-19)",
        "url": "https://www.independent.co.uk/news/science/stephen-hawking-transcendence-looks-at-the-implications-of-artificial-intelligence-but-are-we-taking-ai-seriously-enough-9313474.html",
        "date": "2014-05-01",
    },
    {
        "text": "At some stage therefore we should have to expect the machines to take control, in the way that is mentioned in Samuel Butler's Erewhon.",
        "display": "At some stage therefore we should have to expect the machines to take control...",
        "speaker": "Alan Turing",
        "speaker_short": "A. TURING",
        "source": "Lecture, 'Intelligent Machinery, A Heretical Theory' (Manchester; later collected in The Essential Turing)",
        "url": "https://turingarchive.kings.cam.ac.uk/publications-lectures-and-talks-amtb/amt-b-4",
        "date": "c.1951",
    },
    {
        "text": "Thus the first ultraintelligent machine is the last invention that man need ever make, provided that the machine is docile enough to tell us how to keep it under control.",
        "display": "Thus the first ultraintelligent machine is the last invention that man need ever make...",
        "speaker": "Irving John Good",
        "speaker_short": "I. J. GOOD",
        "source": "'Speculations Concerning the First Ultraintelligent Machine', Advances in Computers, vol. 6",
        "url": "https://www.sciencedirect.com/science/article/abs/pii/S0065245808604180",
        "date": "1965",
    },
    {
        "text": "I console myself with the normal excuse: If I hadn't done it, somebody else would have.",
        "display": "I console myself with the normal excuse: If I hadn't done it, somebody else would have.",
        "speaker": "Geoffrey Hinton",
        "speaker_short": "G. HINTON",
        "source": "The New York Times, ''The Godfather of A.I.' Leaves Google and Warns of Danger Ahead' (Cade Metz)",
        "url": "https://www.nytimes.com/2023/05/01/technology/ai-google-chatbot-engineer-quits-hinton.html",
        "date": "2023-05-01",
    },
    {
        "text": "The alarm bell I'm ringing has to do with the existential threat of them taking control.",
        "display": "The alarm bell I'm ringing has to do with the existential threat of them taking control.",
        "speaker": "Geoffrey Hinton",
        "speaker_short": "G. HINTON",
        "source": "EmTech Digital 2023, MIT Technology Review",
        "url": "https://www.technologyreview.com/2023/05/03/1072589/video-geoffrey-hinton-google-ai-risk-ethics/",
        "date": "2023-05-03",
    },
    {
        "text": "Importantly, none of the current advanced AI systems are demonstrably safe against the risk of loss of control to a misaligned AI.",
        "display": "...none of the current advanced AI systems are demonstrably safe against the risk of loss of control...",
        "speaker": "Yoshua Bengio",
        "speaker_short": "Y. BENGIO",
        "source": "Written testimony to the U.S. Senate Judiciary Subcommittee on Privacy, Technology, and the Law",
        "url": "https://www.judiciary.senate.gov/imo/media/doc/2023-07-26_-_testimony_-_bengio.pdf",
        "date": "2023-07-25",
    },
    {
        "text": "Development of superhuman machine intelligence (SMI) is probably the greatest threat to the continued existence of humanity.",
        "display": "Development of superhuman machine intelligence... is probably the greatest threat to the continued existence of humanity.",
        "speaker": "Sam Altman",
        "speaker_short": "S. ALTMAN",
        "source": "Personal blog, 'Machine intelligence, part 1'",
        "url": "https://blog.samaltman.com/machine-intelligence-part-1",
        "date": "2015-02-25",
    },
    {
        "text": "With artificial intelligence, we are summoning the demon.",
        "display": "With artificial intelligence, we are summoning the demon.",
        "speaker": "Elon Musk",
        "speaker_short": "E. MUSK",
        "source": "MIT AeroAstro Centennial Symposium, reported by The Washington Post",
        "url": "https://www.washingtonpost.com/news/innovations/wp/2014/10/24/elon-musk-with-artificial-intelligence-we-are-summoning-the-demon/",
        "date": "2014-10-24",
    },
    {
        "text": "I think we should be very careful about artificial intelligence. If I were to guess at what our biggest existential threat is, it's probably that.",
        "display": "I think we should be very careful about artificial intelligence. If I were to guess at what our biggest existential threat is, it's probably that.",
        "speaker": "Elon Musk",
        "speaker_short": "E. MUSK",
        "source": "MIT AeroAstro Centennial Symposium. Both sentences are contiguous in the remarks; the first is kept because 'that' has no antecedent without it",
        "url": "https://www.washingtonpost.com/news/innovations/wp/2014/10/24/elon-musk-with-artificial-intelligence-we-are-summoning-the-demon/",
        "date": "2014-10-24",
    },
    {
        "text": "Before the prospect of an intelligence explosion, we humans are like small children playing with a bomb.",
        "display": "Before the prospect of an intelligence explosion, we humans are like small children playing with a bomb.",
        "speaker": "Nick Bostrom",
        "speaker_short": "N. BOSTROM",
        "source": "Superintelligence: Paths, Dangers, Strategies (Oxford University Press)",
        "url": "https://global.oup.com/academic/product/superintelligence-9780199678112",
        "date": "2014",
    },
    {
        "text": "We must take the risks of AI as seriously as other major global challenges, like climate change.",
        "display": "We must take the risks of AI as seriously as other major global challenges, like climate change.",
        "speaker": "Demis Hassabis",
        "speaker_short": "D. HASSABIS",
        "source": "Interview with The Guardian, ahead of the UK AI Safety Summit",
        "url": "https://www.theguardian.com/technology/2023/oct/24/ai-risk-climate-crisis-google-deepmind-chief-demis-hassabis-regulation",
        "date": "2023-10-24",
    },
    {
        "text": "the gorilla problem-specifically, the problem of whether humans can maintain their supremacy and autonomy in a world that includes machines with substantially greater intelligence",
        "display": "...whether humans can maintain their supremacy and autonomy in a world that includes machines with substantially greater intelligence.",
        "speaker": "Stuart Russell",
        "speaker_short": "S. RUSSELL",
        "source": "Human Compatible: Artificial Intelligence and the Problem of Control (Viking)",
        "url": "https://people.eecs.berkeley.edu/~russell/hc.html",
        "date": "2019",
    },
    {
        "text": "Should we develop nonhuman minds that might eventually outnumber, outsmart, obsolete and replace us? Should we risk loss of control of our civilization?",
        "display": "Should we risk loss of control of our civilization?",
        "speaker": "Future of Life Institute open letter, 'Pause Giant AI Experiments', signed by Yoshua Bengio, Stuart Russell, Elon Musk and others",
        "speaker_short": "FLI LETTER",
        "source": "Future of Life Institute, 'Pause Giant AI Experiments: An Open Letter'",
        "url": "https://futureoflife.org/open-letter/pause-giant-ai-experiments/",
        "date": "2023-03-22",
    },
]
