// Package subreddit provides details for the Subreddit applet.
package subreddit

import (
	_ "embed"

	"tidbyt.dev/community/apps"
	"tidbyt.dev/community/apps/manifest"
)

//go:embed subreddit.star
var source []byte

func init() {
	apps.Manifests = append(apps.Manifests, New())
}

// New creates a new instance of the Subreddit applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "subreddit",
		Name:        "Subreddit",
		Author:      "Petros Fytilis",
		Summary:     "Subreddit post",
		Desc:        "Display the #1 post of a subreddit.",
		FileName:    "subreddit.star",
		PackageName: "subreddit",
		Source:      source,
	}
}
