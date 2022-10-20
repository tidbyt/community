// Package unsplash provides details for the Unsplash applet.
package unsplash

import (
	_ "embed"

	"tidbyt.dev/community/apps"
	"tidbyt.dev/community/apps/manifest"
)

//go:embed unsplash.star
var source []byte

func init() {
	apps.Manifests = append(apps.Manifests, New())
}

// New creates a new instance of the Unsplash applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "unsplash",
		Name:        "Unsplash",
		Author:      "zephyern",
		Summary:     "Shows random photos",
		Desc:        "Displays a random image from Unsplash.",
		FileName:    "unsplash.star",
		PackageName: "unsplash",
		Source:      source,
	}
}
