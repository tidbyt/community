// Package analogclock provides details for the Analog Clock applet.
package analogclock

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed analog_clock.star
var source []byte

// New creates a new instance of the Analog Clock applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "analog-clock",
		Name:        "Analog Clock",
		Author:      "Chris Jones (@IPv6Freely)",
		Summary:     "Shows a simple analog clock",
		Desc:        "Shows a simple analog clock with month and day.",
		FileName:    "analog_clock.star",
		PackageName: "analogclock",
		Source:  source,
	}
}
