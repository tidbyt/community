// Package soundtransit provides details for the Sound Transit applet.
package soundtransit

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed sound_transit.star
var source []byte

// New creates a new instance of the Sound Transit applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "sound-transit",
		Name:        "Sound Transit",
		Author:      "Jon Janzen",
		Summary:     "Seattle light rail times",
		Desc:        "Shows upcoming arrivals at up to 2 different stations in Sound Transit's Link light rail system in Seattle.",
		FileName:    "sound_transit.star",
		PackageName: "soundtransit",
		Source:  source,
	}
}
