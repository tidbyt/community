// Package moonphase provides details for the Moon Phase applet.
package moonphase

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed moon_phase.star
var source []byte

// New creates a new instance of the Moon Phase applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "moon-phase",
		Name:        "Moon Phase",
		Author:      "Chris Wyman",
		Summary:     "Shows current moon phase",
		Desc:        "Shows phase of moon based on location.",
		FileName:    "moon_phase.star",
		PackageName: "moonphase",
		Source:  source,
	}
}
