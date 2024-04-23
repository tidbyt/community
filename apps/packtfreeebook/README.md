# Packt Free eBook

## Overview

This app displays details about Packt Pub's daily free eBook, as seen on their website: https://www.packtpub.com/free-learning.

Currently the app displays the book cover, title and number of pages.

## API Details

There are no APIs used. All data is extracted directly from the page's content using Pixlet's `html` module.

The page itself does not use any APIs and the content seems to be rendered server side.

### Caching

Since Packt updates the page everyday at midnight (UTC), there's no point in fetching the content multiple times a day. The app calculates the time remaining until the next update and caches the response for that many seconds.

For this to work, we had to use Pixlet's native `cache` module instead of the one built into the `http` module.

This is because the http module takes the `ttl_seconds` parameter and sends its value in a header called `x-tidbyt-cache-seconds`. Since the http cache key is based on the request (including the headers) and we calculate what would be the ttl in each app run, this would effectively render the http cache useless.

## Configuration (Schema)

Currently this app has no configuration opotions.

## Error Handling

As mentioned before, the app reads its data from the page's html content. This does leave an opening for the html to change in the future and break the app.

With this in mind, the app checks if the data was found and uses default values when necessary.

The http calls to retrieve the content and the cover image are also checked and in case of errors the `render_error` function is called to show a troubleshooting view. The `fail` function is never used.

## Future Improvements

The app currently displays the book cover, title and number of pages. There is more data available on the page like the book's publishing date, summary/description, author name and the rating.

With the limited space of the Tidbyt, it's challenging (let alone a bad user experience) to try to display so much information at the same time. However, the app could have different display modes where the book cover is not shown (it's not readable anyway in 32 pixels) and then other information like the book's author or the rating could be shown instead.
