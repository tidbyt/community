// Package shuffleimages provides details for the Shuffle Images applet.
package shuffleimages

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed shuffle_images.star
var source []byte

// New creates a new instance of the Shuffle Images applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "shuffle-images",
		Name:        "Shuffle Images",
		Author:      "rs7q5",
		Summary:     "Randomly display an image",
		Desc:        "Randomly displays an image from a user-specified list (20 image max).",
		FileName:    "shuffle_images.star",
		PackageName: "shuffleimages",
		Source:  source,
	}
}
