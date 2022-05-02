// Package hvvdepartures provides details for the HVV Departures applet.
package hvvdepartures

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed hvv_departures.star
var source []byte

// New creates a new instance of the HVV Departures applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "hvv-departures",
		Name:        "HVV Departures",
		Author:      "Felix Bruns",
		Summary:     "HVV Departures",
		Desc:        "Display real-time departure times for trains, buses and ferries in Hamburg (HVV).",
		FileName:    "hvv_departures.star",
		PackageName: "hvvdepartures",
		Source:  source,
	}
}
