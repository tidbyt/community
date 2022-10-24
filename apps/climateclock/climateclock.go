// Package climateclock provides details for the Climate Clock applet.
package climateclock

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed climate_clock.star
var source []byte

// New creates a new instance of the Climate Clock applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "climate-clock",
		Name:        "Climate Clock",
		Author:      "Rob Kimball",
		Summary:     "Climate Clock",
		Desc:        "The most important number in the world.",
		FileName:    "climate_clock.star",
		PackageName: "climateclock",
		Source:  source,
	}
}
