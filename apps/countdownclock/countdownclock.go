// Package countdownclock provides details for the Countdown Clock applet.
package countdownclock

import (
	_ "embed"

	"tidbyt.dev/community/apps"
	"tidbyt.dev/community/apps/manifest"
)

//go:embed countdown_clock.star
var source []byte

func init() {
	apps.Manifests = append(apps.Manifests, New())
}

// New creates a new instance of the Countdown Clock applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "countdown-clock",
		Name:        "Countdown Clock",
		Author:      "CubsAaron",
		Summary:     "Countdown to an event",
		Desc:        "Display the days, hours, and minutes remaining to a specified event.",
		FileName:    "countdown_clock.star",
		PackageName: "countdownclock",
		Source:      source,
	}
}
