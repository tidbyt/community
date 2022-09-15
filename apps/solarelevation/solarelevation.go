// Package solarelevation provides details for the Solar Elevation applet.
package solarelevation

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed solar_elevation.star
var source []byte

// New creates a new instance of the Solar Elevation applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "solar-elevation",
		Name:        "Solar Elevation",
		Author:      "dinosaursrarr",
		Summary:     "How high is the sun",
		Desc:        "A clock for when you cannot look out of the window or at an actual clock. How high is the sun above or below the horizon right now?",
		FileName:    "solar_elevation.star",
		PackageName: "solarelevation",
		Source:  source,
	}
}
