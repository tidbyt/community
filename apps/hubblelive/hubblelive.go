// Package hubblelive provides details for the Hubble Live applet.
package hubblelive

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed hubble_live.star
var source []byte

// New creates a new instance of the Hubble Live applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "hubble-live",
		Name:        "Hubble Live",
		Author:      "Brian McLaughlin (SpinStabilized)",
		Summary:     "Current Hubble Observation",
		Desc:        "Displays the currently scheduled observation status of the Hubble Space Telescope (v0.2.0).",
		FileName:    "hubble_live.star",
		PackageName: "hubblelive",
		Source:  source,
	}
}
