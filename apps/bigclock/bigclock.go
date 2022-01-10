// Package bigclock provides details for the Big Clock applet.
package bigclock

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed big_clock.star
var source []byte

// New creates a new instance of the Big Clock applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "big-clock",
		Name:        "Big Clock",
		Author:      "Joey Hoer",
		Summary:     "Display a large retro-style clock",
		Desc:        "Display a large retro-style clock; the clock can change color at night based on sunrise and sunset times for a given location, supports 24-hour and 12-hour variants and optionally flashes the seperator.",
		FileName:    "big_clock.star",
		PackageName: "bigclock",
		Source:      source,
	}
}
