// Package tempest provides details for the Tempest Weather applet.
package tempest

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed tempest.star
var source []byte

// New creates a new instance of the Tempest Weather applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "tempest",
		Name:        "Tempest Weather",
		Author:      "Rohan Singh",
		Summary:     "Tempest weather station",
		Desc:        "Show readings from your Tempest weather station.",
		FileName:    "tempest.star",
		PackageName: "tempest",
		Source:      source,
	}
}
