// Package sfnextmuni provides details for the SF Next Muni applet.
package sfnextmuni

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed sf_next_muni.star
var source []byte

// New creates a new instance of the SF Next Muni applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "sf-next-muni",
		Name:        "SF Next Muni",
		Author:      "Martin Strauss",
		Summary:     "SF Muni arrival times",
		Desc:        "Shows the predicted arrival times from NextBus for a given SF Muni stop.",
		FileName:    "sf_next_muni.star",
		PackageName: "sfnextmuni",
		Source:  source,
	}
}
