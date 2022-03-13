# Reddit Image Shuffler For Tidbyt

Displays a random image post from subreddits you specify and/or a list of default subreddits, along with its name, subreddit, and post ID.

To access any posts on reddit, tack the ID onto the end of the URL. For example, the post below is located at http://www.reddit.com/td4fnp.

![Sample Shuffle](image-shuffler-example.png)

## Reddit API

This uses the public listing API for reddit. See [the documentation](http://reddit.com/dev/api#GET_hot) for more details. This does not require any kind of authentication or API key -- all reddit asks is that the script calling this API has a name in the `User-Agent` field in the headers.