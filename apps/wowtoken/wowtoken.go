package wowtoken

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed wowtoken.star
var source []byte

func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "wowtoken",
		Name:        "WoW Token",
		Author:      "@ledif",
		Summary:     "Display WoW Token Price",
		Desc:        "Displays the current price of the World of Warcraft token in various regions. Data provided by wowtokenprices.com and updated every 10 minutes",
		FileName:    "wowtoken.star",
		PackageName: "wowtoken",
		Source:  source,
	}
}
