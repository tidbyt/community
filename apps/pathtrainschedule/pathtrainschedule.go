// Package pathtrainschedule provides details for the Path Train Schedule applet.
package pathtrainschedule

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed path_train_schedule.star
var source []byte

// New creates a new instance of the Path Train Schedule applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "path-train-schedule",
		Name:        "Path Schedule",
		Author:      "Todd Greenberg",
		Summary:     "Schedule for path train",
		Desc:        "Shows train arrivals for upcoming inbound and outbound trains at path train stations.",
		FileName:    "path_train_schedule.star",
		PackageName: "pathtrainschedule",
		Source:      source,
	}
}
