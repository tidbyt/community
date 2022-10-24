// Package daynightmap provides details for the Day Night Map applet.
package daynightmap

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed day_night_map.star
var source []byte

// New creates a new instance of the Day Night Map applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "day-night-map",
		Name:        "Day Night Map",
		Author:      "Henry So, Jr.",
		Summary:     "Day & Night World Map",
		Desc:        "A map of the Earth showing the day and the night. The map is based on Equirectangular (0°) by Tobias Jung (CC BY-SA 4.0).",
		FileName:    "day_night_map.star",
		PackageName: "daynightmap",
		Source:  source,
	}
}
