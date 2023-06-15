# Json Display
This is my first Tidbyt community app, I wanted to display some simple json business data and I discovered that there doesn't seem to be such a thing as a private app.

So this is my attempt to load some simple json and get it to display.

## Features
* Read in a URL from a server (I think you should be able to do basic http auth here http://user:password@domain.com/)
* Title image and text (10x10px png works well for the icon)
* Up to three lines of values, you can add more but I can't work out the animation functions yet
* Each line will scroll if too long
* Each line can have a different color
* If you want more than three lines, you should be able to add the app a second time and use a different json URL, not idea but ¯\_(ツ)_/¯
* Doesn't use cache, if I am reading the [API doc right](https://tidbyt.dev/docs/reference/modules#pixlet-module-cache) we may all use the same cache which would cause issues! 

## Things I would like to add
* Animation to scroll more than three lines
* Better alignment for the titles and values (perhaps just get values to scroll not the titles)

## Feedback
I'm happy to make improvements if I can. just let me know on Mastodon [https://mas.to/@thickey](https://mas.to/@thickey_)


## Example json file
    {
		"title_image": "https://tidbyt-json-display.s3.eu-west-1.amazonaws.com/heart.png",
		"title_text": "Sales",
		"data": [
			{
				"title": "Sales",
				"value": "$56,854",
				"color": "FF0000"
			},
			{
				"title": "Orders",
				"value": "40",
				"color": "00FF00"
			},
			{
				"title": "Status",
				"value": "I am some long text that will scroll",
				"color": "0000FF"
			}
		]
	}