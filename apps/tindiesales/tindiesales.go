// Package tindiesales provides details for the Tindie Sales applet.
package tindiesales

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed tindie_sales.star
var source []byte

// New creates a new instance of the Tindie Sales applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "tindie-sales",
		Name:        "Tindie Sales",
		Author:      "Joey Castillo",
		Summary:     "Shows Tindie sales numbers",
		Desc:        "Tindie is an online marketplace for maker-made products. This app displays sales stats for your Tindie store.",
		FileName:    "tindie_sales.star",
		PackageName: "tindiesales",
		Source:  source,
	}
}
