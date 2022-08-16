// Package giphy provides details for the Giphy applet.
package giphy

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed giphy.star
var source []byte

// New creates a new instance of the Giphy applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "giphy",
		Name:        "Giphy",
		Author:      "Ricky Smith (DigitallyBorn)",
		Summary:     "Displays Giphy gifs",
		Desc:        "Displays a random gif based on a search query. Powered by Giphy.com.",
		FileName:    "giphy.star",
		PackageName: "giphy",
		Source:  source,
	}
}
