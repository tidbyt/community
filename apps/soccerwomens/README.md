# Women's soccer tournament / league

Women's soccer displays upcoming / current / completed games for tourname / league you have selected

Displayed:

- Home / Away Teams & current record
- If future game: Date & Time of upcoming game
- If inprogress game:  Score & Time
- If past game:  Final Score

## Configuration
- Select League / Tournament to display.  Current Leagues / Tournament options are:
    * Australian A-League Women  ** Cavaet see below
    * CONCACAF W Championship
    * English Women's Champions League
    * English Women's FA Cup
    * English Women's Super League
    * She Believes Cup
    * United States NWSL
    * Women's International Friendly
    * Women's Olympics Tournament
    * Women's World Cup

- Which team to display first (home or away)
- Select display format type
- Select color for time
- Select time to display each score (this eliminates the mult-instance thing we've traditionally done)
- 12 hour vs 24 hour time & US vs Intl date format
- Select if you want to show a range of days forward / back instead of just the default API results & specify how many days forward and back.

## Caveat
For some reason, if you select Australian Women's A-Legaue, the API returns no data by default (vs all the other leagues).  If you do NOT select the option to filter by date range,  the app automatically looks 6 days ahead from today.

## Thanks

Thanks a lot to a bunch of folks who have worked on these various sports apps.  @LunchBox8484 is the original author of many of them.
Thanks to @jesushairdo for the new option to be able to show home or away team first.  Let's be more international :-)

## Screenshot

![screenshot](soccerwomens.gif)
![screenshot](soccerwomens2.gif)
