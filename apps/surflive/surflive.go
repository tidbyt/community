// Package surflive provides details for the Surflive applet.
package surflive

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed surflive.star
var source []byte

// New creates a new instance of the Surflive applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "surflive",
		Name:        "Surflive",
		Author:      "Rémi Carton",
		Summary:     "Live surf conditions",
		Desc:        "Shows the current surf conditions for a surf spot.",
		FileName:    "surflive.star",
		PackageName: "surflive",
		Source:      source,
	}
}
