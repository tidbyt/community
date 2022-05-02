// Package isitchristmas provides details for the Is It Christmas applet.
package isitchristmas

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed is_it_christmas.star
var source []byte

// New creates a new instance of the Is It Christmas applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "is-it-christmas",
		Name:        "Is It Christmas",
		Author:      "Austin Fonacier",
		Summary:     "Is it christmas: yes/no",
		Desc:        "Is it christmas: yes/no.",
		FileName:    "is_it_christmas.star",
		PackageName: "isitchristmas",
		Source:  source,
	}
}
