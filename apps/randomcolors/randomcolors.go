// Package randomcolors provides details for the Random Colors applet.
package randomcolors

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed random_colors.star
var source []byte

// New creates a new instance of the Random Colors applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "random-colors",
		Name:        "Random Colors",
		Author:      "M0ntyP",
		Summary:     "Generates random color",
		Desc:        "Generates random color and corresponding hex code.",
		FileName:    "random_colors.star",
		PackageName: "randomcolors",
		Source:  source,
	}
}
