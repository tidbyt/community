// Package ethstaker provides details for the Ethstaker applet.
package ethstaker

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed ethstaker.star
var source []byte

// New creates a new instance of the Ethstaker applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "ethstaker",
		Name:        "Ethstaker",
		Author:      "ColinCampbell",
		Summary:     "Ethereum validator status",
		Desc:        "Shows the recent status of provided validators on the Ethereum beacon chain.",
		FileName:    "ethstaker.star",
		PackageName: "ethstaker",
		Source:  source,
	}
}
