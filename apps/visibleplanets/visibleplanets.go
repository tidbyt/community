// Package visibleplanets provides details for the VisiblePlanets applet.
package visibleplanets

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed visibleplanets.star
var source []byte

// New creates a new instance of the VisiblePlanets applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "visibleplanets",
		Name:        "VisiblePlanets",
		Author:      "Robert Ison",
		Summary:     "Displays Info on Planets",
		Desc:        "Displays info on planet visibility.",
		FileName:    "visibleplanets.star",
		PackageName: "visibleplanets",
		Source:  source,
	}
}
