// Package njtransit provides details for the NJ Transit applet.
package njtransit

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed nj_transit.star
var source []byte

// New creates a new instance of the NJ Transit applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "nj-transit",
		Name:        "NJ Transit",
		Author:      "Jason-J-Hunt",
		Summary:     "NJ Transit Departures",
		Desc:        "See the upcoming departures of a selected NJ Transit station.",
		FileName:    "nj_transit.star",
		PackageName: "njtransit",
		Source:  source,
	}
}
