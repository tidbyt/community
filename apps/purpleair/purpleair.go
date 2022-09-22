// Package purpleair provides details for the PurpleAir applet.
package purpleair

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed purpleair.star
var source []byte

// New creates a new instance of the PurpleAir applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "purpleair",
		Name:        "PurpleAir",
		Author:      "posburn",
		Summary:     "Displays local air quality",
		Desc:        "Displays the local air quality index from a nearby PurpleAir sensor. Choose a sensor close to you or provide a specific sensor id.",
		FileName:    "purpleair.star",
		PackageName: "purpleair",
		Source:  source,
	}
}
