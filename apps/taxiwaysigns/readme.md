# Taxiway Signs Applet for Tidbyt

Displays a randomly generated Airport Taxiway Sign

This will randomly display a sign like you'd see at an airport as you taxi to the runway.
Black with box with yellow text gives you your current location. "I5" for example means you are on taxiway I at point 5.
Yellow with black text is a directional indicator letting you know which direction the indicated taxiway is located.
Red indicates a runway hold position where planes need to get clearance before moving. The number is the runway number.

Runway Numbers are based on the direction of the runway from 0 to 360 degrees. If the entire runway is in front of you and you are facing south, you are facing 180 degrees. You drop the rightmost digit to get 18, and that runway will be runway 18. If you go to the opposite end of the runway, you'd be facing North which is 360 degrees. That end of the runway will be numbers 36. The numbers of the ends of the runways always differ by 18 (meaning 180 degrees).  Sometimes there are two or three runways parrallel to each other. In those cases they would add and "L" or "R" for left and right, or a "C" for center.  So you might see a runway with 18L at one end, you'd see 36R at the other end. There could be a runway next to that with 18C at one end, and 36C at the other end.

The example graphic shows F3 G↑ 07. The F3 indicates the current position, point #3 on taxiway F. The G↑ indicates that if you go straight you can get to taxiway G. The 07 means that you are at the stopping point before getting on to runway 07. This runway will get you headed to about 70 degrees which is East Northeast (ENE)

![Taxiway Signs Applet for Tidbyt](taxiway_signs.webp)
