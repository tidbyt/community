// Package analogclock2 provides details for the Analog Clock 2 applet.
package analogclock2

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed analog_clock_2.star
var source []byte

// New creates a new instance of the Analog Clock 2 applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "analog-clock-2",
		Name:        "Analog Clock 2",
		Author:      "rs7q5 (RIS)",
		Summary:     "Shows time analog style",
		Desc:        "Shows the time on an analog style clock.",
		FileName:    "analog_clock_2.star",
		PackageName: "analogclock2",
		Source:  source,
	}
}
