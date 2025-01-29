# Avatars In Pixels

## Overview

This app uses the [Avatars In Pixels API](https://www.avatarsinpixels.com/) to generate a random pixel art character, and then displays it using a nice scrolling animation.

Example:

![app](avatars_in_pixels.webp)

---

## API Details

This app needs two API calls to work. The first one calls the Avatars In Pixels generator, which returns the URL of the generated image. The second API call uses this URL to download the image itself.

### Terms of Use

Per the official [terms of use](https://www.avatarsinpixels.com/terms-of-use), the avatars can be used anywhere.

They also ask for attribution and a link back to the website. We provide this link on the app description, which is displayed on the Tidbyt mobile app.

### Authentication

The API requires no authentication. There is only one PHP session cookie (returned in the first API call) that needs to be passed to the second API to be able to download the avatar image.

### Rate Limiting

It is unknown if the API is rate limited.

Anyway, the images are cached for 1 hour so we don't stress the API.

---

## Error Handling

The app handles API errors, generates logs and has a different display mode to indicate there was an error.

The `fail` function is never called.

---

## Future Improvements

The Avatars In Pixels website has three different character generators: Minipix, Chibi and Pony.

We currently generate only the Minipix characters, meaning there's room for improvement.

Also, the API for the other character types seems to be very close to the Minipix one, which makes it easier to support them in the future.
