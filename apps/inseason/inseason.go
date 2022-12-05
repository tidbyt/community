// Package inseason provides details for the InSeason applet.
package inseason

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed inseason.star
var source []byte

// New creates a new instance of the InSeason applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "inseason",
		Name:        "In Season",
		Author:      "Robert Ison",
		Summary:     "Displays In Season Foods",
		Desc:        "Displays In Season Foods for your region.",
		FileName:    "inseason.star",
		PackageName: "inseason",
		Source:      source,
	}
}
