// Package twitterfollows provides details for the Twitter Follows applet.
package twitterfollows

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed twitter_follows.star
var source []byte

// New creates a new instance of the Twitter Follows applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "twitter-follows",
		Name:        "Twitter Follows",
		Author:      "Nick Penree",
		Summary:     "Twitter Follower Count",
		Desc:        "Display the follower count for a provided screen name.",
		FileName:    "twitter_follows.star",
		PackageName: "twitterfollows",
		Source:      source,
	}
}
