# NPM Packages

## Overview

This app shows the number of downloads for a NPM package for the last day, week or month.

## API Details

We use two public NPM APIs to retrieve the data:

- The [search](https://www.npmjs.com/search?q=axios) API is used by the `get_schema` method to help the user find the package he wants to track.
- The [downloads](https://api.npmjs.org/downloads/range/last-week/axios) API is then used to retrieve the download counts for a given period.

### Authentication

Both APIs used require no authentication.

### Rate Limiting

It is unknown if the API is rate limited.

Anyway, since NPM only updates the download counts on a daily basis, results are cached for 6 hours using the built-in caching provided by the `http` module.

## Error Handling

The app handles API errors, generates logs and has a different display mode to indicate there was an error.

The `fail` function is never used.
