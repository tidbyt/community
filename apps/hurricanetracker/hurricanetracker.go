// Package hurricanetracker provides details for the HurricaneTracker applet.
package hurricanetracker

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed hurricanetracker.star
var source []byte

// New creates a new instance of the HurricaneTracker applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "hurricanetracker",
		Name:        "HurricaneTracker",
		Author:      "Robert Ison",
		Summary:     "NHC Hurricane Information",
		Desc:        "Display NHC Hurricane info.",
		FileName:    "hurricanetracker.star",
		PackageName: "hurricanetracker",
		Source:  source,
	}
}
