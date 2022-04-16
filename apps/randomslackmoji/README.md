# Random Slackmoji for Tidbyt

Made by: [btjones](https://github.com/btjones/)

Displays a random image from [slackmojis.com](https://slackmojis.com/) on your Tidbyt using the Slackmojis API which includes over 50,000 potential images! Some are static and some animate.

Note: Because the API does not return image sizes, this app assumes all images square (most are).

## Slackmojis API

The Slackmojis API doesn't provide many options. It returns an array of 500 images at a time and takes only a single `page` parameter. That's it.

Example: https://slackmojis.com/emojis.json?page=25

## Potential Future Improvements

- If the Slackmojis API adds a search parameter this app could be customizable and allow users to enter a search phrase and only display images from those results.
- Dynamically determine the dimensions of an image so that non-square images are not stretched.

## Screenshots

![Blob from Random Slackmoji](screenshots/blob.png)
![This is Fine from Random Slackmoji](screenshots/thisisfine.png)
![Banana Dance from Random Slackmoji](screenshots/banana.png)
