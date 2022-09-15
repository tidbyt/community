// Package roblox provides details for the Roblox applet.
package roblox

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed roblox.star
var source []byte

// New creates a new instance of the Roblox applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "roblox",
		Name:        "Roblox",
		Author:      "Chad Milburn / CODESTRONG",
		Summary:     "Online friends & games",
		Desc:        "Real time views of your Roblox experiences.",
		FileName:    "roblox.star",
		PackageName: "roblox",
		Source:  source,
	}
}
