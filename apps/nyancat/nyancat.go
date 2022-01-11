// Package nyancat provides details for the Nyan Cat applet.
package nyancat

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed nyan_cat.star
var source []byte

// New creates a new instance of the Nyan Cat applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "nyan-cat",
		Name:        "Nyan Cat",
		Author:      "Mack Ward",
		Summary:     "Nyan Cat Animation",
		Desc:        "An animated cartoon cat with a Pop-Tart for a torso.",
		FileName:    "nyan_cat.star",
		PackageName: "nyancat",
		Source:  source,
	}
}
