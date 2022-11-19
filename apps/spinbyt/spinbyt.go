// Package spinbyt provides details for the Spinbyt applet.
package spinbyt

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed spinbyt.star
var source []byte

// New creates a new instance of the Spinbyt applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "spinbyt",
		Name:        "Spinbyt",
		Author:      "zachlucas",
		Summary:     "Shows Spin scooters info",
		Desc:        "App that shows the nearest Spin scooter, its battery level, and number of other nearby scooters. Includes a scooter icon.",
		FileName:    "spinbyt.star",
		PackageName: "spinbyt",
		Source:  source,
	}
}
