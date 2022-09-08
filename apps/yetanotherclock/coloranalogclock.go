// Package coloranalogclock provides details for the Color Analog Clock applet.
package coloranalogclock

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed color_analog_clock.star
var source []byte

// New creates a new instance of the Color Analog Clock applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "color-analog-clock",
		Name:        "color-analog Clock",
		Author:      "LukiLeu",
		Summary:     "Color Analog Clock",
		Desc:        "Shows the time like on an old wall clock.",
		FileName:    "color_analog_clock.star",
		PackageName: "coloranalogclock",
		Source:  source,
	}
}
