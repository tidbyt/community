// Package martamap provides details for the Marta Map applet.
package martamap

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed marta_map.star
var source []byte

// New creates a new instance of the Marta Map applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "marta-map",
		Name:        "Marta Map",
		Author:      "InTheDaylight14",
		Summary:     "Display MARTA trains",
		Desc:        "Display real-time MARTA train locations and optionaly show station arrivals.",
		FileName:    "marta_map.star",
		PackageName: "martamap",
		Source:  source,
	}
}
