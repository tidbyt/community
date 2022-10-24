// Package mvv provides details for the MVV applet.
package mvv

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed mvv.star
var source []byte

// New creates a new instance of the MVV applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "mvv",
		Name:        "MVV",
		Author:      "Robin Sommer",
		Summary:     "MVV departures (Munich)",
		Desc:        "Departure times for the Münchner Verkehrsverbund (MVV).",
		FileName:    "mvv.star",
		PackageName: "mvv",
		Source:  source,
	}
}
