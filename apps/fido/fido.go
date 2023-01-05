// Package fido provides details for the Fido applet.
package fido

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed fido.star
var source []byte

// New creates a new instance of the Fido applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "fido",
		Name:        "Fido",
		Author:      "yonodactyl",
		Summary:     "A pixel pal",
		Desc:        "Fido is a pixel pal that will sit, walk, and feast inside your Tidbyt.",
		FileName:    "fido.star",
		PackageName: "fido",
		Source:  source,
	}
}
