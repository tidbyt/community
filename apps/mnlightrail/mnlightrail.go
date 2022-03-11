// Package mnlightrail provides details for the Date Time Clock applet.
package mnlightrail

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed mn_light_rail.star
var source []byte

// New creates a new instance of the MN Light Rail applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "mn-light-rail",
		Name:        "MN Light Rail",
		Author:      "Alex Miller",
		Summary:     "Train Departure Times",
		Desc:        "Shows Light Rail Departure Times from Selected Stop.",
		FileName:    "mn_light_rail.star",
		PackageName: "mnlightrail",
		Source:      source,
	}
}
