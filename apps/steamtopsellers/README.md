# Steam Top Sellers (A Tidbyt App)

## Overview
A simple [Tidbyt](https://tidbyt.com/) appliction intended to render a random selection from Steam's Top Seller list. 

This data is exposed via the Steam API using the "featured categories" resource (ie. `https://store.steampowered.com/api/featuredcategories`).

The API payload includes game metadata as well as an image resource. These details are used to populate frames in the Tidbyt app.

![Preview](steam_top_sellers.gif "Preview")

## Usage
After installing [Pixlet](https://tidbyt.dev/docs/build/installing-pixlet), run the following commands to render/serve the image locally. 

```
# Serve locally (default port 8080)
pixlet serve steamtopsellers/steam_top_sellers.star

# Render webp artifact
pixlet serve steamtopsellers/steam_top_sellers.star
```

> See [Tidbyt.dev](https://tidbyt.dev/) for additional details about pushing to a device or publishing.