# ShowTime Applet for Tidbyt

ShowTime will let you pick a region, and then pick a local area in that region. It will monitor your region for upcoming ticketed events in your region and display one at a time.

The source for this information is the Ticketmaster API. 

I don't use the http cache, which seems to be what folks want. The reason is that the Ticketmaster API returns a TON of extra information. So instead of caching all that and looking through it each time, I pull out the data I need, and cache just that.

Since it'll take a while to display all the cached items anyway, no point in going back to refresh the data that often. New events only pop up every few days or so at the most. 

In addition to picking your region, you can choose to display the event artwork in the background or not, add "closed caption" type black bars over the image to make the text easier to read, and you can also pick the colors of the title and detail scrolling text.

If anyone has an idea how to pick the most contrasting color based on the given image, I'd love to hear it!

![ShowTime Applet for Tidbyt](showtime.webp)
