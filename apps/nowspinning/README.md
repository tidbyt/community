# Now Spinning

## Overview

This app was developed by request for the user `Diesel7688` on the [Tidbyt Forums](https://discuss.tidbyt.com/t/now-spinning/6964).

It displays the album cover, album name and artist name from a specific album chosen by the user.

The app itself is not connected to any music service and does not update automatically. The user needs to manually change the displayed album. This was also by request.

---

## Configuration (Schema)

The app has a `Typeahead` control where the user types the name of the album and it displays a list of options to choose from. This list is populated with results from a Spotify API, see details below.

There are also options to change the app colors and one option to hide the app from rotation.

---

## API Details

As mentioned above, the app uses Spotify's [Search for Item](https://developer.spotify.com/documentation/web-api/reference/search) API to build a list of possible albums to choose from.

### Authentication

The API above requires bearer token authentication. To do this, we follow the same process as Spotify's own public web player. We call an open endpoint that returns an access token, which is then used on the next request.

The token is cached for its validity and the cover images are cached for 24 hours.

### Rate Limiting

Spotify's APIs are [rate limited](https://developer.spotify.com/documentation/web-api/concepts/rate-limits), however the value is not published on the documentation. The only information is that the limit is calculated based on a 30 second rolling window.

---

## Error Handling

The app has safeguards in place to identify potential errors and always display something on the screen. For instance, failure to recover the cover image of an album will be handled and a default image will be shown.

Failures when calling the API that populates the `Typeahead` control are also handled and a message is shown on the Tidbyt screen.

---

## Future Improvements

This app is already pretty straightforward and there is nothing much else to add. Trying to connect it to a music service is pointless because then it will behave like the official apps like Spotify or Sonos.
