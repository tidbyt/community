// Package mcserverstatus provides details for the MCServerStatus applet.
package mcserverstatus

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed mcserverstatus.star
var source []byte

// New creates a new instance of the MCServerStatus applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "mcserverstatus",
		Name:        "MCServerStatus",
		Author:      "jakeva",
		Summary:     "See MC server player count",
		Desc:        "Track the player count on any MC server!",
		FileName:    "mcserverstatus.star",
		PackageName: "mcserverstatus",
		Source:  source,
	}
}
