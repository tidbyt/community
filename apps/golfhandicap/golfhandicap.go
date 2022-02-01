// Package golfhandicap provides details for the Golf Handicap applet.
package golfhandicap

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed golf_handicap.star
var source []byte

// New creates a new instance of the Golf Handicap applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "golf-handicap",
		Name:        "Golf Handicap",
		Author:      "Chris Jones (IPv6Freely)",
		Summary:     "Displays your golf handicap",
		Desc:        "Displays your golf handicap using data from GHIN. Includes low/high and cap information.",
		FileName:    "golf_handicap.star",
		PackageName: "golfhandicap",
		Source:  source,
	}
}
