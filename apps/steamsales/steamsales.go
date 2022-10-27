// Package steamsales provides details for the Steam Sales applet.
package steamsales

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed steam_sales.star
var source []byte

// New creates a new instance of the Steam Sales applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "steam-sales",
		Name:        "Steam Sales",
		Author:      "Par Johansson",
		Summary:     "List sales on Steam",
		Desc:        "Lists current Steam sales from their featured section.",
		FileName:    "steam_sales.star",
		PackageName: "steamsales",
		Source:  source,
	}
}
