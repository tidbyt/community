// Package airthings provides details for the AirThings applet.
package airthings

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed airthings.star
var source []byte

// New creates a new instance of the AirThings applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "airthings",
		Name:        "AirThings",
		Author:      "joshspicer",
		Summary:     "Environment sensor readings",
		Desc:        "Environment sensor readings from an AirThings sensor.",
		FileName:    "airthings.star",
		PackageName: "airthings",
		Source:  source,
	}
}
