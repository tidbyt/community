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
		Desc:        "Display swell data for user specified buoy. Find buoy_id's here : https://www.ndbc.noaa.gov/obs.shtml Buoy must have height,period,direction to display correctly.",
		FileName:    "noaa_buoy.star",
		PackageName: "noaabuoy",
		Source:      source,
	}
}
