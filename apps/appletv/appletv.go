// Package appletv provides details for the Apple TV applet.
package appletv

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed apple_tv.star
var source []byte

// New creates a new instance of the Apple TV applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "apple-tv",
		Name:        "Apple TV",
		Author:      "tjmehta",
		Summary:     "Apple TV \"Now Playing\"",
		Desc:        "Shows Apple TV \"Now Playing\" on Tidbyt.",
		FileName:    "apple_tv.star",
		PackageName: "appletv",
		Source:  source,
	}
}
