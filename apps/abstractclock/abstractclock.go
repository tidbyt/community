// Package abstractclock provides details for the Abstract Clock applet.
package abstractclock

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed abstract_clock.star
var source []byte

// New creates a new instance of the Abstract Clock applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "abstract-clock",
		Name:        "Abstract Clock",
		Author:      "AmillionAir",
		Summary:     "Shows Time",
		Desc:        "Uses 60 Pixels to display time across width of Tidbyt.",
		FileName:    "abstract_clock.star",
		PackageName: "abstractclock",
		Source:  source,
	}
}
