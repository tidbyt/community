// Package deathvalleytemp provides details for the Death Valley Thermometer applet.
package deathvalleytemp

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed deathvalleytemp.star
var source []byte

// New creates a new instance of the Death Valley Thermometer applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "deathvalleytemp",
		Name:        "Death Valley Thermometer",
		Author:      "Kyle Stark",
		Summary:     "Death Valley thermometer",
		Desc:        "Based on the thermometers at Death Valley National Park",
		FileName:    "deathvalleytemp.star",
		PackageName: "deathvalleytemp",
		Source:      source,
	}
}
