// Package warframecycles provides details for the Warframe Cycles applet.
package warframecycles

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed warframe_cycles.star
var source []byte

// New creates a new instance of the Warframe Cycles applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "warframe-cycles",
		Name:        "Warframe Cycles",
		Author:      "grantmatheny",
		Summary:     "Time in Warframe open areas",
		Desc:        "Tells you the cycle that's active in each of the Warframe open areas and in Earth missions.",
		FileName:    "warframe_cycles.star",
		PackageName: "warframecycles",
		Source:  source,
	}
}
