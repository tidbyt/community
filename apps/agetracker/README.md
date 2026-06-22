# Age Tracker

A memento-mori "life in months" calendar for the Tidbyt (64×32).

Every month from your birth to age **82** is one cell — **984** months packed to
fill the whole panel. Cells are **2px wide × 1px tall**, **32 per row**, so the
grid spans the full **64px width** and 31 of the 32px height. Months you have
already lived are filled with your chosen color; months still ahead are white.

The screen is **animated**: the lived months fill in left-to-right, row by row,
over ~5 seconds, then the finished grid holds for ~3 seconds before looping.

## Settings

| Field         | Type | Default   | Description                          |
|---------------|------|-----------|--------------------------------------|
| `birthdate`   | Date | 1990-01-01| Your birthdate.                      |
| `livingColor` | Color| `#3b82f6` | Color for the months already lived.  |

Months lived are computed from `birthdate` to the current date (whole completed
months), clamped to `[0, 984]`.
