// Package wantedposter provides details for the WantedPoster applet.
package wantedposter

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed wantedposter.star
var source []byte

// New creates a new instance of the WantedPoster applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "wantedposter",
		Name:        "WantedPoster",
		Author:      "Robert Ison",
		Summary:     "Display Wanted Poster",
		Desc:        "Displays a custom wanted poster based on an image you upload.",
		FileName:    "wantedposter.star",
		PackageName: "wantedposter",
		Source:  source,
	}
}
