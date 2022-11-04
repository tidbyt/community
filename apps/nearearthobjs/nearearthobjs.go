// Package nearearthobjs provides details for the Near Earth Objs applet.
package nearearthobjs

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed near_earth_objs.star
var source []byte

// New creates a new instance of the Near Earth Objs applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "near-earth-objs",
		Name:        "Near Earth Objs",
		Author:      "noahcolvin",
		Summary:     "Show next near earth object",
		Desc:        "Displays the name, speed, distance, and arrival of the next near Earth object from NeoWs.",
		FileName:    "near_earth_objs.star",
		PackageName: "nearearthobjs",
		Source:  source,
	}
}
