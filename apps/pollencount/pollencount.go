// Package pollencount provides details for the Pollen Count applet.
package pollencount

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed pollen_count.star
var source []byte

// New creates a new instance of the Pollen Count applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "pollen-count",
		Name:        "Pollen Count",
		Author:      "Nicole Brooks",
		Summary:     "Pollen count for your area",
		Desc:        "Displays a pollen count for your area. Enter your location for updates every 12 hours on the current conditions in your town, as well as which types of pollen are in the air today.",
		FileName:    "pollen_count.star",
		PackageName: "pollencount",
		Source:  source,
	}
}
