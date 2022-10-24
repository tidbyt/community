// Package tube provides details for the Tube applet.
package tube

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed tube.star
var source []byte

// New creates a new instance of the Tube applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "tube",
		Name:        "Tube",
		Author:      "dinosaursrarr",
		Summary:     "London Underground arrivals",
		Desc:        "Upcoming arrivals for a particular Tube, Elizabeth Line, DLR or Overground station.",
		FileName:    "tube.star",
		PackageName: "tube",
		Source:  source,
	}
}
