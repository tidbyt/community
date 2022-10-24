// Package surfforecast provides details for the Surf Forecast applet.
package surfforecast

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed surf_forecast.star
var source []byte

// New creates a new instance of the Surf Forecast applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "surf-forecast",
		Name:        "Surf Forecast",
		Author:      "smith-kyle",
		Summary:     "Daily surf forecast",
		Desc:        "Daily surf forecast for any spot on Surfline.",
		FileName:    "surf_forecast.star",
		PackageName: "surfforecast",
		Source:  source,
	}
}
