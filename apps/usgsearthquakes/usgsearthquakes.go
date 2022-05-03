// Package usgsearthquakes provides details for the USGS Earthquakes applet.
package usgsearthquakes

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed usgs_earthquakes.star
var source []byte

// New creates a new instance of the USGS Earthquakes applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "usgs-earthquakes",
		Name:        "USGS Earthquakes",
		Author:      "Chris Silverberg",
		Summary:     "Recent nearby earthquakes",
		Desc:        "Displays the most recent earthquakes based on location.",
		FileName:    "usgs_earthquakes.star",
		PackageName: "usgsearthquakes",
		Source:  source,
	}
}
