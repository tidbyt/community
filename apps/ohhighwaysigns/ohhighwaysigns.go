// Package ohhighwaysigns provides details for the OH Highway Signs applet.
package ohhighwaysigns

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed oh_highway_signs.star
var source []byte

// New creates a new instance of the OH Highway Signs applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "oh-highway-signs",
		Name:        "OH Highway Signs",
		Author:      "noahcolvin",
		Summary:     "Displays OH highway signs",
		Desc:        "Displays messages from overhead signs on Ohio highways.",
		FileName:    "oh_highway_signs.star",
		PackageName: "ohhighwaysigns",
		Source:      source,
	}
}
