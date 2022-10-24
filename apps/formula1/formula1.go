// Package formula1 provides details for the Formula 1 applet.
package formula1

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed formula_1.star
var source []byte

// New creates a new instance of the Formula 1 applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "formula-1",
		Name:        "Formula 1",
		Author:      "AmillionAir",
		Summary:     "Next F1 Race Location",
		Desc:        "Shows Time date and location of Next F1 race.",
		FileName:    "formula_1.star",
		PackageName: "formula1",
		Source:  source,
	}
}
