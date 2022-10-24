// Package digitalrain provides details for the Digital Rain applet.
package digitalrain

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed digital_rain.star
var source []byte

// New creates a new instance of the Digital Rain applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "digital-rain",
		Name:        "Digital Rain",
		Author:      "Henry So, Jr.",
		Summary:     "Digital Rain à la Matrix",
		Desc:        "Generates an animation loop of falling code similar to that from the Matrix movie. A new sequence every 30 minutes.",
		FileName:    "digital_rain.star",
		PackageName: "digitalrain",
		Source:  source,
	}
}
