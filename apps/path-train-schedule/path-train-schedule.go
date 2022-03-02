// Package path-train-schedule provides details for the Path Train applet.
package path-train-schedule

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed path-train-schedule.star
var source []byte

// New creates a new instance of the BGG Hotness applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "path-train-schedule",
		Name:        "Path Train Schedule",
		Author:      "Todd Greenberg",
		Summary:     "Schedule for path train",
		Desc:        "Shows train arrivals for path train stations",
		FileName:    "path-train-schedule.star",
		PackageName: "path-train-schedule",
		Source:      source,
	}
}
