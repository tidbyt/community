// Package mnmetrotransit provides details for the MN Metro Transit applet.
package mnmetrotransit

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed mn_metro_transit.star
var source []byte

// New creates a new instance of the MN Metro Transit applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "mn-metro-transit",
		Name:        "MN Metro Trasnit",
		Author:      "Jonathan Wescott & Alex Miller",
		Summary:     "Metro Transit Departures",
		Desc:        "MN Train, BRT, ABRT, and Bus Departure Times.",
		FileName:    "mn_metro_transit.star",
		PackageName: "mnmetrotransit",
		Source:      source,
	}
}
