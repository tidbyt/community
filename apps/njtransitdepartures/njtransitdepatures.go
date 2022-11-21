// Package njtransitdepartures provides details for the NJ Transit Departures applet.
package njtransitdepartures

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed nj_transit_departures.star
var source []byte

// New creates a new instance of the NJ Transit Departures applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "nj-transit-departures",
		Name:        "NJ Transit Departures",
		Author:      "Jason-J-Hunt",
		Summary:     "NJ Transit Departures",
		Desc:        "See the upcoming train departures of a selected NJ Transit station",
		FileName:    "nj_transit_departures.star",
		PackageName: "njtransitdepartures",
		Source:  source,
	}
}