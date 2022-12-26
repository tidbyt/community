// Package hadisplay provides details for the HA Display applet.
package hadisplay

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed ha_display.star
var source []byte

// New creates a new instance of the HA Display applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "ha-display",
		Name:        "HA Display",
		Author:      "Etienne Michels",
		Summary:     "Home Assistant Display",
		Desc:        "Displays values from a Home Assistant device.",
		FileName:    "ha_display.star",
		PackageName: "hadisplay",
		Source:  source,
	}
}
