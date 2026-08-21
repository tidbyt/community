# USL League One

Displays the selected club's live match, most recent result, or next fixture using ESPN's public USL League One scoreboard. New York Cosmos is the default, all current League One clubs are available in a Tidbyt dropdown, and compact team crests are loaded from ESPN with a text-only fallback.

```sh
pixlet serve apps/uslleagueone/usl_league_one.star
pixlet render apps/uslleagueone/usl_league_one.star
pixlet check apps/uslleagueone/usl_league_one.star
```

The team IDs and dropdown labels are kept together near the top of `usl_league_one.star` so league membership changes can be updated in one small section.
