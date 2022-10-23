// Package redditrplace provides details for the Reddit R-Place applet.
package redditrplace

import (
	_ "embed"

	"tidbyt.dev/community/apps"
	"tidbyt.dev/community/apps/manifest"
)

//go:embed reddit_r_place.star
var source []byte

func init() {
	apps.Manifests = append(apps.Manifests, New())
}

// New creates a new instance of the Reddit R-Place applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "reddit-r-place",
		Name:        "Reddit R-Place",
		Author:      "funkfinger",
		Summary:     "Bits of r/place",
		Desc:        "See tidbits of what Redditors created for r/place.",
		FileName:    "reddit_r_place.star",
		PackageName: "redditrplace",
		Source:      source,
	}
}
