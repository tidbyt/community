// Package 5pmsomewhere provides details for the 5pm Somewhere applet.
package 5pmsomewhere

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed 5pm_somewhere.star
var source []byte

// New creates a new instance of the 5pm Somewhere applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "5pm-somewhere",
		Name:        "5pm Somewhere",
		Author:      "grantmatheny",
		Summary:     "Where it is 5 o'clock",
		Desc:        "Displays a random timezone where it's currently in the 5 o'clock hour.",
		FileName:    "5pm_somewhere.star",
		PackageName: "5pmsomewhere",
		Source:  source,
	}
}
