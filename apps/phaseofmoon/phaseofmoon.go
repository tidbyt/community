// Package phaseofmoon provides details for the Phase Of Moon applet.
package phaseofmoon

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed phase_of_moon.star
var source []byte

// New creates a new instance of the Phase Of Moon applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "phase-of-moon",
		Name:        "Phase Of Moon",
		Author:      "Alan Fleming",
		Summary:     "Shows the phase of the moon",
		Desc:        "Shows the current phase of the moon.",
		FileName:    "phase_of_moon.star",
		PackageName: "phaseofmoon",
		Source:  source,
	}
}
