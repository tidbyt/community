# Live Tennis

Live **point-by-point** tennis scores on your Tidbyt, across the ATP, WTA,
Challenger and ITF tours.

![Live Tennis](live_tennis_scores.gif)

Each live match gets its own page and the app rotates through them:

```
+----------------------------------+
| Toronto                       QF |  <- tournament + round (bg colour = tour)
|   Alcaraz                1  2 40 |  <- sets won / games this set / current point
| * Sinner                 1  1 AD |  <- green dot = this player is serving
| 6-3 4-6                     LIVE |  <- completed sets            live/tiebreak
+----------------------------------+
```

* **Sets won** in white, **games in the current set** in blue, **current point**
  (`0 / 15 / 30 / 40 / AD`) in yellow.
* During a tiebreak the point column turns orange and the status reads `TB`.
* The header background identifies the tour: blue = ATP, magenta = WTA,
  brown = Challenger, grey = ITF.
* A player slot that has not been filled yet (qualifier / lucky loser) shows
  `TBD`, and a match with no score yet shows `About to start`.

## Setup

1. Get a **free** Live Tennis API key (1,000 requests/day) at
   <https://livetennisapi.com/subscribe/free>.
2. Paste it into the app's **API key** field in the Tidbyt mobile app.
3. Optionally pick a single tour, set the rotation speed, and turn on rankings.

## Requests

The app fetches `GET /matches?status=live` with `ttl_seconds = 120`, so one
key/tour combination makes at most `86400 / 120 = 720` upstream requests a day —
inside the 1,000/day free tier.
