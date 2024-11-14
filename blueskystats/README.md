# Bluesky Stats

## Overview

This is a simple app that displays statistics from [Bluesky](https://bsky.social/) such as the total number of users.

Statistics are gathered from the website https://bsky.jazco.dev/stats.

---

## Configuration (Schema)

The app supports some configuration options like selecting the statistic you want to view, the color to use for the numbers, and an option to use dots instead of commas as thousands separator.

The supported statistics are:

- total users
- total posts
- total follows
- total likes

---

## API Details

There is a single and unauthenticated API used: https://bsky-search.jazco.io/stats.

We are not sure if there is any kind of rate limiting implemented, but results are cached for 15 minutes using the http module native caching mechanism.

---

## Error Handling

The app has safeguards in place to identify potential errors and always display something on the screen. For instance, a non 200 response from the API will be handled and a message will be shown on the screen.

---

## Future Improvements

There's nothing much left to add here. The API returns more data like the `daily_data` field which could be used to render some charts.
