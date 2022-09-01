// Package analogueclock provides details for the Analogue Clock applet.
package analogueclock

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed analogue_clock.star
var source []byte

// New creates a new instance of the Analogue Clock applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "analogue-clock",
		Name:        "Analogue Clock",
		Author:      "LukiLeu",
		Summary:     "Analogue Clock",
		Desc:        "Shows the time like on an old wall clock.",
		FileName:    "analogue_clock.star",
		PackageName: "analogueclock",
		Source:  source,
	}
}
