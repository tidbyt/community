// Package lordoftherings provides details for the LordOfTheRings applet.
package lordoftherings

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed lordoftherings.star
var source []byte

// New creates a new instance of the LordOfTheRings applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "lordoftherings",
		Name:        "LordOfTheRings",
		Author:      "Jake Manske",
		Summary:     "Displays LOTR quotes",
		Desc:        "Displays random quotes from LOTR trilogy.",
		FileName:    "lordoftherings.star",
		PackageName: "lordoftherings",
		Source:  source,
	}
}
