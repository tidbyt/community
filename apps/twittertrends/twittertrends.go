// Package twittertrends provides details for the Twitter Trends applet.
package twittertrends

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed twitter_trends.star
var source []byte

// New creates a new instance of the Twitter Trends applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "twitter-trends",
		Name:        "Twitter Trends",
		Author:      "Joseph Esposito",
		Summary:     "Displays top twitter trends",
		Desc:        "Displays the top N number of Trending Hashtags on Twitter. Colors of the trends text determine how many tweets it has. White: No Volume Data, Green: Less then 25K, Blue: 25K - 100K, Orange: 100K - 250K, Purple: 250K - 500K, Red: More than 500K.",
		FileName:    "twitter_trends.star",
		PackageName: "twittertrends",
		Source:  source,
	}
}
