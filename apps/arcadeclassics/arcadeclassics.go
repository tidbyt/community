// Package arcadeclassics provides details for the Arcade Classics applet.
package arcadeclassics

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed arcade_classics.star
var source []byte

// New creates a new instance of the Arcade Classics applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "arcade-classics",
		Name:        "Arcade Classics",
		Author:      "Steve Otteson",
		Summary:     "Classic arcade animations",
		Desc:        "Animations from classic arcade video games.",
		FileName:    "arcade_classics.star",
		PackageName: "arcadeclassics",
		Source:  source,
	}
}
