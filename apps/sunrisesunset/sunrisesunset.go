// Package sunrisesunset provides details for the Sunrise Sunset applet.
package sunrisesunset

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed sunrise_sunset.star
var source []byte

// New creates a new instance of the Sunrise Sunset applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "sunrise-sunset",
		Name:        "Sunrise Sunset",
		Author:      "Alan Fleming",
		Summary:     "Shows sunrise and set times",
		Desc:        "Displays with icon sunrise and sunset times.",
		FileName:    "sunrise_sunset.star",
		PackageName: "sunrisesunset",
		Source:  source,
	}
}
