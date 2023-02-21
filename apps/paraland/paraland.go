// Package paraland provides details for the Paraland applet.
package paraland

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed paraland.star
var source []byte

// New creates a new instance of the Paraland applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "paraland",
		Name:        "Paraland",
		Author:      "yonodactyl",
		Summary:     "Shows hand drawn landscapes",
		Desc:        "See cool hand drawn pixel art landscapes from your Tidbyt.",
		FileName:    "paraland.star",
		PackageName: "paraland",
		Source:  source,
	}
}
