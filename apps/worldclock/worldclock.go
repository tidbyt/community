// Package worldclock provides details for the World Clock applet.
package worldclock

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed world_clock.star
var source []byte

// New creates a new instance of the World Clock applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "world-clock",
		Name:        "World Clock",
		Author:      "Elliot Bentley",
		Summary:     "Multi timezone clock",
		Desc:        "Displays the time in up to three different locations.",
		FileName:    "world_clock.star",
		PackageName: "worldclock",
		Source:  source,
	}
}
