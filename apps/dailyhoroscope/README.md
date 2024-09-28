# Daily Horoscope for Tidbyt

Displays the specified daily horoscope from [USA Today](https://www.usatoday.com/horoscopes/daily/) (currently thanks to Sanctuary).

![Daily Horoscope for Tidbyt](daily_horoscope.gif)

## Moon data

The current moon phase and sign are pulled daily from [Astro-Seek](https://mooncalendar.astro-seek.com/).

Below is the dictionary the applet uses when displaying the current moon phase and signs:

### Moon phases
| Icon                   | Phase           |
| :------------------:   |:-------------:  |
| :new_moon:             | New Moon        |
| :waxing_crescent_moon: | Waxing Crescent |
| :first_quarter_moon:   | First Quarter   |
| :waxing_gibbous_moon:  | Waxing Gibbous  |
| :full_moon:            | Full Moon       |
| :waning_gibbous_moon:  | Waning Gibbous  |
| :last_quarter_moon:    | Last Quarter    |
| :waning_crescent_moon: | Waning Crescent |

### Moon signs
| Abbreviation | Sign        |
| :--------:   |:----------: |
| ARI          | Aries       |
| AQU          | Aquarius    |
| CAN          | Cancer      |
| CAP          | Capricorn   |
| GEM          | Gemini      |
| LEO          | Leo         |
| LIB          | Libra       |
| PIS          | Pisces      |
| SAG          | Sagittarius |
| SCO          | Scorpio     |
| TAU          | Taurus      |
| VIR          | Virgo       |

## Version history

**Version 1.1.1** *(Current)*
- Fixed long words being cut off by hyphenating them at their final syllable
- Fixed certain apostrophes not showing in horoscope text

**Version 1.1**
- Added current moon phase and sign with display toggle
- Added ability to customize zodiac icon color