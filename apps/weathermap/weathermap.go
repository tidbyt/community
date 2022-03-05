// Package weathermap provides details for the Weather Map applet.
package weathermap

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed weather_map.star
var source []byte

// New creates a new instance of the Weather Map applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "weather-map",
		Name:        "Weather Map",
		Author:      "Felix Bruns",
		Summary:     "Weather Map",
		Desc:        "Display real-time precipitation radar for a location. Powered by the RainViewer API.",
		FileName:    "weather_map.star",
		PackageName: "weathermap",
		Source:  source,
	}
}
