// Package xboxgamerscore provides details for the Xbox Gamerscore applet.
package xboxgamerscore

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed xbox_gamerscore.star
var source []byte

// New creates a new instance of the Xbox Gamerscore applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "xbox-gamerscore",
		Name:        "Xbox Gamerscore",
		Author:      "Nick Penree",
		Summary:     "Display XBL gamerscore",
		Desc:        "Display your Xbox Live Gamerscore on your Tidbyt.",
		FileName:    "xbox_gamerscore.star",
		PackageName: "xboxgamerscore",
		Source:  source,
	}
}
