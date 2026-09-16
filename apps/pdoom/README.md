# p(DOOM)

A countdown to local midnight, as though midnight were the moment the machines
take over. At midnight it announces `p(DOOM) = 1.00`, says `SEE YOU TOMORROW`,
and starts again.

It is not a prediction. The joke is that p(DOOM) happens every midnight, every
day — a daily reminder that the time is finite, so use today well.

Between countdowns it shows a real, attributed quotation from someone who has
publicly discussed catastrophic or existential risk from AI. **No quotation in
this app is invented.** All fifteen are stored in `quotes.star` with the
speaker, the source, a URL and a date, so any of them can be checked.

## Settings

- **Location** — only the timezone is used; it decides which midnight is being
  counted down to.
- **Quote frequency** — never, rarely, sometimes, often, or always.
- **Animation** — `ominous` blinks the colon, pulses the warning pips and
  glitches into quotes; `calm` holds everything steady.

## Notes

The countdown is baked into the animation at one second per four frames, so it
ticks in real time for the whole 15 seconds of a render. The next local
midnight is found by bisecting absolute time rather than by constructing
tomorrow at 00:00, because a daylight-saving day is 23 or 25 hours long and in
a few timezones (`America/Havana`, `America/Santiago`, `Atlantic/Azores`,
`Africa/Cairo`, `Asia/Beirut`) local midnight does not exist at all on one day
of the year.

The visual design is original pixel art. It is inspired by the idea of a
doomsday clock and deliberately copies no artwork, logo or trade dress.
