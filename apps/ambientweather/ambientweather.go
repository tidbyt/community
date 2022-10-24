// Package ambientweather provides details for the Ambient Weather applet.
package ambientweather

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed ambient_weather.star
var source []byte

// New creates a new instance of the Ambient Weather applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "ambient-weather",
		Name:        "Ambient Weather",
		Author:      "Jon Maddox",
		Summary:     "Your local weather",
		Desc:        "Show readings from your Ambient weather station.",
		FileName:    "ambient_weather.star",
		PackageName: "ambientweather",
		Source:  source,
	}
}
