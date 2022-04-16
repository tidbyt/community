// Package destiny2stats provides details for the Destiny 2 Stats applet.
package destiny2stats

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed destiny_2_stats.star
var source []byte

// New creates a new instance of the Destiny 2 Stats applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "destiny-2-stats",
		Name:        "Destiny 2 Stats",
		Author:      "brandontod97",
		Summary:     "Display Destiny stats",
		Desc:        "Gets the emblem, race, class, and light level of your most recently played Destiny 2 character.",
		FileName:    "destiny_2_stats.star",
		PackageName: "destiny2stats",
		Source:  source,
	}
}
