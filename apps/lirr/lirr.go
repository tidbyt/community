// Package lirr provides details for the LIRR applet.
package lirr

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed lirr.star
var source []byte

// New creates a new instance of the LIRR applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "lirr",
		Name:        "LIRR",
		Author:      "bralax",
		Summary:     "LIRR Train Times",
		Desc:        "Long Island Railroad Train Times.",
		FileName:    "lirr.star",
		PackageName: "lirr",
		Source:  source,
	}
}
