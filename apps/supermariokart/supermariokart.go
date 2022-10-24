// Package supermariokart provides details for the Super Mario Kart applet.
package supermariokart

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed super_mario_kart.star
var source []byte

// New creates a new instance of the Super Mario Kart applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "super-mario-kart",
		Name:        "Super Mario Kart",
		Author:      "Kevin Connell",
		Summary:     "Super Mario Kart Animation",
		Desc:        "Animated characters & items from the 1992 Super Mario Kart game.",
		FileName:    "super_mario_kart.star",
		PackageName: "supermariokart",
		Source:  source,
	}
}
