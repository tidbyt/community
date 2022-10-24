// Package dutchfuzzyclock provides details for the Dutch Fuzzy Clock applet.
package dutchfuzzyclock

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed dutch_fuzzy_clock.star
var source []byte

// New creates a new instance of the Dutch Fuzzy Clock applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "dutch-fuzzy-clock",
		Name:        "Dutch Fuzzy Clock",
		Author:      "Remy Blok",
		Summary:     "Dutch readable time",
		Desc:        "Display the time in Dutch, human-readable way.",
		FileName:    "dutch_fuzzy_clock.star",
		PackageName: "dutchfuzzyclock",
		Source:  source,
	}
}
