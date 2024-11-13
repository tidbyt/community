# Piet Mondrian-inspired clock for Tidbyt

Displays the time with a beautiful, unique composition De Stijl for each minute of the day.

## Reading the clock
### Digital clock
As you learn to read the clock faces, I suggest leaving the configuration for the digital clock face set to True.

### Hours
Hours are displayed next to the red block on the top.
A thin white block is merely decorative (for 12 and 6 displays). A thicker column or two of white blocks indicates actual hours. If the red block has moved to the left side of the display, that equals 6 hours.

```
12: Thin white column / Red
01: White column of 1 / Red
02: White column of 2 / Red
03: White column of 3 / Red
04: White column of 3 / White column of 1 / Red
05: White column of 3 / White column of 2 / Red
06: Red / Thin white column
07: Red / White column of 1
08: Red / White column of 2
09: Red / White column of 3
10: Red / White column of 3 / White column of 1
11: Red / White column of 3 / White column of 2
```

### Five Minute Increments
Five minute intervals are displayed in the bottom left. When the blue box is on the top row, it expands until it fits 25. Conversely, when the blue box is on the bottom row, it expands until it fits 55. The 15 and 45 have convenient grey boxes next to them to make them easier to read.

### One Minute Increments
There is a one minute mark in the bottom right. If the big one is yellow, it means to add 0 to the five-minute-read. There is then a box with four smaller boxes in them. The top left means to add one, top right to add two, bottom left to add three, and bottom right to add four.

## Like my programming?
Reach out to me on github [@theredwillow](https://github.com/theredwillow)