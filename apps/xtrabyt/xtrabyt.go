// Package xtrabyt provides details for the Xtrabyt applet.
package xtrabyt

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed xtrabyt.star
var source []byte

// New creates a new instance of the Xtrabyt applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "xtrabyt",
		Name:        "Xtrabyt",
		Author:      "vmitchell85",
		Summary:     "Display Xtrabyt.com View",
		Desc:        "Display a custom drawing or integration view from Xtrabyt.com.",
		FileName:    "xtrabyt.star",
		PackageName: "xtrabyt",
		Source:  source,
	}
}
