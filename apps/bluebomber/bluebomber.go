// Package bluebomber provides details for the BlueBomber applet.
package bluebomber

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed bluebomber.star
var source []byte

// New creates a new instance of the BlueBomber applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "bluebomber",
		Name:        "BlueBomber",
		Author:      "Greg Burkett",
		Summary:     "Shows a random Megaman boss",
		Desc:        "Randomly shows one of the 8-bit style Megaman bosses with a slick title card and subtle animation.",
		FileName:    "bluebomber.star",
		PackageName: "bluebomber",
		Source:  source,
	}
}
