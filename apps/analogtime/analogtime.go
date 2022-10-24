// Package analogtime provides details for the Analog Time applet.
package analogtime

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed analog_time.star
var source []byte

// New creates a new instance of the Analog Time applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "analog-time",
		Name:        "Analog Time",
		Author:      "rs7q5",
		Summary:     "Show time analog style",
		Desc:        "Shows the time on an analog style clock. Enter custom colors in #rgb, #rrggbb, #rgba, or #rrggbbaa format.",
		FileName:    "analog_time.star",
		PackageName: "analogtime",
		Source:  source,
	}
}
