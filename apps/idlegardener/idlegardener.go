// Package idlegardener provides details for the Idle Gardener applet.
package idlegardener

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed idle_gardener.star
var source []byte

// New creates a new instance of the Idle Gardener applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "idle-gardener",
		Name:        "Idle Gardener",
		Author:      "yonodactyl",
		Summary:     "Grow trees while you work",
		Desc:        "The Idle Gardener is an Idle tree growing tycoon that takes absolutely no input from you!",
		FileName:    "idle_gardener.star",
		PackageName: "idlegardener",
		Source:  source,
	}
}
