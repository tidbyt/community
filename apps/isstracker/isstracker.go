// Package isstracker provides details for the ISS Tracker applet.
package isstracker

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed iss_tracker.star
var source []byte

// New creates a new instance of the ISS Tracker applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "iss-tracker",
		Name:        "ISS Tracker",
		Author:      "Chris Jones (@IPv6Freely)",
		Summary:     "Tracks the ISS Position",
		Desc:        "Tracks the position of the International Space Station using LAT/LONG coordinates.",
		FileName:    "iss_tracker.star",
		PackageName: "isstracker",
		Source:  source,
	}
}
