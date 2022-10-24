// Package neotrack provides details for the NEOTrack applet.
package neotrack

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed neotrack.star
var source []byte

// New creates a new instance of the NEOTrack applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "neotrack",
		Name:        "NEOTrack",
		Author:      "brettohland",
		Summary:     "Near Earth Object Tracker",
		Desc:        "Shows the closest object on approach to Earth today according to NASA's NeoW API.",
		FileName:    "neotrack.star",
		PackageName: "neotrack",
		Source:  source,
	}
}
