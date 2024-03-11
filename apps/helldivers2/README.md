# Helldivers 2

## Overview

This app shows the current number of players for the game Helldivers 2.

## API Details

We use the game's public API to retrieve the data. This is the same API used by websites like [helldivers.io](https://helldivers.io/) and [helldiversstats.com](https://www.helldiversstats.com/).

### Authentication

The API requires no authentication.

### Rate Limiting

It is unknown if the API is rate limited.

Results are cached for 15 minutes using the built-in caching provided by the `http` module.

## Error Handling

The app handles API errors, generates logs and has a different display mode to indicate there was an error.

The `fail` function is never used.

## Future Improvements

The API provides more data that could be used to enhance the application like:

- Show a chart with the player count history from the last 24h (using [this API](https://www.helldiversstats.com/api.php)).
- Show ongoing game global events and major orders.
- Show stats about a planet's liberation campaign.
