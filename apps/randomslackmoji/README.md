# Random Slackmoji for Tidbyt

Made by: [btjones](https://github.com/btjones/)

Displays a random image from [slackmojis.com](https://slackmojis.com/) on your Tidbyt using the Slackmojis API which includes over 50,000 potential images! Some are static and some animate.

## Slackmojis API

### Main API

The Slackmojis API doesn't provide many options. It returns an array of 500 images at a time and takes only a single `page` parameter. That's it.

Example: https://slackmojis.com/emojis.json?page=25

### Search API

The search API powers the slackmojis.com front end and returns html. It takes a `query` and optional `page` parameter. Because this returns html, we scrape the results to find the returned `<img>` tags. Will it break some day? Hopefully not.

Example: https://slackmojis.com/emojis/search?page=2&query=test

## Potential Future Improvements

- [x] Allow users to enter a search phrase and only display images from those results.
- [x] Maintain aspect ratio of an image so that non-square images are not stretched.

## Screenshots

![Blob from Random Slackmoji](screenshots/blob.png)
![This is Fine from Random Slackmoji](screenshots/thisisfine.png)
![Banana Dance from Random Slackmoji](screenshots/banana.png)
