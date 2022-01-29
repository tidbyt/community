// Package MNLightRail provides details for the Date Time Clock applet.
package MNLightRail

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed date_time_clock.star
var source []byte

// New creates a new instance of the Date Time Clock applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "MN-Light-Rail",
		Name:        "MN Light Rail",
		Author:      "Alex Miller",
		Summary:     "Train Departure Times",
		Desc:        "Shows Light Rail Departure Times from Selected Stop.",
		FileName:    "MN_Light_Rail.star",
		PackageName: "MNLightRail",
		Source:  source,
	}
}
