// Package preciousmetals provides details for the Precious Metals applet.
package preciousmetals

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed precious_metals.star
var source []byte

// New creates a new instance of the Precious Metals applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "precious-metals",
		Name:        "Precious Metals",
		Author:      "threeio",
		Summary:     "Quotes on precious metals",
		Desc:        "Quotes for gold, platinum and silver.",
		FileName:    "precious_metals.star",
		PackageName: "preciousmetals",
		Source:  source,
	}
}
