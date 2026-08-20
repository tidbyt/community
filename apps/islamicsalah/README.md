# Islamic Salah

Daily Islamic prayer times. Displays Fajr, Dhuhr, Asr, Maghrib and Isha for a
location chosen in the Tidbyt mobile app, highlighting the next prayer in amber.

![](islamic_salah.png)

## Configuration

The install screen provides three fields:

- **Location** — the place prayer times are calculated for.
- **Calculation method** — the authority used for the timings: Muslim World
  League, Islamic Society of North America, Umm al-Qura, Diyanet or Moonsighting
  Committee.
- **Asr calculation** — Standard/Shafi or Hanafi. The Hanafi school places Asr
  noticeably later in the day, so this changes the displayed time materially.

## Privacy

Latitude and longitude are truncated to two decimal places before being sent to
the AlAdhan API. This keeps roughly city-block accuracy, which is more than
enough for prayer timings, without disclosing a precise device location.

## Disclaimer

Timings come from the [AlAdhan API](https://aladhan.com/) and may differ from
those published by a local mosque or authority. Where they disagree, follow your
local authority.
