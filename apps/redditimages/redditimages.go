// Package redditimages provides details for the Reddit Images applet.
package redditimages

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed reddit_images.star
var source []byte

// New creates a new instance of the Reddit Images applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "reddit-images",
		Name:        "Reddit Images",
		Author:      "Nicole Brooks",
		Summary:     "Shuffle Subreddit Images",
		Desc:        "Description: Show a random image post from a custom list of subreddits (up to 10) and/or a list of default subreddits. Use the ID displayed to access the post on a computer, at http://www.reddit.com/{id}. All fields are optional.",
		FileName:    "reddit_images.star",
		PackageName: "redditimages",
		Source:  source,
	}
}
