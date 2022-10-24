// Package fivesomewhere provides details for the Five Somewhere applet.
package fivesomewhere

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed five_somewhere.star
var source []byte

// New creates a new instance of the Five Somewhere applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "five-somewhere",
		Name:        "Five Somewhere",
		Author:      "grantmatheny",
		Summary:     "Where it is 5 o'clock",
		Desc:        "Displays a random timezone where it's currently in the 5 o'clock hour.",
		FileName:    "five_somewhere.star",
		PackageName: "fivesomewhere",
		Source:  source,
	}
}
