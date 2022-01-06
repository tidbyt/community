// Package fuzzyclock provides details for the Fuzzy Clock applet.
package fuzzyclock

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed fuzzy_clock.star
var source []byte

// New creates a new instance of the Fuzzy Clock applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		Name:    "Fuzzy Clock",
		Author:  "Max Timkovich",
		Summary: "Human readable time",
		Desc:    "Display the time in a groovy, human-readable way.",
		Source:  source,
	}
}
