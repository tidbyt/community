// Package hexcolorclock provides details for the Hex Color Clock applet.
package hexcolorclock

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed hex_color_clock.star
var source []byte

// New creates a new instance of the Hex Clock applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "hex-color-clock",
		Name:        "Hex Color Clock",
		Author:      "gabe565",
		Summary:     "Shows a hex color clock",
		Desc:        "This app shows a clock and a hex number. The background will change colors to match the hex code shown.",
		FileName:    "hex_color_clock.star",
		PackageName: "hexcolorclock",
		Source:      source,
	}
}
