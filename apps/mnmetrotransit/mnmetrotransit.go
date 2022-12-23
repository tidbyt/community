// Package mnmetrotransit provides details for the Date Time Clock applet.
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
		Summary:     "Train, BRT, ABRT, and Bus Departure Times",
		Desc:        "Shows Transit Departure Times from Selected Stop.",
		FileName:    "mn_metro_transit.star",
		PackageName: "mnmetrotransit",
		Source:      source,
	}
}
