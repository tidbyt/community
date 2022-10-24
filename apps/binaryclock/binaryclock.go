// Package binaryclock provides details for the Binary Clock applet.
package binaryclock

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed binary_clock.star
var source []byte

// New creates a new instance of the Binary Clock applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "binary-clock",
		Name:        "Binary Clock",
		Author:      "LukiLeu",
		Summary:     "Shows a binary clock",
		Desc:        "This app show the current date and time in a binary format.",
		FileName:    "binary_clock.star",
		PackageName: "binaryclock",
		Source:  source,
	}
}
