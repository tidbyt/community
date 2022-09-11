// Package mbtanewtrains provides details for the MBTA New Trains applet.
package mbtanewtrains

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed mbta_new_trains.star
var source []byte

// New creates a new instance of the MBTA New Trains applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "mbta-new-trains",
		Name:        "MBTA New Trains",
		Author:      "joshspicer",
		Summary:     "Track new MBTA subway cars",
		Desc:        "Displays the real time location of the new MBTA subway cars.",
		FileName:    "mbta_new_trains.star",
		PackageName: "mbtanewtrains",
		Source:  source,
	}
}
