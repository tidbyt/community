// Package wowtoken provides details for the WoW Token applet.
package wowtoken

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed wow_token.star
var source []byte

// New creates a new instance of the WoW Token applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "wow-token",
		Name:        "WoW Token",
		Author:      "@ledif",
		Summary:     "Display WoW Token Price",
		Desc:        "Displays the current price of the World of Warcraft token in various regions. Data provided by wowtokenprices.com and updated every 10 minutes.",
		FileName:    "wow_token.star",
		PackageName: "wowtoken",
		Source:  source,
	}
}
