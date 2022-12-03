// Package earthquakemap provides details for the Earthquake Map applet.
package earthquakemap

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed earthquake_map.star
var source []byte

// New creates a new instance of the Earthquake Map applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "earthquake-map",
		Name:        "Earthquake Map",
		Author:      "Brian McLaughlin (SpinStabilized)",
		Summary:     "Map of global earthquakes",
		Desc:        "Display a map of earthquakes based on USGS data.",
		FileName:    "earthquake_map.star",
		PackageName: "earthquakemap",
		Source:  source,
	}
}
