# Product Hunt

## Overview

This app shows the daily top tech products being launched on [Product Hunt](https://www.producthunt.com/).

There is an option to show only the current top product, or the top 3 where each one is displayed for about 5 seconds.

The app shows the product name, logo and the current vote count.

Votes are cast by the Product Hunt community and are used to rank the products. Users of the app may see different products displayed on the Tidbyt along the day.

---

## API Details

Product Hunt does have an official and free [GraphQL API](https://api.producthunt.com/v2/docs). It supports OAuth2 authentication with the `authorization_code` and `client_credentials` flows.

However, we noticed that the [GraphQL Explorer](https://ph-graph-api-explorer.herokuapp.com/) that is referenced on their documentation does not require any authentication and it returns the same production data as the "official" (authenticated) API.

For the sake of simplicity, the app is currently using the unauthenticated GraphQL Explorer endpoint.

### Rate Limiting

The "official" (authenticated) API has a documented [Rate Limit](https://api.producthunt.com/v2/docs/rate_limits/headers) of 450 requests every 15 minutes.

During development we did not reach any limits, even when using the unauthenticated API. Anyway, the app caches the results for 30 minutes using the `http` module's internal caching feature.

---

## Configuration (Schema)

The app supports only one configuration option where the user can choose if he/she wants to see only the current top product trending on Product Hunt, or the top 3.

---

## Error Handling

The app has safeguards in place to identify potential errors and always display something on the screen. For instance, API errors will be rendered with the `render_api_error` function and will try to extract an error message from the payload.

Errors when trying to download the product's logo will be handled and a default image will be shown instead.

The `fail` function is never used in the code.

---

## Future Improvements

Product Hunt's GraphQL API has a lot of information available such as product categories, rewiews, ratings, descriptions, number of followers etc.

The app could be improved with new display options to show this data.

We could also add more config options to allow customization of colors, to hide the product logo and show something else there, or even to let the user select a specific category and view only the products that are part of that.
