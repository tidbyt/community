// Package soccerwomens.
package soccerwomens

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed soccerwomens.star
var source []byte

// New creates instance of applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "soccerwomens",
		Name:        "Womens Soccer",
		Author:      "jvivona",
		Summary:     "Womens Soccer scores",
		Desc:        "Shows upcoming games, current score, date and time of game for selected league / tournament.",
		FileName:    "soccerwomens.star",
		PackageName: "soccerwomens",
		Source:      source,
	}
}
