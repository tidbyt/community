// Package fitbitweight provides details for the FitbitWeight applet.
package fitbitweight

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed fitbitweight.star
var source []byte

// New creates a new instance of the FitbitWeight applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "fitbitweight",
		Name:        "FitbitWeight",
		Author:      "Robert Ison",
		Summary:     "Displays recent weigh-ins",
		Desc:        "Displays your Fitbit recent weigh-ins.",
		FileName:    "fitbitweight.star",
		PackageName: "fitbitweight",
		Source:  source,
	}
}
