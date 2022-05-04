// Package baywheels provides details for the Bay Wheels applet.
package baywheels

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed bay_wheels.star
var source []byte

// New creates a new instance of the Bay Wheels applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "bay-wheels",
		Name:        "Bay Wheels",
		Author:      "Martin Strauss",
		Summary:     "Bay Wheels availability",
		Desc:        "Shows the availability of bikes and e-bikes at a Bay Wheels station.",
		FileName:    "bay_wheels.star",
		PackageName: "baywheels",
		Source:  source,
	}
}
