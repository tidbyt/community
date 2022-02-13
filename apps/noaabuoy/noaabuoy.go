// Package noaabuoy provides details for the NOAA Buoy applet.
package noaabuoy

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed noaa_buoy.star
var source []byte

// New creates a new instance of the NOAA Buoy applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "noaa-buoy",
		Name:        "NOAA Buoy",
		Author:      "tavdog",
		Summary:     "Show buoy swell info",
		Desc:        "Display swell details from a specified noaa buoy.",
		FileName:    "noaa_buoy.star",
		PackageName: "noaabuoy",
		Source:  source,
	}
}
