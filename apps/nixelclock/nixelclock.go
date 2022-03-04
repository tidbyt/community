// Package nixelclock provides details for the Nixel Clock applet.
package nixelclock

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed nixel_clock.star
var source []byte

// New creates a new instance of the Nixel Clock applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "nixel-clock",
		Name:        "Nixel Clock",
		Author:      "Olly Stedall @saltedlolly",
		Summary:     "A Pixel Nixie Clock",
		Desc:        "Nixie Tube Clock + Pixels = Nixel Clock!",
		FileName:    "nixel_clock.star",
		PackageName: "nixelclock",
		Source:  source,
	}
}
