// Package noaatides provides details for the NOAA Tides applet.
package noaatides

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed noaa_tides.star
var source []byte

// New creates a new instance of the NOAA Tides applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "noaa-tides",
		Name:        "NOAA Tides",
		Author:      "tavdog",
		Summary:     "Display NOAA Tides",
		Desc:        "Display daily tides from NOAA stations.",
		FileName:    "noaa_tides.star",
		PackageName: "noaatides",
		Source:  source,
	}
}
