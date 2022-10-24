// Package coloranalogclock provides details for the Colorful Clock applet.
package colorfulclock

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed colorful_clock.star
var source []byte

// New creates a new instance of the Color Analog Clock applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "colorful-clock",
		Name:        "Colorful Clock",
		Author:      "LukiLeu",
		Summary:     "Colorful Clock",
		Desc:        "Shows the time like on an old wall clock.",
		FileName:    "colorful_clock.star",
		PackageName: "colorfulclock",
		Source:  source,
	}
}
