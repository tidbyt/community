// Package rplace2022 provides details for the R-Place 2022 applet.
package rplace2022

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed r_place_2022.star
var source []byte

// New creates a new instance of the R-Place 2022 applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "r-place-2022",
		Name:        "Reddit R Place 2022",
		Author:      "funkfinger",
		Summary:     "Bits of r/place 2022",
		Desc:        "See bits of what Redditors created for r/place 2022.",
		FileName:    "r_place_2022.star",
		PackageName: "rplace2022",
		Source:  source,
	}
}
